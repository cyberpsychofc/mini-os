bits 16		; 16 bit real mode
org 0x7c00	; BIOS loads OS at this address

start:
	; Setting up segment registers
	xor ax, ax	; Zero out AX
	mov ds, ax	; Data Segment
	mov es, ax	; Extra Segment
	mov ss, ax 	; Stack segment
	mov sp, 0x7c00	; Set Stack Pointer just below the bootloader

	; Clear screen in real mode
	mov ax, 0x0600
	mov bh, 0x07
	xor cx, cx
	mov dx, 0x184F
	int 0x10

	; Printing an output in real mode
	mov si, real_mode_msg
	call print_string

	; Disable interrupts
	cli

	; Enabling A20 line (simple method via keyboard controller)
	in al, 0x92
	or al, 2
	out 0x92, al

	; Check for 64 bit support
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29	; Check for long mode bit
	jz no_long_mode

	; Paging
	mov edi, 0x1000		; Start of page tables
	mov cr3, edi		; Set CR3 to PML4 base
	xor eax, eax
	mov ecx, 0x1000		; Clear 4 KB (PML4, PDP, PD, PT)
	rep stosb

	; PML4: Map first entry to PDP
	mov edi, 0x1000
	mov dword [edi], 0x2003	; PDP base (0x2000) + present + writable

	; PDP: Map first entry to PD
	mov edi, 0x2000
	mov dword [edi], 0x3003	; PD base (0x3000) + present + writable

	; PD: Map first entry to PT
	mov edi, 0x3000
	mov dword [edi], 0x4003	;PT base (0x4000) + present + writable

	; PT: Identify map first 2 MB (512 * 4 KB pages)
	mov edi, 0x4000
	mov ebx, 0x0003	; Page base + present + writable
	mov ecx, 512	; 512 entries
.pt_loop:
	mov [edi], ebx
	add ebx, 0x1000	; Next 4 KB page
	add edi, 8
	loop .pt_loop

	; Enable PAE
	mov eax, cr4
	or eax, 1<<5	; Set PAE bit
	mov cr4, eax

	; Load GDT
	lgdt [gdt_descriptor]

	; Enable long mode (64 bit)
	mov ecx, 0xC0000080	; EFER MSR
	rdmsr
	or eax, 1 << 8		; Set long mode bit
	wrmsr

	; Enable paging and protected mode
	mov eax, cr0
	or eax, 1 << 31		; Set paging bit
	or eax, 1 << 0		; Set protected mode bit
	mov cr0, eax

	jmp 0x08:long_mode

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
no_long_mode:
	mov si, no_long_mode_msg
	call print_string
	jmp $

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
	db 0xAF		; Granularity (4k pages) + Limit (16-19 bits)
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
no_long_mode_msg db "Long mode not supported!", 0

bits 64		; 64 bit Long Mode
long_mode:
	; Set up segment registers for protected mode
	mov ax, 0x10	; Data segment selector
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	; Clear VGA Buffer
	mov edi, 0xB8000
	mov rax, 0x0720072007200720	; Space char + white on black
	mov ecx, 500
	rep stosq

	; Print VGA Buffer
	mov edi, 0xB8000	; VGA text buffer address
	mov rsi, long_mode_msg
	mov ah, 0x07		; White on black attr
.print_loop:
	lodsb			; Load next byte from ESI
	cmp al, 0
	je .done
	mov [edi], ax		; Write character and attr to VGA
	add edi, 2		; Move to VGA Position
	jmp .print_loop
.done:
	hlt

long_mode_msg db "Booting in 64 bit long Mode...", 0
times 510-($-$$) db 0	; Pad to 510 bytes
dw 0xAA55		; Boot signature
