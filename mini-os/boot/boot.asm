bits 16
org 0x7c00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10

    ; Enable A20
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Check 64-bit support
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz no_long_mode

    ; Set up page tables
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 1024
    rep stosd
    mov dword [0x1000], 0x2003
    mov dword [0x1004], 0
    mov dword [0x2000], 0x3003
    mov dword [0x2004], 0
    mov dword [0x3000], 0x4003
    mov dword [0x3004], 0
    mov edi, 0x4000
    mov eax, 0x00000003
    mov ecx, 512
.map_pages:
    stosd
    mov dword [edi], 0
    add edi, 4
    add eax, 0x1000
    loop .map_pages

    ; Set CR3
    mov eax, 0x1000
    mov cr3, eax

    ; Load kernel (20 sectors from LBA 1)
    mov ax, 0x8000
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 20
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x00
    int 0x13
    jc disk_error

    ; Verify kernel (check first 4 words)
    mov ax, 0x8000
    mov es, ax
    xor bx, bx
    mov cx, 4
.verify_loop:
    mov ax, [es:bx]
    test ax, ax
    jnz .valid_data
    add bx, 2
    loop .verify_loop
    jmp kernel_load_error
.valid_data:
    mov al, 'K'
    call print_char

    ; Load GDT
    lgdt [gdt_descriptor]

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Enable long mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging and protected mode
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 0
    mov cr0, eax

    jmp 0x08:long_mode

print_char:
    mov ah, 0x0e
    int 0x10
    mov al, 0x0d  ; CR
    int 0x10
    mov al, 0x0a  ; LF
    int 0x10
    ret

no_long_mode:
    mov al, 'E'
    call print_char
    mov al, '1'
    call print_char
    jmp $

disk_error:
    mov al, 'E'
    call print_char
    mov al, '2'
    call print_char
    jmp $

kernel_load_error:
    mov al, 'E'
    call print_char
    mov al, '3'
    call print_char
    jmp $

gdt_start:
    dq 0
    dq 0x00209A0000000000
    dq 0x0000920000000000
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

bits 64
long_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Copy kernel (10240 bytes = 1280 quadwords)
    mov rsi, 0x80000
    mov rdi, 0x100000
    mov rcx, 1280
    rep movsq

    jmp 0x100000

times 510-($-$$) db 0
dw 0xAA55