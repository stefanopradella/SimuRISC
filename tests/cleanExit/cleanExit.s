.global _start
.section .text.init

_start:
    la x1, tohost
    li x2, 1
    sw x2, 0(x1)

.section .tohost
    .align 6
    .global tohost
tohost:
    .dword 0

                     