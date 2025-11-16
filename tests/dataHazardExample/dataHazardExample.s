# Patterson, Hennessy - Computer Organization and Design RISC-V edition

.global _start
.section .text.init

_start:
    li x1, 0xabcd
    li x3, 0xaaaa
    
    # Hazard example at page 570 

    sub x2, x1, x3
    and x12, x2, x5
    or x13, x6, x2
    add x14, x2, x2
    sw  x15, 100(x2)

    # Memory copy at page 580
    
    sw x2, 4(x0)
    lw x3, 4(x0)
    sw x3, 8(x0)

    # Pipeline stall

    lw x5, 4(x0)
    and x6, x5, x1

    # Branch hazard
    bne x1, x3, exit
    li x1, 0
    li x2, 0
    li x3, 0

exit:
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