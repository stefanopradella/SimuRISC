.global _start
.section .text.init

_start:
    li x1, 10000            # assembled as lui + addi
    li x2, 1                # equivalent to addi x2, x0, 1
    and x3, x2, x1
    or x4, x2, x1
    add x5, x2, x1
    sub x6, x2, x1

    li x7, 1
    li x8, 2

branch_loop:
    addi x7, x7, 1
    beq x7, x8, branch_loop

    lw x9, testvar          # assembled as auipc + lw
    
    la x8, tohost           # assembled as auipc + addi
    li x2, 1
    sw x2, 0(x8)

.section .tohost
    .align 6
    .global tohost
tohost: 
    .dword 0

.section .data
variable: 
    testvar:    .word   0xdeadbeef
