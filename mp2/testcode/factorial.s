factorial.s:
.align 4
.section .text
.globl factorial


# x1 = n  && x1 will hold the final result
# x2 = n-1 && multiply counter
# x3 = result of n * n - 1 multiply && running total
# x4 = factorial counter

factorial:
    and x2, x2, 0           # clear 
    and x3, x3, 0           # clear 
    and x4, x4, 0           # clear 
    and x5, x5, 0           # clear 
    and x6, x6, 0           # clear

    lw x1, integer_n        # load value n
    lw x2, integer_n        # 
    add x2, x2, -1          # load n - 1
    add x4, x2, -1          # there are n - 2 total multiples for a factorial (not counting n*1)
    beq x0, x0, multiply    # call first multiply

multiply_return:
    and x1, x1, 0           # clear x1
    and x2, x2, 0           # clear x2
    add x1, x1, x3          # load total result into x1
    add x2, x2, x4          # load (n-1)-1 into x2

    beq x4, x0, done        # done if counter == 0
    beq x0, x0, multiply    # multiply n * n-1


done:
    and x1, x1, 0   
    add x1, x1, x3          # move final result into x1
    lw x2, integer_n        # the factorial value you're calculating   
           
    lw x3, finished         # dummy value so I know it's done
    lw x4, finished
    lw x5, finished
    lw x6, finished
loop:
    beq x0, x0, loop        # infinite loop


# multiply x3 = x1 * x2
multiply:
        add x3, x3, x1                  # x3 += x1                   
        add x2, x2, -1                  # decrememnt multiply counter
        bne x2, x0, multiply            # keep multipling if x2 > 1
        add x4, x4, -1                  # decrement factorial counter
        beq x0, x0, multiply_return     # done multiply, jump back to factorial 

    

.section .rodata
# if you need any constants
integer_n:    .word 0x0000000a
finished:     .word 0xdeadbeef



