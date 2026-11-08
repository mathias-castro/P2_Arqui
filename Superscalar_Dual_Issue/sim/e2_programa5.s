# E2 - Programa 5: dos escrituras en el Register File en el mismo ciclo.
    addi x1, x0, 1       # dos escrituras: x1 = 1
    addi x2, x0, 2       # x2 = 2
    addi x3, x0, 3       # las dos vias escriben x3
    addi x3, x0, 4       # gana la via 1: x3 = 4
    addi x0, x0, 5       # x0 no cambia
    addi x4, x0, 6       # x4 = 6
    sw   x2, 0(x0)       # Mem[0] = 2
    add  x5, x1, x2      # x5 = 3
    add  x6, x3, x4      # ALU en la via 0: x6 = 10
    lw   x7, 0(x0)       # lw en la via 1: x7 = 2
    lw   x8, 0(x0)       # lw en la via 0: x8 = 2
    add  x9, x6, x5      # ALU en la via 1: x9 = 13
    add  x10, x7, x8     # x10 = 4
    sw   x10, 252(x0)    # senal de fin
fin:
    beq  x0, x0, fin
