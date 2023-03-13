
//Volatile this to let the compiler know optimising this could have weird consequences.
//Aka if the compiler optimisizes away the writes to this memory due to the memory 
//Never being used it could mess with our output
static volatile char *VGA_TXT_MODE_MEM = (void*)0xb8000;
static int pos = 0;

//128 should be enough but as we can't allocate memory 
//atleast until we know what memory is free to allocate
//HACK:If Needed this could be increased as the e820 map should 
//be located in BSS section and thus technically could be expanded
#define MAX_E820_ENTRIES 128  

//Basic Int types 
//TODO: proper implementation 
typedef signed int int32_t;
typedef unsigned int uint32_t;

typedef signed char byte;
typedef unsigned char ubyte;

typedef signed char int8_t;
typedef unsigned char uint8_t;

typedef signed short int16_t; 
typedef unsigned short uint16_t;

typedef signed long int64_t;
typedef unsigned long uint64_t;
typedef uint32_t reg32_t;
typedef uint16_t reg16_t;
typedef uint64_t reg64_t; 
typedef uint8_t reg8_t;

//Get the segment of a ptr 
#define REAL_SEG(ptr) ((uint16_t)(((uint64_t)ptr >> 4) & 0xf000))

//Get the offset of a ptr
#define REAL_OFF(ptr) ((uint16_t)(((uint64_t)ptr) & 0xffff));

//Convert a Real mode far pointer to a regular pointer 
#define FAR_PTR_TO_PTR(segment, offset) ((void *)((uint64_t)((segment << 4) + offset)))

void *memset(void *a, int v, uint64_t len) {
    unsigned char *d = a;
    while (len--)
        *d++ = v;
    return a;
}

typedef struct vbe_info_block {
	char vbe_sig[4];
	uint16_t vbe_ver;
	uint16_t str_far_ptr[2];
	uint8_t capabilities[4];
	uint16_t mode_far_ptr[2];
	uint16_t total_memory; //as 64KB blocks 
} __attribute__((packed)) vbe_info_block_t ;

typedef struct x86_regs {
	//General Purpose Registers 
	reg32_t eax;
	reg32_t ebx;
	reg32_t ecx;
	reg32_t edx;

	//Pointer Registers 
	reg32_t edi;
	reg32_t esi;
	reg32_t ebp;

	//Segment Registers 
	reg16_t ds;
	reg16_t es; 
	reg16_t gs;
	reg16_t fs;
}__attribute__((packed)) x86_regs_t;

typedef struct e820_entry {
	uint64_t base;
	uint64_t length;
	uint32_t type; 
	uint32_t acpi3;
} e820_entry_t;

void x86int_64(uint8_t int_no, x86_regs_t *regs);

void put(char c) {
	*(VGA_TXT_MODE_MEM + pos) = c;
	pos += 2;
}

void putsn(char *str, int size) {
	for(int i = 0; i < size; ++i) {
		put(str[i]);
	}
}

void puts(char *str) {
	while(*str != '\0') {
		put(*str);
		str++;
	}
}

void put_uint(uint32_t i) {
	char buffer[32] = { 0 };
	uint32_t tmp = i; 
	uint32_t digit_count = 0;
	while(tmp) {
		tmp /= 10;
		digit_count++;
	}
	buffer[digit_count] = '\0';
	while(i) {
		int digit = i % 10; 
		buffer[digit_count - 1] = digit + 0x30; 
		digit_count--;

		i = i / 10;
	}

	puts(buffer);


}

/* Get upto MAX_E820_ENTRIES
 */
static e820_entry_t mmap[128] = { 0 };

void get_e820_map() {
	x86_regs_t regs = { 0 };
	regs.eax = 0xe820;
	regs.edx = 0x534D4150;

	//Uhhhhh so to get the memory map I need ebx result
}


int scboot_main() {
	while(1) {

	}
	return 0;
}
