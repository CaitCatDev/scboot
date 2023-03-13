[bits 64] 
section .text 

; rbx, rsp, rbp, r12, r13, r14, and r15
global x86int_64
;;
; Call a 16 bit interrupt from 64bit long mode 
; TODO: Implement output registers 
; as at the minute error info placed in registers 
; are not returned 
;;
x86int_64:
	;Save Sys-V 64 preserve registers 
	push rbx 
	push r12 
	push r13
	push r14
	push r15 
	push rbp
	;Setup far return 
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
	
	;Restore Sys-V 64 preserve registers 
	pop rbp
	pop r15 
	pop r14 
	pop r13 
	pop r12 
	pop rbx

	retq ;Return to 64-bit C code 

[bits 32] 
;;
; ebx, esi, edi, ebp, and esp
; Call a 16 bit interrupt from 32bit protected mode 
; TODO: Implement output registers 
; as at the minute error info placed in registers 
; are not returned 
; This is a different call point in the stack 
;;
x86int_32:
	mov ax,0x20 ;32bit data selector index 
	mov ds,ax
	mov ss,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 

	mov dword[registers],esi
	

	sgdt [gdtr_save] ;Save our GDTR(Technically this isn't needed)
	;But it's just an idea in case Buggy bios that may 
	;overwrite the GDTR. (It shouldn't but when it comes to 
	;BIOS it's better to be more cautious than less)

	sidt [idtr_save] ;Save our IDTR

	mov eax,edi ;Move argv 0 into eax 
	mov byte[x86int_rm.int_no],al ;overwrite interrupt instruction byte

	lidt [idtr_real] ;Set idt to 16bit BIOS IVT 

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
	mov ax,0x10 ;16bit data selector index 
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
	mov ax,0x1000 ;Set segment Registers 
	mov ds,ax
	mov es,ax
	mov gs,ax
	mov fs,ax 
	mov ax,0x1000
	mov ss,ax

	;;
	; TODO: get interrupt data from 64-bit c to 16-bit asm
	;A structure of some sort? 
	;Storing on the stack? 
	;;
	mov [ss:stack_save - 0x10000],esp
	mov esp,[ss:registers - 0x10000]
	xor ax,ax
	mov ss,ax
	pop eax 
	pop ebx
	pop ecx 
	pop edx 
	
	pop edi

	pop esi 
	pop ebp;

	pop ds 
	pop es 
	pop gs 
	pop fs;
	
	sti

	db 0xcd ;x86 int instruction 
	.int_no: ;Overwrite this byte to change the int 
	db 0x00 ; 0xcd10 -> int 0x10 instruction 


	
	cli

	mov ax,0x1000 
	mov ss,ax 

	mov esp,dword[ss:stack_save - 0x10000]


	lidt[ss:(idtr_save - 0x10000)]

	lgdt[ss:(gdtr_save - 0x10000)]

	mov eax,cr0 ;Move Cr0 into eax 
	or eax,0x1  ;Set protected mode bit 
	mov cr0,eax ;Set CR0 to eax enabling pmode 

	jmp dword 0x0018:x86int_32_ret 


idtr_real: 
	dw 0x03ff 
	dd 0x0000 

idtr_save:
	dw 0x0000 
	dd 0x0000

gdtr_save:
	dw 0x0000 
	dd 0x0000 

stack_save:
	dd 0x0000 

registers:
 	dd 0x0000
