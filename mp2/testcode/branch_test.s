branch_test.s:
.align 4
.section .text
.globl _start

_start:
    lw x1, one
    lw x2, two
    beq x0, x0, halt
    blt x1, x2, working

not_working:
    lw x3, not_nice

halt:
    lw x4, sexy
    beq x0, x0, halt

working:
    lw x3, nice
    beq x0, x0, halt


one:         .word 0x00000001
two:         .word 0x00000011
nice:        .word 0xdeadbeef
not_nice:    .word 0xf69f69f6
sexy:        .word 0x11110000

