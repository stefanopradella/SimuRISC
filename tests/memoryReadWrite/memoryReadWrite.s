.global _start
.section .text.init

_start:
    lw x1, src1
    lw x2, src2
    lw x3, src3
    la x4, dst1
    sw x1, 0(x4)
    sw x2, 4(x4)
    sw x3, 8(x4)

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
    src2:       .word 8
    src3:       .word 9
    dst1:       .word 0
    dst2:       .word 0
    dst3:       .word 0