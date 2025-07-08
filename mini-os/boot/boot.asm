bits 16		; 16 bit real mode
org 0x7c00	; BIOS loads OS at this address

start:
	; Setting up segment registers
	xor ax, ax	; Zero out AX
	mov ds, ax	; Data Segment
	mov es, ax	; Extra Segment
	mov ss, ax 	; Stack segment
	mov sp, 0x7c00	; Set Stack Pointer just below the bootloader

	; Printing an output
	mov si, msg
	call print_string

	; Infinite Loop
	jmp $		;Jump to current instruction

print_string:
	mov ah, 0x0e	; BIOS teletype output function
.loop:
	lodsb		; Load next byte from [SI] into AL, increment SI
	cmp al, 0	; Check if end of string
	je .done
	int 0x10	; Call BIOS to print character in AL
	jmp .loop
.done:
	ret
msg db "Booting Mini-OS...", 0
times 510-($-$$) db 0	; Pad to 510 bytes
dw 0xAA55
