.global _start
.section .text.init

_start:
    li x2, 4
    li x3, 2
    li x4, 2
    
    jal_test:
        jal x1, jalr_test
        beq x4, x3, error
    
    jalr_test:
        la x2, jalr_test_align
        jalr x1, x2, 4
        beq x4, x3, error
    
    jalr_test_align:
        beq x4, x3, error
        la x2, jump_to_exit
        jalr x1, x2, 5
        beq x4, x3, error
    
    jump_to_exit:
        beq x4, x3, error
        beq x4, x3, bgeu_test
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

.section .tohost
    .align 6
    .global tohost
tohost: 
    .dword 0

.section .data
variable: 
    testvar:    .word   0xdeadbeef
