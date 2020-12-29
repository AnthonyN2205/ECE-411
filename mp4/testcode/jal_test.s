.align 4
.section .text
.globl _start

_start:
    lw x5, DEAD             # x5 = 0xDEADBEEF
    lw x10, STUFF           # x10 = 0xECEBECEB for comparison
    addi x1, x1, 5          # random stuff
    addi x2, x2, 6          # random stuff
    add x3, x2, x1          # hazard
    jal x7, MATH            # jump to MATH
    addi x11, x6, 0         # mv x6 -> x11. Returning into a hazard after jalr
    beq x6, x10, HALT
    jal x7, DEADEND         # fetched during line 12 BUT should be squashed and not jump

MATH:
    lw x6, STUFF            # x6 = 0xECEBECEB to make sure it made it here
    addi x1, x1, 1          # increment x1
    jalr x0, x7, 0          # return to address stored in x7. [line 11 + 1]

HALT:
    beq x0, x0, HALT        # halt

DEADEND:                    # infinite loop to make sure it never is reached.
    add x4, x4, 1
    beq x0, x0, DEADEND




.section .rodata
.balign 256

DEAD:     .word   0xDEADBEEF
STUFF:   .word   0xECEBECEB

