# === Tools ===
CC = gcc
AS = nasm
LD = x86_64-elf-ld
OBJCOPY = x86_64-elf-objcopy
DD = dd
QEMU = qemu-system-x86_64

# === Directories ===
BUILD_DIR = build
BOOT_DIR = boot
KERNEL_DIR = src

# === Flags ===
CFLAGS = -ffreestanding -m64 -nostdlib -mno-red-zone -fno-stack-protector -Wall -Wextra -c
LDFLAGS = -T $(KERNEL_DIR)/kernel.ld -nostdlib
ASFLAGS = -f bin

# === Targets ===
all: $(BUILD_DIR)/os_image.bin

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Assemble bootloader
$(BUILD_DIR)/boot.bin: $(BOOT_DIR)/boot.asm | $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

# Compile kernel
$(BUILD_DIR)/kernel.o: $(KERNEL_DIR)/kernel.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@

# Link kernel with linker script
$(BUILD_DIR)/kernel.elf: $(BUILD_DIR)/kernel.o | $(BUILD_DIR)
	$(LD) $(LDFLAGS) -o $@ $<

# Extract binary from ELF
$(BUILD_DIR)/kernel.bin: $(BUILD_DIR)/kernel.elf
	$(OBJCOPY) -O binary $< $@

# Create properly sized OS image (1.44MB floppy)
$(BUILD_DIR)/os_image.bin: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=$(BUILD_DIR)/boot.bin of=$@ conv=notrunc bs=512 count=1
	$(DD) if=$(BUILD_DIR)/kernel.bin of=$@ conv=notrunc bs=512 seek=1

# Run in QEMU as floppy
run: $(BUILD_DIR)/os_image.bin
	$(QEMU) -fda $< -m 512M

# Debug with QEMU and GDB
debug: $(BUILD_DIR)/os_image.bin
	$(QEMU) -fda $< -m 512M -s -S -gdb tcp::1234 &
	gdb $(BUILD_DIR)/kernel.elf \
		-ex 'target remote localhost:1234' \
		-ex 'break _start' \
		-ex 'continue'

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Show build info
info:
	@echo "=== Build Information ==="
	@echo "Bootloader size: $$(stat -c%s $(BUILD_DIR)/boot.bin 2>/dev/null || echo 'Not built') bytes"
	@echo "Kernel size: $$(stat -c%s $(BUILD_DIR)/kernel.bin 2>/dev/null || echo 'Not built') bytes"
	@echo "Image size: $$(stat -c%s $(BUILD_DIR)/os_image.bin 2>/dev/null || echo 'Not built') bytes"

.PHONY: all run debug clean info