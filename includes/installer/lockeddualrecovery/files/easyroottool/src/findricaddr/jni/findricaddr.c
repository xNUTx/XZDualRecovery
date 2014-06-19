/* findricaddr */

/*
 * Copyright (C) 2014 CUBE
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

#define KERNEL_START_ADDRESS 0xc0008000
#define KERNEL_SIZE 0x2000000
#define SEARCH_START_ADDRESS 0xc0800000
#define KALLSYMS_SIZE 0x200000

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/system_properties.h>

unsigned long *pmem = NULL;
unsigned long *kallsymsmem = NULL;

unsigned long pattern_kallsyms_addresses[] = {
	0xc0008000,	/* stext */
	0xc0008000,	/* _sinittext */
	0xc0008000,	/* _stext */
	0xc0008000	/* __init_begin */
};
unsigned long pattern_kallsyms_addresses2[] = {
	0xc0008000,	/* stext */
	0xc0008000	/* _text */
};
unsigned long pattern_kallsyms_addresses3[] = {
	0xc00081c0,	/* asm_do_IRQ */
	0xc00081c0,	/* _stext */
	0xc00081c0	/* __exception_text_start */
};
unsigned long kallsyms_num_syms;
unsigned long *kallsyms_addresses;
unsigned char *kallsyms_names;
unsigned char *kallsyms_token_table;
unsigned short *kallsyms_token_index;
unsigned long *kallsyms_markers;

unsigned long sony_ric_enabled_address = 0;
unsigned long ric_enable_address = 0;

int read_value_at_address(unsigned long address, unsigned long *value) {
	unsigned long off;

	off = (address - KERNEL_START_ADDRESS) / 4;
	*value = *(pmem + off);

	return 0;
}

int check_pattern(unsigned long *addr, unsigned long *pattern, int patternnum) {
	unsigned long val;
	unsigned long cnt;
	unsigned long i;

	read_value_at_address((unsigned long)addr, &val);
	if (val == pattern[0]) {
		cnt = 1;
		for (i = 1; i < patternnum; i++) {
			read_value_at_address((unsigned long)(&addr[i]), &val);
			if (val == pattern[i]) {
				cnt++;
			} else {
				break;
			}
		}
		if (cnt == patternnum) {
			return 0;
		}
	}

	return -1;
}

int check_kallsyms_header(unsigned long *addr) {
	if (check_pattern(addr, pattern_kallsyms_addresses, sizeof(pattern_kallsyms_addresses) / 4) == 0) {
		return 0;
	} else if (check_pattern(addr, pattern_kallsyms_addresses2, sizeof(pattern_kallsyms_addresses2) / 4) == 0) {
		return 0;
	} else if (check_pattern(addr, pattern_kallsyms_addresses3, sizeof(pattern_kallsyms_addresses3) / 4) == 0) {
		return 0;
	}

	return -1;
}

int get_kallsyms_addresses() {
	unsigned long *kallsyms_address;
	unsigned long *endaddr;
	unsigned long i, j;
	unsigned long *addr;
	unsigned long n;
	unsigned long val;
	unsigned long off;

	if (read_value_at_address(KERNEL_START_ADDRESS, &val) != 0) {
		fprintf(stderr, "this device is not supported.\n");
		return -1;
	}
	printf("search kallsyms...\n");
	endaddr = (unsigned long *)(KERNEL_START_ADDRESS + KERNEL_SIZE);
	for (i = 0; i < (KERNEL_START_ADDRESS + KERNEL_SIZE - SEARCH_START_ADDRESS); i += 16) {
		for (j = 0; j < 2; j++) {
			/* get kallsyms_addresses pointer */
			if (j == 0) {
				kallsyms_address = (unsigned long *)(SEARCH_START_ADDRESS + i);
			} else {
				if ((i == 0) || ((SEARCH_START_ADDRESS - i) < KERNEL_START_ADDRESS)) {
					continue;
				}
				kallsyms_address = (unsigned long *)(SEARCH_START_ADDRESS - i);
			}
			if (check_kallsyms_header(kallsyms_address) != 0) {
				continue;
			}
			addr = kallsyms_address;
			off = 0;

			/* search end of kallsyms_addresses */
			n = 0;
			while (1) {
				read_value_at_address((unsigned long)addr, &val);
				if (val < KERNEL_START_ADDRESS) {
					break;
				}
				n++;
				addr++;
				off++;
				if (addr >= endaddr) {
					return -1;
				}
			}

			/* skip there is filled by 0x0 */
			while (1) {
				read_value_at_address((unsigned long)addr, &val);
				if (val != 0) {
					break;
				}
				addr++;
				off++;
				if (addr >= endaddr) {
					return -1;
				}
			}

			read_value_at_address((unsigned long)addr, &val);
			kallsyms_num_syms = val;
			addr++;
			off++;
			if (addr >= endaddr) {
				return -1;
			}

			/* check kallsyms_num_syms */
			if (kallsyms_num_syms != n) {
				continue;
			}

			printf("(kallsyms_addresses=%08x)\n", (unsigned int)kallsyms_address);
			printf("(kallsyms_num_syms=%08x)\n", (unsigned int)kallsyms_num_syms);
			kallsymsmem = pmem + (((unsigned long)kallsyms_address - KERNEL_START_ADDRESS) / 4);
			kallsyms_addresses = kallsymsmem;
			endaddr = (unsigned long *)((unsigned long)kallsymsmem + KALLSYMS_SIZE);

			addr = &kallsymsmem[off];

			/* skip there is filled by 0x0 */
			while (addr[0] == 0x00000000) {
				addr++;
				if (addr >= endaddr) {
					return -1;
				}
			}

			kallsyms_names = (unsigned char *)addr;

			/* search end of kallsyms_names */
			for (i = 0, off = 0; i < kallsyms_num_syms; i++) {
				int len = kallsyms_names[off];
				off += len + 1;
				if (&kallsyms_names[off] >= (unsigned char *)endaddr) {
					return -1;
				}
			}

			/* adjust */
			addr = (unsigned long *)((((unsigned long)&kallsyms_names[off] - 1) | 0x3) + 1);
			if (addr >= endaddr) {
				return -1;
			}

			/* skip there is filled by 0x0 */
			while (addr[0] == 0x00000000) {
				addr++;
				if (addr >= endaddr) {
					return -1;
				}
			}
			/* but kallsyms_markers shoud be start 0x00000000 */
			addr--;

			kallsyms_markers = addr;

			/* end of kallsyms_markers */
			addr = &kallsyms_markers[((kallsyms_num_syms - 1) >> 8) + 1];
			if (addr >= endaddr) {
				return -1;
			}

			/* skip there is filled by 0x0 */
			while (addr[0] == 0x00000000) {
				addr++;
				if (addr >= endaddr) {
					return -1;
				}
			}

			kallsyms_token_table = (unsigned char *)addr;

			i = 0;
			while ((kallsyms_token_table[i] != 0x00) || (kallsyms_token_table[i + 1] != 0x00)) {
				i++;
				if (&kallsyms_token_table[i - 1] >= (unsigned char *)endaddr) {
					return -1;
				}
			}

			/* skip there is filled by 0x0 */
			while (kallsyms_token_table[i] == 0x00) {
				i++;
				if (&kallsyms_token_table[i - 1] >= (unsigned char *)endaddr) {
					return -1;
				}
			}

			/* but kallsyms_markers shoud be start 0x0000 */
			kallsyms_token_index = (unsigned short *)&kallsyms_token_table[i - 2];

			return 0;
		}
	}

	return -1;
}

unsigned long kallsyms_expand_symbol(unsigned long off, char *namebuf) {
	int len;
	int skipped_first;
	unsigned char *tptr;
	unsigned char *data;

	/* Get the compressed symbol length from the first symbol byte. */
	data = &kallsyms_names[off];
	len = *data;
	off += len + 1;
	data++;

	skipped_first = 0;
	while (len > 0) {
		tptr = &kallsyms_token_table[kallsyms_token_index[*data]];
		data++;
		len--;

		while (*tptr > 0) {
			if (skipped_first != 0) {
				*namebuf = *tptr;
				namebuf++;
			} else {
				skipped_first = 1;
			}
			tptr++;
		}
	}
	*namebuf = '\0';

	return off;
}

int search_functions() {
	char namebuf[1024];
	unsigned long i;
	unsigned long off;

	for (i = 0, off = 0; i < kallsyms_num_syms; i++) {
		off = kallsyms_expand_symbol(off, namebuf);
		if (strcmp(namebuf, "sony_ric_enabled") == 0) {
			sony_ric_enabled_address = kallsyms_addresses[i];
			return 0;
		}
	}

	return -1;
}

void analyze_sony_ric_enabled() {
	unsigned long i, j, k;
	unsigned long addr;
	unsigned long val;
	unsigned long regnum;
	unsigned long data_addr;

	printf("analyze sony_ric_enabled...\n");
	for (i = 0; i < 0x200; i += 4) {
		addr = sony_ric_enabled_address + i;
		read_value_at_address(addr, &val);
		if ((val & 0xffff0000) == 0xe59f0000) {
			data_addr = addr + (val & 0x00000fff) + 8;
			read_value_at_address(data_addr, &val);
			ric_enable_address = val;
			return;
		}
	}

	return;
}

int get_addresses() {
	if (get_kallsyms_addresses() != 0) {
		fprintf(stderr, "kallsyms_addresses search failed.\n");
		return -1;
	}

	printf("\n");
	if (search_functions() != 0) {
		fprintf(stderr, "sony_ric_enabled not found.\n");
		printf("\n");
		return -1;
	}
	printf("sony_ric_enabled=%08x\n", (unsigned int)sony_ric_enabled_address);

	analyze_sony_ric_enabled();
	if (ric_enable_address == 0) {
		fprintf(stderr, "ric_enable not found.\n");
		printf("\n");
		return -1;
	}
	printf("ric_enable=%08x\n", (unsigned int)ric_enable_address);
	printf("\n");

	return 0;
}

int main(int argc, char **argv) {
	char devicename[PROP_VALUE_MAX];
	char buildid[PROP_VALUE_MAX];
	int fd;

	__system_property_get("ro.build.product", devicename);
	__system_property_get("ro.build.id", buildid);
	printf("ro.build.product=%s\n", devicename);
	printf("ro.build.id=%s\n", buildid);

	fd = open("/dev/kmem", O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "/dev/kmem open failed: %s.\n", strerror(errno));
		return -1;
	}

	pmem = mmap(NULL, KERNEL_SIZE, PROT_READ, MAP_SHARED, fd, KERNEL_START_ADDRESS);
	if (pmem == MAP_FAILED) {
		fprintf(stderr, "mmap failed: %s.\n", strerror(errno));
		close(fd);
		return -1;
	}

	if (get_addresses() != 0) {
		munmap(pmem, KERNEL_SIZE);
		close(fd);
		exit(EXIT_FAILURE);
	}

	munmap(pmem, KERNEL_SIZE);
	close(fd);

	exit(EXIT_SUCCESS);
	return 0;
}
