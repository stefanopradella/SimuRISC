.global _start
.section .text.init

_start:
    la x1, testvar

    lh x2, 0(x1)
    lb x3, 1(x1)
    
    lbu x4, 0(x1)
    lhu x5, 1(x1)

    li x1, 3
    sll x6, x2, x1
    srl x7, x2, x1
    sra x8, x2, x1

    la x1, dest 
    sb x2, 0(x1)
    sh x3, 4(x1)
    sw x4, 8(x1)
    sw x5, 12(x1)
    sw x6, 16(x1)
    sw x7, 20(x1)
    sw x8, 24(x1)
    
    la x16, tohost           # assembled as auipc + addi
    li x17, 1
    sw x17, 0(x16)

.section .tohost
    .align 6
    .global tohost
tohost: 
    .dword 0

.section .data
variable: 
    testvar:    .word   0xdeadbeef
    dest:       .word   0x0
