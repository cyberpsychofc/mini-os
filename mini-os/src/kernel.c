void kprint(const char *str) {
    volatile char *vga_buffer = (volatile char *)0xB8000;
    for (int i = 0; str[i] != '\0'; i++) {
        vga_buffer[i * 2] = str[i];        // Character
        vga_buffer[i * 2 + 1] = 0x07;      // White text on black background
    }
}

void kernel_main() {
    kprint("Mini-OS Kernel is running...");
    while (1) {
        asm volatile("hlt");
    }
}