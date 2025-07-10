bits 16			; 16 bit real mode
org 0x7c00		; BIOS loads OS at this address

start:
	cli
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

	; Enabling A20 line (simple method via keyboard controller)
	in al, 0x92
	or al, 2
	out 0x92, al

	; Check for 64 bit support
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29	; Check for long mode bit
	jz no_long_mode

	; Load kernel using INT 13h, 10 sectors from LBA 1
	mov bx, 0x8000
	mov es, bx
	xor bx, bx	; Offset 0
	mov ah, 0x02	; BIOS read sector function
	mov al, 10	; 10 sectors
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, 0x80
	int 0x13
	jc disk_error	; If fails to load kernel

	; Load GDT
	lgdt [gdt_descriptor]

	; Enable PAE
	mov eax, cr4
	or eax, 1<<5	; Set PAE bit
	mov cr4, eax

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
disk_error:
	mov si, disk_error_msg
	call print_string
	jmp $

; GDT config

gdt_start:
	; Null Descriptor
	dq 0
	dq 0x00AF9A000000FFFF	; Code Segment
	dq 0x00AF92000000FFFF	; Data Segment
gdt_end:
gdt_descriptor:
	dw gdt_end - gdt_start - 1	; GDT size
	dq gdt_start			; GDT addr

; Messages
real_mode_msg db "Booting in Real Mode...", 0
no_long_mode_msg db "Long mode not supported!", 0
disk_error_msg db "Disk read failed!", 0

bits 64		; 64 bit Long Mode
long_mode:
	; Set up segment registers for protected mode
	mov ax, 0x10	; Data segment selector
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	; Setup identity-mapped page tables
    mov rdi, 0x1000         ; PML4
    xor rax, rax
    mov rcx, 0x1000 / 8     ; Clear 4KB

.zero_page_tables:
    mov qword [rdi], rax
    add rdi, 8
    loop .zero_page_tables

    ; Build paging structure
    mov qword [0x1000], 0x2003      ; PML4 to PDP
    mov qword [0x2000], 0x3003      ; PDP to PD
    mov qword [0x3000], 0x4003      ; PD to PT

    mov rdi, 0x4000                 ; PT entries
    mov rbx, 0x0000000000000003
    mov rcx, 512
.map_pages:
    mov qword [rdi], rbx
    add rbx, 0x1000
    add rdi, 8
    loop .map_pages

	; Copy kernel from 0x80000 to 0x100000
    mov rsi, 0x80000
    mov rdi, 0x100000
    mov rcx, (5120 / 8)      ; 10 sectors = 640 qwords
.copy_loop:
    mov rax, [rsi]
    mov [rdi], rax
    add rsi, 8
    add rdi, 8
    loop .copy_loop

	jmp 0x100000

long_mode_msg db "Booting in 64 bit long Mode...", 0
times 510-($-$$) db 0			; Pad to 510 bytes
dw 0xAA55				; Boot signature
