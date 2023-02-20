[org 0x7c00]
[bits 16]

;;
; This is my first time using structs in asm if you 
; have any advice please let me know. Or if you think
; I did something wrong here let me know. More
; Than aware these first structs probably are not the 
; best/only way to do this.
;;

;Effectively make it so dap.offset resolves to 0x1004.
;Effectively making 0x1000 a dap structure 
struc dap, 0x1000 
	.size: resw 1
	.sectors: resw 1
	.transfer_buffer:
	.offset: resw 1
	.segment: resw 1 
	.low_lba: resd 1 
	.high_lba: resd 1 
	.abs_address: resq 1 ;WE don't use but technically part
endstruc

struc disk_parameters, 0x1100 
	;Version 1.x 
	.size: resw 1 ;0x1a - v1.x, 0x1e - 2.x, 0x42 - v3.0
	.flags: resw 1 
	.cyli_cnt: resd 1 
	.head_cnt: resd 1
	.sect_cnt_track: resd 1 
	.sect_cnt_drive: resq 1
	.sector_size: resw 1 ;From my tests with QEMU this is logical sector size not physical. 
	;That's assuming that logical != physical 
	;Version 2.x
	.edd_config: resd 1
	;Version 3.0 
	.dev_pth_sig: resw 1 
	.dev_pth_len: resb 1 
	.reserved0: resb 3
	.host_bus_name: resb 4
	.iface_type_name: resb 8
	.iface_path: resb 8
	.dev_path: resb 8 
	.reserved1: resb 1
	.checksum: resb 1
endstruc


;;
; TODO: try to save bytes where possible
;;

;; BIOS PARAMETER BLOCK BUG
; Some BIOS seem to overwrite certain fields 
; in the bios parameter block. Likely to try and 
; "Help" with BIOS disk emulation. So we avoid this
; By have the first 90 bytes look like a BPB. 
; THus having the jump instruction to jump past 
; unsafe bytes that may have been overwritten 
;;

;; MBR boot flow 
; 0x7c00 = _start <- Bios drops use here
; _start jumps to 0x7c58 past the BPB
; Thus avoiding potential BPB bugs 
; And technically makes us compatible with
; BIOS that contain a BPB 
; eg a fat floopy
; 0x7c58 = _real_start <- actual bootloader code
;;

_start:
	jmp short _real_start 
	nop ;Some say this is needed for boot
	;Either way I can't alot with one byte 
	;So we opt for supporting weird hardware
	;Rather than discover a differnt use for one byte

_bpb: ;Fill BPB with random garbage
	times 90 - ($ - $$) db 0x00;

_real_start:
	cli ;clear ints well we setup exe env

	xor ax,ax ;Clear ax reg 
	mov ds,ax ;Clear seg regs we use 
	mov ss,ax
	mov es,ax 
	;Don't use gs or fs they are random 
	
	mov sp,0x7c00 ;set stack
	
	add al,0x03 ;Set video mode
	int 0x10
	
	jmp 0x0000:.clear_cs ;far jump to clear cs 

.clear_cs:
	sti ;env should be setup now 
	
	;;
	; TODO we should set GS as an arg for read disk as we need to set it here 
	;anyway 
	;;

	mov cx,word[stage2_size]
	mov ebx,0x10000000
	mov eax,dword[stage2_lba]
	mov ebp,dword[stage2_lba+4]
	call _read_disk

	push 0x1000 
	pop gs
	mov al,'7'
	;Check stage 2 has a valid signature. useful cases were stage2 
	;is improperly installed/was deleted by another bootloader for 
	;example.
	cmp word[gs:0x01fe],0xaa55
	jne _errors

	jmp gs:0x0000
;;SO if an error happens here it isn't great. 
;;As we can't really afford to go using bytes for
;;Strings so we are going to use error numbers
;;AL should be set before call 
_errors: 
.print:
	push 0xb800 ;Video memory start;
	pop es ;es = 0xb800 
	mov ah,0x4f
	mov word[es:0x0000], 'E' + 0x4f00 ;Error e letter
	mov word[es:0x0002], ax ;Error code 

;;
; On error loop endlessly 
;; 
_hlt_endless:
	cli 
	hlt 
	jmp _hlt_endless 

;;
; Read disk function 
; EAX = 32bit low LBA
; EBX = 32bit high LBA
; CX = Stage 2 size  
; DL = disk no
; EBX(0-15) = disk buffer offset 
; EBX(16-32) = disk buffer segment 
; High EBX bytes are in typical real mode segment fashion
; ie 0x1000 * 16 + 0ffset
; e.g. EBX = 0x10000000 translates to abs address 0x10000
;;
;;acordding to https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
;;These BIOS INT calls should completely preserve all the registers (except AX).
;;Also never heard of any issues with the disk read functions 
_read_disk:
	.setup_dap:
	mov word[dap.size],0x0010
	mov word[dap.sectors],0x01 ;read one sector at a time to work around buggy bios's 
	mov dword[dap.transfer_buffer],ebx
	mov dword[dap.low_lba],eax
	mov dword[dap.high_lba],ebp
	push dx ;save drive number for upcomming division 
	push cx ;Preserve this for later use as 0x41 does overwrite 
	
	mov al,'3' ;error 3 = invalid divison size
	test cx,cx 
	jz _errors
	
	.disk_ext_check:
	mov ah,0x41
	mov bx,0x55aa
	int 0x13

	mov al,'0' ;Error Zero 
	jc _errors
	inc al
	cmp bx,0xaa55
	jne _errors
	
	.get_disk_parms:
	mov ah,0x48 
	mov si,disk_parameters
	mov word[disk_parameters.size],0x42 
	int 0x13 
	
	mov al,'2'
	jc _errors
	
	;//bp = sector size.
	mov bp,word[disk_parameters.sector_size]
	xor dx,dx 
	pop ax ;//AX = stage 2 size 
	
	div bp ;//Divide DX:AX by BP 
	mov cx,ax ;CX = sector count to read

	test dx,dx ;Clean division don't round 
	jz .read

	inc cx
	
	.read:
	pop dx
	.read2:
	mov ah,0x42 
	mov si,dap 

	int 0x13 
	mov al,'5'
	jc _errors 

	add word[dap.offset],bp 
	;we oveflowed is stage 2 bigger than a uint16_max?
	inc al ;add one to error code 
	jc _errors
	
	;Calculate new LBA
	add dword[dap.low_lba],1 ;We use add to set carry flag
	adc dword[dap.high_lba],0 ;Add one if carry flag was set from add
	clc	
	
	loop .read2 ;loop cx times 

	ret

times 430 - ($ - $$) db 0x00;pad to have variables place at abs address
stage2_lba: dq 0x01 ;Default is 1 
stage2_size: dw 0x200 ;Default read 1 sector 
times 440 - ($ - $$) db 0x00 ;End of BIOS code 
times 510 - ($ - $$) db 0x00 

;BIOS MAGIC
dw 0xaa55

times 2048 - ($ - $$) db 0
