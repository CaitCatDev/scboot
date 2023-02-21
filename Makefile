.POSIX:
.PRAGMA: target_name
CC=clang
ASM=nasm
ARCH=x86_64
LD=ld.lld
OBJDUMP=llvm-objdump
VM=qemu-system-${ARCH}
VM_ARGS=-d int --no-reboot
S1_TARGET=mbr.bin

S2_TARGET=stage2.bin
S2_OBJS=start.o

.PHONY: biostest clean

all: ${S1_TARGET} ${S2_TARGET}


verbose:
	echo ${S2_SRC}
	echo ${S2_OBJ}

bios.img: all
	dd if=/dev/zero of=$@ bs=512 count=102400
	dd if=$(S1_TARGET) bs=512 count=1 seek=0 conv=notrunc of=$@
	dd if=$(S2_TARGET) count=1 seek=1 conv=notrunc of=$@

biostest: bios.img
	${VM} ${VM_ARGS} -hda bios.img

mbr.bin: src/arch/x86_64/bios/mbr/mbr.asm
	$(ASM) -fbin src/arch/x86_64/bios/mbr/mbr.asm -o $@

${S2_TARGET}: stage2.elf 
	objcopy -O binary -I elf64-x86-64 stage2.elf $@

stage2.elf: $(S2_OBJS)
	${LD} -T ./ld-scripts/x86_64-bios.ld

start.o: src/arch/x86_64/bios/stage2/start.asm
	$(ASM) -felf64 src/arch/x86_64/bios/stage2/start.asm -o $@ 

clean:
	rm *.bin *.o *.img *.elf
