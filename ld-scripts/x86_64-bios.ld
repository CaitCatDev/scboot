ENTRY(_start)
OUTPUT_FORMAT(elf64-x86-64) 
INPUT(start.o)

OUTPUT(stage2.elf)

SECTIONS {
	. = 0x10000;
	.text : {
		*(.rm_text)
		*(.pm_text)
		*(.text)
	}

	.data : {
		*(.data)
	}

	.rodata : {
		*(.rodata*)
	}

	.bss : {
		_BSS_START = .;
		*(.bss)
		_BSS_END = .;
	}

}
