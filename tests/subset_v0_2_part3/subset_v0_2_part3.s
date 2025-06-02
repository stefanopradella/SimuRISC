.global _start
.section .text.init

_start:
    li x1, 1
    li x2, 10

li x3, 2
li x4, 2
li x5, 3
li x7, 3
lw x6, testvar

bne_test:
    bne x3, x1, blt_test
    beq x4, x3, error

blt_test:
    blt x1, x3, bge_test
    beq x4, x3, error

bge_test:
    bge x5, x3, bltu_test
    beq x4, x3, error

bltu_test:
    bltu x3, x6, bgeu_test
    beq x4, x3, error

bgeu_test:
    bgeu x6, x5, beq_test
    beq x4, x3, error

beq_test:
    beq x7, x5, exit
    beq x4, x3, error

exit:
    la x8, tohost
    li x2, 1
    sw x2, 0(x8)

error:
    li x1, 0xFFFF

.section .tohost
    .align 6
    .global tohost
tohost: 
    .dword 0

.section .data
variable: 
    testvar:    .word   0xdeadbeef
