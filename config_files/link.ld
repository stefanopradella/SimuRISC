MEMORY
{
ROM (rwx) : ORIGIN = 0x00002000, LENGTH = 0x6000
RAM (rwx) : ORIGIN = 0x00008000, LENGTH = 0x8000
}

SECTIONS
{
    . = 0x2000;
    .text : { *(.text) } > ROM
    . = 0x8000;
    .data : { *(.data) } > RAM
}
