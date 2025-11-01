.global _start
.section .text.init

_start:
    nop
    nop
    li x1, 1
    addi x2, x1, 1
    nop 
    nop 
    nop 
    nop 
    nop

    la x1, tohost
    li x2, 1
    sw x2, 0(x1)

.section .tohost
    .align 6
    .global tohost
tohost: 
    .dword 0

.section .data
variable:
    src1:       .word 7