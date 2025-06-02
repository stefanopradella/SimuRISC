# This test replicates the startup routine for the tests 
# included in the riscv-tests suite

.global _start
.section .text.init

_start:
    j reset_vector

trap_vector:
    csrr x30, mcause
    li x31, 0x8
    beq x30, x31, write_tohost
    li x31, 0x9
    beq x30, x31, write_tohost
    li x31, 0xb
    beq x30, x31, write_tohost
    li x30, 0
    beqz x30, 1f
    jr x30
1:
    csrr x30, mcause
    bgez x30, handle_exception
    j other_exception

handle_exception:
other_exception:
1:
    ori x28, x28, 1337

write_tohost:
    la x8, tohost
    li x2, 1
    sw x2, 0(x8)

reset_vector:
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x5, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    csrr x10, mhartid
1:
    bnez x10, 1b
    la x5, 1f
    csrw mtvec, x5
    csrwi mnstatus, 8
1:
    la x5, 1f
    csrw mtvec, x5
    # csrwi satp, 0
1:
    la x5, 1f
    csrw mtvec, x5
    li x5, 0x7fffffff
    csrw pmpaddr0, x5
    li x5, 31
    csrw pmpcfg0, x5
1:
    csrwi mie, 0
    la x5, 1f
    csrw mtvec, x5
    csrwi medeleg, 0
    csrwi mideleg, 0
1:
    li x28, 0
    la x5, trap_vector
    csrw mtvec, x5
    li x10, 1
    slli x10, x10, 31
    bltz x10, 1f
    fence
    li x28, 1
    li x17, 93
    li x10, 0
    ecall
1:
    li x5, 0
    beqz x5, 1f
    csrw stvec, x5
    li x5, 0xb109
    csrw medeleg, x5
1:
    csrwi mstatus, 0
    la x5, 1f
    csrw mepc, x5
    csrr x10, mhartid
    mret

1:
    j write_tohost

.section .tohost
    .align 6
    .global tohost
tohost:
    .dword 0
