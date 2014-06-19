/* writekmem */

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

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>

int main(int argc, char **argv) {
	int fd;
	int *pmem;
	unsigned int addr;
	unsigned int off;
	unsigned int val;

	if (argc != 3) {
		printf("usage: writekmem [address] [value]\n");
		return -1;
	}

	addr = strtoul(argv[1], NULL, 16);
	val = strtoul(argv[2], NULL, 16);

	fd = open("/dev/kmem", O_RDWR);
	if (fd < 0) {
		printf("open failed.\n");
		return -1;
	}

	pmem = mmap(NULL, 0x20000000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0xc0000000);
	if (pmem == MAP_FAILED) {
		printf("mmap failed.\n");
		close(fd);
		return -1;
	}

	off = (addr - 0xc0000000) / 4;
	*(pmem + off) = val;
	printf("%08x: %08x\n", addr, *(pmem + off));

	munmap(pmem, 0x20000000);
	close(fd);
	return 0;
}
