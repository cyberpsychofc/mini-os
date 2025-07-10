# === Tools ===
CC = gcc
AS = nasm
LD = ld
QEMU = qemu-system-x86_64

# === Directories ===
BUILD_DIR = build
BOOT_DIR = boot
KERNEL_DIR = src

# === Flags ===
CFLAGS = -ffreestanding -m64 -nostdlib -mno-red-zone -Wall
LDFLAGS = -T $(KERNEL_DIR)/kernel.ld -nostdlib

# === Targets ===
all: $(BUILD_DIR)/os_image.bin

# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Assemble bootloader
$(BUILD_DIR)/boot.bin: $(BOOT_DIR)/boot.asm | $(BUILD_DIR)
	$(AS) -f bin $< -o $@

# Compile kernel
$(BUILD_DIR)/kernel.o: $(KERNEL_DIR)/kernel.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link kernel with linker script
$(BUILD_DIR)/kernel.bin: $(BUILD_DIR)/kernel.o | $(BUILD_DIR)
	$(LD) $(LDFLAGS) -o $@ $<

# Combine bootloader and kernel into image
$(BUILD_DIR)/os_image.bin: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	cat $^ > $@

# Run in QEMU
run: $(BUILD_DIR)/os_image.bin
	$(QEMU) -drive format=raw,file=$<

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean