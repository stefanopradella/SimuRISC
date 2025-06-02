.global _start
.section .text.init

_start:
    la x1, testvar
    lw x2, 0(x1)
    li x1, 0xabcd
    
    slli x3, x2, 3
    srli x4, x2, 3
    srai x5, x2, 3

    xor x6, x1, x2
    xori x7, x2, 0xef
    ori x8, x2, 0xef
    andi x9, x2, 0xab
    slt x10, x2, x1;
    sltu x11, x1, x2;
    slti x12, x2, 0xef;
    sltiu x13, x9, 0xef;

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
