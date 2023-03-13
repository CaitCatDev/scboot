[bits 64] 
section .text 

global x86int_64

x86int_64:
	
	push 0x18 ;Push code selector to stack 
	push qword x86int_32 ;Push address to 32-bit code 
	
	retfq ;return far to 32bit pm 

x86int_64_ret:
	mov ax,0x30 ;32bit data selector index 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 
	
	retq ;Return to 64-bit C code 

[bits 32] 
x86int_32:
	mov ax,0x20 ;32bit data selector index 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 

	mov eax,cr0 ;Mov control register into cr0 
	and eax,0x7fffffff ;Unset the paging bit 
	mov cr0,eax ;Paging is now disabled 

	jmp 0x0008:x86int_16

x86int_32_ret:
	mov ax,0x20 ;32bit data selector index 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 

	mov eax,cr0 ;Mov control register into cr0 
	or eax,0x80000000 ;Unset the paging bit 
	mov cr0,eax ;Paging is now disabled 

	jmp 0x0028:x86int_64_ret

[bits 16]
x86int_16:
	mov ax,0x10 ;32bit data selector index 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 

	mov eax,cr0 
	and eax,0x7ffffffe 
	mov cr0,eax

	jmp 0x1000:(x86int_rm - 0x10000)

x86int_rm:
	mov ax,0x1000 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 

	;;
	; TODO: get interrupt data from 64-bit c to 16-bit asm
	;;

	sti 
	mov ax,0x0e00 + 'L'
	xor bx,bx
	int 0x10 
	cli
	
	mov eax,cr0 
	or eax,0x1 
	mov cr0,eax 
	
	jmp dword 0x0018:x86int_32_ret
