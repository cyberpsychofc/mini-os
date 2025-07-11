volatile unsigned char *video_memory = (unsigned char *)0xb8000;
static int cursor_pos = 0;
static const int SCREEN_WIDTH = 80;
static const int SCREEN_HEIGHT = 25;

void clear_screen() {
    for (int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT * 2; i++) {
        video_memory[i] = 0;
    }
    cursor_pos = 0;  // Reset cursor position
}

void print_char(char c) {
    if (c == '\n') {
        // Move to next line
        cursor_pos = ((cursor_pos / SCREEN_WIDTH) + 1) * SCREEN_WIDTH;
    } else {
        if (cursor_pos < SCREEN_WIDTH * SCREEN_HEIGHT) {
            video_memory[cursor_pos * 2] = c;           // Character
            video_memory[cursor_pos * 2 + 1] = 0x0F;    // White on black
            cursor_pos++;
        }
    }
    
    if (cursor_pos >= SCREEN_WIDTH * SCREEN_HEIGHT) {
        cursor_pos = 0;
    }
}

void print_string(const char* str) {
    int i = 0;
    while (str[i] != '\0') {
        print_char(str[i]);
        i++;
    }
}

void print_hex(unsigned long value) {
    const char hex_chars[] = "0123456789ABCDEF";
    char buffer[17];
    buffer[16] = '\0';
    
    for (int i = 15; i >= 0; i--) {
        buffer[i] = hex_chars[value & 0xF];
        value >>= 4;
    }
    
    print_string("0x");
    print_string(buffer);
}

void kernel_main() {
    clear_screen();
    print_string("Mini-OS Kernel is running!\n");
    print_string("64-bit Long Mode Active\n");
    
    print_string("Video Memory: ");
    print_hex((unsigned long)video_memory);
    print_string("\n");
    
    print_string("Kernel loaded successfully!\n");
    
    // Halt the CPU
    while (1) {
        asm volatile("hlt");
    }
}

// Entry point for the bootloader
void _start() {
    kernel_main();
    
    while (1) {
        asm volatile("hlt");
    }
}