OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start)

SECTIONS {
    /* Load the kernel at 0x100000 */
    . = 0x100000;

    /* Text (code) section */
    .text : {
        *(.text)
    }

    /* Read-only data */
    .rodata : {
        *(.rodata)
    }

    /* Data section */
    .data : {
        *(.data)
    }

    /* BSS section (zero-initialized data) */
    .bss : {
        *(.bss COMMON)
    }
}