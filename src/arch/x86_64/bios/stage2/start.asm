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
	mov al,'S'
	mov ah,0x0e 
	int 0x10 
	mov al,'2'
	mov ah,0x0e 
	int 0x10

_rm_halt_loop:
	cli 
	hlt 
	jmp _rm_halt_loop


times 510 - ($ - $$) db 0x00 
dw 0xaa55 ;Same as BIOS MAGIC 

[bits 32] 
section .pm_text ;Protected Mode Text section 
