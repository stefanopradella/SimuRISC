.global _boot
.text

_boot:
    la x1, tohost
    li x2, 1
    sw x2, 0(x1)

.data
variable:
    .align 6; .global tohost;   tohost:   .dword 0

                     