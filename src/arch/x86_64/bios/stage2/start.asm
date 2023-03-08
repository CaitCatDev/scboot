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
extern _scboot_bss_start
extern _scboot_bss_end

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
	db 0x92 ;access byte 
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
	mov gs,ax

	call zero_bss
	call setup_paging 
	jmp 0x28:init_lmode

_hlt_loop32:
	cli 
	hlt 
	jmp _hlt_loop32

zero_bss:
	xor eax,eax 
	mov edi,_scboot_bss_start
	.1: 
	stosd ;Store eax into [edi]

	cmp edi,_scboot_bss_end
	jb zero_bss.1 ;fill bss
	ret 

check_l5page: 
	mov eax,0x7
	xor ecx,ecx 
	cpuid 
	test ecx,(1<<16) 
	jz .l4paging
	
	mov byte[page_features],0x01
	.l4paging
	ret 

setup_paging:
	call check_l5page
	
	mov ecx,0x3 
	mov edi,PML4_start
	mov esi,PDP 

	test byte[page_features],0x01 
	jz .no_pml5 
	
	add cl,1 
	mov edi,PML5_start
	mov esi,PML4_start

	.no_pml5:
	or esi,0x3 ;set bits 0-1 
	
	;PML5 -> PML4 -> PDP -> PDE -> PT  
	.fill_page_tables:
	mov dword[edi],esi 
	add edi,0x1000 
	add esi,0x1000 
	loop .fill_page_tables

	and esi,0x3 ;Keep only these bits  
	mov ecx,512
	
	;;
	; Fill the first Page table 
	; Mapping 2MB currently 
	; TODO: Check for 1GB pages 
	; TODO: User 2MB pages 
	;;
	.set_pt_entry: 
	mov dword[edi],esi 
	add esi,0x1000 
	add edi,8 
	loop .set_pt_entry

	;Set LM bit 
	xor eax,eax 
	mov ecx,0xC0000080
	rdmsr 
	or eax,1<<8 
	wrmsr
	
	;Set PAE bit 
	mov eax,cr4 
	or eax,1<<5 
	mov cr4,eax 

	mov eax,PML4_start
	mov cr3,eax 

	test byte[page_features],0x01 
	jz .skip_la57 
	
	mov eax,cr4 ;Set 5 level page  
	or eax,(1<<12)
	mov cr4,eax 

	;Set the CR3 to PM5 
	mov eax,PML5_start ;change eax to point to L5 page table when supported 
	mov cr3,eax 

	.skip_la57:
	;Set CR0 Paging bit 
	mov eax,cr0 
	or eax,1 << 31
	mov cr0,eax
	ret

[bits 64] 
section .text
init_lmode:
	cli 
	mov ax,0x30 
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov gs,ax
	mov fs,ax 

    mov edi, 0xB8000 
    mov rax, 0x1F201F201F201F20 
    mov ecx, 500 
    rep stosq

_hlt_loop64:
	cli 
	hlt 
	jmp _hlt_loop64



section .bss ;BSS segment contains anything that should be 
;set to zero when we run 

;;
; Normally with an ELF file the BSS would be zeroed when the ELF 
; Is loaded by the OS but since we dump to raw binary we need to 
; Zero the BSS ourself.
;;
PML5_start:
	resb 0x1000 
PML4_start:
	resb 0x1000 
PDP:
	resb 0x1000 
PDE: 
	resb 0x1000
PT: 
	resb 0x1000

page_features:
resb 1 
