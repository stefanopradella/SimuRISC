.global _start
.section .text.init

_start:
    j csrrw_test

exit:
    la x8, tohost
    li x2, 1
    sw x2, 0(x8)

error:
    li x1, 0xDEAD

csrrw_test:
    li x3, 0x120
    csrrw x4, mtvec, x3
    csrr x5, mtvec
    bne x5, x3, error
    j csrrs_test

csrrs_test:
    li x3, 0x8
    csrrw x0, mtvec, x0
    csrrs x4, mtvec, x3
    csrr x5, mtvec
    bne x5, x3, error
    j csrrc_test

csrrc_test:
    li x3, 0x123
    csrrw x4, mtvec, x3
    li x4, 0x3
    csrrc x5, mtvec, x4
    csrr x6, mtvec
    not x8, x4
    and x7, x3, x8
    bne x6, x7, error
    j csrrwi_test

csrrwi_test:
    li x3, 0x10
    csrrwi x4, mtvec, 0x10
    csrr x5, mtvec
    li x6, 0x10
    bne x5, x6, error
    j csrrsi_test

csrrsi_test:
    csrrw x0, mtvec, x0
    csrrsi x4, mtvec, 0xC
    csrr x5, mtvec
    li x6, 0xC
    bne x5, x6, error
    j csrrci_test

csrrci_test:
    csrrw x0, mtvec, x0
    csrrwi x0, mtvec, 0xF
    csrrci x5, mtvec, 0x3
    csrr x6, mtvec
    li x3, 0xF
    li x4, 0x3
    not x8, x4
    and x7, x3, x8
    bne x6, x7, error
    j exit

.section .tohost
    .align 6
    .global tohost
tohost:
    .dword 0
