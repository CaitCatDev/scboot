CC=clang
ASM=nasm
ARCH=x86_64
LD=ld.lld
OBJDUMP=llvm-objdump
VM=qemu-system-${ARCH}
VM_ARGS=-d int --no-reboot
S1_TARGET=./mbr.bin

S2_TARGET=./stage2.bin
S2_SRC=$(wildcard ./src/arch/x86_64/bios/stage2/*.asm)
S2_OBJ=$(patsubst ./src/arch/x86_64/bios/stage2/%.asm, %.o, ${S2_SRC})

.PHONY: bios-test clean

all: ${S1_TARGET} ${S2_TARGET}

verbose:
	echo ${S2_SRC}
	echo ${S2_OBJ}

bios.img: all
	dd if=/dev/zero of=$@ bs=512 count=102400
	dd if=$(S1_TARGET) bs=512 count=1 seek=0 conv=notrunc of=$@
	dd if=$(S2_TARGET) count=1 seek=1 conv=notrunc of=$@

bios-test: bios.img
	${VM} ${VM_ARGS} -hda $^

${S1_TARGET}: ./src/arch/x86_64/bios/mbr/mbr.asm 
	${ASM} -fbin $^ -o $@

${S2_TARGET}: stage2.elf 
	objcopy -O binary -I elf64-x86-64 $^ $@

stage2.elf: ${S2_OBJ}
	${LD} -T ./ld-scripts/x86_64-bios.ld

%.o: ./src/arch/x86_64/bios/stage2/%.asm
	${ASM} -felf64 $^ -o $@

clean:
	rm *.bin *.o *.img *.elf
