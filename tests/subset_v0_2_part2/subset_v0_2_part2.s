.global _boot
.text

_boot:
    la x1, testvar
    lw x2, 0(x1)
    li x1, 0xabcd
    
    slli x3, x2, 3
    srli x4, x2, 3
    srai x5, x2, 3

    xor x6, x1, x2
    xori x7, x2, 0xef
    ori x8, x2, 0xef
    andi x9, x2, 0xef

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

.data
variable: 
    tohost:     .dword  0
    testvar:    .word   0xdeadbeef
    dest:       .word   0x0
