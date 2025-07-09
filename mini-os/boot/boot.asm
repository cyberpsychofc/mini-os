bits 16		; 16 bit real mode
org 0x7c00	; BIOS loads OS at this address

start:
	; Setting up segment registers
	xor ax, ax	; Zero out AX
	mov ds, ax	; Data Segment
	mov es, ax	; Extra Segment
	mov ss, ax 	; Stack segment
	mov sp, 0x7c00	; Set Stack Pointer just below the bootloader

	; Printing an output in real mode
	mov si, real_mode_msg
	call print_string

; Delay in loop
	mov cx, 0xFFFF
.delay:
	loop .delay

	; Disable interrupts
	cli

	; Enabling A20 line (simple method via keyboard controller)
	in al, 0x92
	or al, 2
	out 0x92, al

	; Load GDT
	lgdt [gdt_descriptor]

	; Switch to Protected Mode
	mov eax, cr0
	or eax, 1	; Set Protected Mode Bit
	mov cr0, eax

	; Far jump to 32 bit code (0x80 is code seg)
	jmp 0x08:protected_mode

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

; GDT definition

gdt_start:
	; Null Descriptor
	dq 0x0000000000000000

	; Code Segment Descriptor
	; Base=0, Limit=0xFFFFFF, Access=0x9A (present, code, executable)

	dw 0xFFFF	; Limit (0-15 bits)
	dw 0x0000	; Base (0-15 bits)
	db 0x00		; Base (16-23 bits)
	db 0x9A		; Access byte (present, ring 0, data)
	db 0xCF		; Granularity (4k pages) + Limit (16-19 bits)
	db 0x00		; Base (24-31 bits)

	; Data Segment Descriptor
	; Base=0, Limit=0xFFFF, Access=0x92 (present, data, read/write)
	dw 0xFFFF	; Same as Code Seg.
	dw 0x0000
	db 0x00
	db 0x92
	db 0xCF
	db 0x00
gdt_end:
gdt_descriptor:
	dw gdt_end - gdt_start - 1	; GDT size
	dd gdt_start			; GDT addr

; Messages
real_mode_msg db "Booting in Real Mode...", 0

bits 32		; 32 bit Protected Mode
protected_mode:
	; Set up segment registers for protected mode
	mov ax, 0x10	; Data segment selector
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	; Clear VGA Buffer
	mov edi, 0xB8000
	mov ecx, 1000
	mov ax, 0x0720
	rep stosw		; Fill VGA Buffer with spaces

	; Print VGA Buffer
	mov edi, 0xB8000	; VGA text buffer address
	mov esi, protected_mode_msg
	mov ah, 0x07		; White on black attr
.print_loop:
	lodsb			; Load next byte from ESI
	cmp al, 0
	je .done
	mov [edi], ax		; Write character and attr to VGA
	add edi, 2		; Move to VGA Position
	jmp .print_loop
.done:
	; Infinite Mode
	jmp $

protected_mode_msg db "Booting in Protected Mode...", 0
times 510-($-$$) db 0	; Pad to 510 bytes
dw 0xAA55		; Boot signature
