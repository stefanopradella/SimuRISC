.global _boot
.text

_boot:
    li x1, 1
    li x2, 10

li x3, 2
li x4, 2
li x5, 3
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
    bgeu x6, x5, exit
    beq x4, x3, error

exit:
    la x8, tohost
    li x2, 1
    sw x2, 0(x8)

error:
    li x1, 0xFFFF

.data
variable: 
    tohost:     .dword  0
    testvar:    .word   0xdeadbeef
