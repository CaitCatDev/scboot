;Stage 2 format
;
;Sector 1 contains some BIOS code and a boot signature
;The boot signature is used to guard against half done 
;installs. Where stage 2 was not installed or was 
;improperly installed but the MBR was installed and 
;it's variables where set.
;
;Sector 2 contains the Protect mode start point 
;The MBR can be swapped out with one that sets the
;PC into Protected mode it just needs to call with 
;an offset of 0x200
;
[bits 16] 
section .rm_text ;Real Mode Text section 
global _start

_start:
	mov ax,0x1000 
	mov ds,ax
	mov es,ax 

	mov al,'S'
	mov ah,0x0e 
	int 0x10 
	mov al,'2'
	mov ah,0x0e 
	int 0x10

_setup_gdt:
	cli
	lgdt[ds:_gdtr-0x10000]

	mov eax,0x11  
	mov cr0,eax
	
	jmp dword 0x18:0x10200

_rm_halt_loop:
	cli 
	hlt 
	jmp _rm_halt_loop


_gdt:
	.null: 
	dq 0x00 
	.code16:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x9a ;access byte 
	db 0x8f ;flags and limit 
	db 0x00

	.data16:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x92 ;access byte 
	db 0x8f ;flags and limit 
	db 0x00
	
	.code32:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x9a ;access byte 
	db 0xcf ;flags and limit 
	db 0x00
	
	.data32:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x92 ;access byte 
	db 0xcf ;flags and limit 
	db 0x00
	
	.code64:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x9a ;access byte 
	db 0xaf ;flags and limit 
	db 0x00
	
	.data64:
	dw 0xffff ;limit low 
	dw 0x0000 ;base low 
	db 0x00 ;base med 
	db 0x9a ;access byte 
	db 0xaf ;flags and limit 
	db 0x00

.end:

_gdtr: 
	.size: dw _gdt.end - _gdt
	.offset: dd _gdt 

times 510 - ($ - $$) db 0x00 
dw 0xaa55 ;Same as BIOS MAGIC 

[bits 32] 
section .pm_text ;Protected Mode Text section 
pm_init:
mov ax,0x20 
mov ds,ax
mov es,ax
mov ss,ax
mov es,ax
mov fs,ax

mov byte[0xb8000],'l'
//TODO setup paging 
//TODO 

_hlt_loop32:
	cli 
	hlt 
	jmp _hlt_loop32
