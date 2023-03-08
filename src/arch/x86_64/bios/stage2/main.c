
//Volatile this to let the compiler know optimising this could have weird consequences.
//Aka if the compiler optimisizes away the writes to this memory due to the memory 
//Never being used it could mess with our output
static volatile char *VGA_TXT_MODE_MEM = (void*)0xb8000;
static int pos = 0;

void put(char c) {
	*(VGA_TXT_MODE_MEM + pos) = c;
	pos += 2;
}

void puts(char *str) {
	while(*str != '\0') {
		put(*str);
		str++;
	}
}

int scboot_main() {
	puts("Personally It's nice to be back in C");
	
	return 0;
}
