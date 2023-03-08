#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#define X86_BIOS_LBA_OFF 430 
#define X86_BIOS_SIZE_OFF 438 

typedef struct scboot_ins_cfg {
	char *mbr_path;
	char *stage2_path;
	char *device_path;

	uint8_t mbr_data[512];
	uint8_t *stage2_data;
	

	int debug;
} scboot_ins_cfg_t;

static scboot_ins_cfg_t config = { 0 };

void parse_args(int argc, char **argv) {
	config.mbr_path = argv[1];
	config.stage2_path = argv[2];
	config.device_path = argv[3];
}

void install_x86_bios_mbr() {
	int mbr_fd = open(config.mbr_path, O_RDONLY);
	int stage2_fd = open(config.stage2_path, O_RDONLY);
	int device_fd = open(config.device_path, O_RDWR);
	uint64_t lba = 1;
	uint16_t stage2_size = lseek(stage2_fd, 0, SEEK_END);
	lseek(stage2_fd, 0, SEEK_SET);
	config.stage2_data = calloc(1, stage2_size);

	size_t mbr_size = 512;

	/*read in bootloader data*/
	read(mbr_fd, config.mbr_data, mbr_size); 
	read(stage2_fd, config.stage2_data, stage2_size);

	write(device_fd, config.mbr_data, mbr_size);
	
	write(device_fd, config.stage2_data, stage2_size);
	
	lseek(device_fd, X86_BIOS_SIZE_OFF, SEEK_SET);
	write(device_fd, &stage2_size, sizeof(stage2_size));
	
	lseek(device_fd, X86_BIOS_LBA_OFF, SEEK_SET);
	write(device_fd, &lba, sizeof(uint64_t));
	
	close(mbr_fd);
	close(stage2_fd);
	close(device_fd);
}

int main(int argc, char **argv) {
	parse_args(argc, argv);
	
	install_x86_bios_mbr();

	return 0;
}
