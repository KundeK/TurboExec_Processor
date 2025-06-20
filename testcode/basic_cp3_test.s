.section .text
.globl _start
_start:
    addi x1, x0, 4
    addi x3, x1, 1
    addi x3, x1, 2
    addi x3, x1, 3
    addi x3, x1, 4
    bge  x3, x0, BRANCH
    addi x3, x1, 5
    blt  x0, x3, BRANCHTWO
    addi x3, x1, 6
BRANCH:
    addi x3, x1, 7
    addi x3, x1, 8
    addi x3, x1, 9
BRANCHTWO:
    addi x3, x1, 10
    addi x3, x1, 11
    auipc x4, 0
    sh x3, 218(x4)
    lb x5, 218(x4)
    sb x5, 224(x4)
    addi x5, x5, -63

    slti x0, x0, -256 # this is the magic instruction to end the simulation
    nop               # preventing fetching illegal instructions
    nop
    nop
    nop
    nop

li x1, 10
li x2, 20
li x3, 256
auipc x7, 0

sw x2, 256(x7)

add x4, x2, x3

lw x5, 248(x7)

add x6, x5, x4

slti x0, x0, -256