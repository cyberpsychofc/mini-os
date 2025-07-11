ENTRY(_start)

SECTIONS
{
    . = 0x100000;
    
    _kernel_start = .;
    
    .text : ALIGN(4K)
    {
        *(.text.startup)
        *(.text)
    }
    
    .rodata : ALIGN(4K)
    {
        *(.rodata*)
    }
    
    .data : ALIGN(4K)
    {
        *(.data)
    }
    
    .bss : ALIGN(4K)
    {
        _bss_start = .;
        *(COMMON)
        *(.bss)
        _bss_end = .;
    }
    
    _kernel_end = .;
    
    /DISCARD/ :
    {
        *(.note*)
        *(.comment*)
        *(.eh_frame*)
    }
}