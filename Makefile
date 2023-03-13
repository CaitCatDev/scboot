.POSIX:
.PRAGMA: target_name
CC=clang
CFLAGS=-mno-red-zone -ffreestanding -mno-mmx -mno-sse -mno-sse2 
ASM=nasm
ARCH=x86_64
LD=ld.lld
OBJDUMP=llvm-objdump
VM=qemu-system-${ARCH}
VM_ARGS=-d int --no-reboot
S1_TARGET=mbr.bin

S2_TARGET=stage2.bin
S2_OBJS=start.o main.o x86_int.o  

.PHONY: biostest clean

all: ${S1_TARGET} ${S2_TARGET}


bios.img: all
	dd if=/dev/zero of=$@ bs=512 count=102400
	./install $(S1_TARGET) $(S2_TARGET) $@

biostest: bios.img
	${VM} ${VM_ARGS} -hda bios.img

mbr.bin: src/arch/x86_64/bios/mbr/mbr.asm
	$(ASM) -fbin src/arch/x86_64/bios/mbr/mbr.asm -o $@

${S2_TARGET}: stage2.elf 
	objcopy -O binary -I elf64-x86-64 stage2.elf $@

stage2.elf: $(S2_OBJS)
	${LD}  -T ./ld-scripts/x86_64-bios.ld

start.o: src/arch/x86_64/bios/stage2/start.asm
	$(ASM) -felf64 src/arch/x86_64/bios/stage2/start.asm -o $@ 

main.o: src/arch/x86_64/bios/stage2/main.c 
	$(CC) $(CFLAGS) -c src/arch/x86_64/bios/stage2/main.c -o $@

x86_int.o: src/arch/x86_64/bios/stage2/x86_int.asm 
	$(ASM) -felf64 src/arch/x86_64/bios/stage2/x86_int.asm -o $@

clean:
	rm *.bin *.o *.img *.elf
