# E1 - Programa 4: saltos y flushing.
# x9 cuenta las instrucciones que no debían ejecutarse; al final tiene que seguir en 0.
        addi x1, x0, 5        # x1 = 5
        addi x9, x0, 0        # x9 = 0
        beq  x1, x1, L1       # se toma
        addi x9, x9, 1        # se anula
        addi x9, x9, 1        # se anula
L1:     beq  x1, x0, L2       # no se toma (5 != 0)
        addi x2, x0, 7        # x2 = 7
L2:     jal  x3, L3           # salta, x3 = 32
        addi x9, x9, 1        # se anula
        addi x9, x9, 1        # se anula
L3:     add  x4, x2, x9       # x4 = 7 + 0 = 7
        sw   x4, 100(x0)      # Mem[100] = 7
fin:    beq  x0, x0, fin      # fin del programa
