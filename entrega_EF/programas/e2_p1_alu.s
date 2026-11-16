# E2 - Programa 1: dos operaciones ALU independientes en cada par.
        addi x1, x0, 12       # x1 = 12
        addi x2, x0, 5        # x2 = 5
        addi x3, x0, -3       # x3 = -3
        addi x4, x0, 9        # x4 = 9
        add  x5, x1, x2       # x5 = 17
        sub  x6, x1, x2       # x6 = 7
        and  x7, x3, x4       # x7 = 9
        or   x8, x3, x4       # x8 = -3
        slt  x9, x3, x1       # x9 = 1   (-3 < 12)
        slti x10, x4, 5       # x10 = 0  (9 < 5 es falso)
        add  x11, x5, x6      # x11 = 24
        sub  x12, x7, x9      # x12 = 8
        add  x13, x11, x12    # x13 = 32
        andi x14, x8, 15      # x14 = 13
        sw   x13, 100(x0)     # Mem[100] = 32
fin:    beq  x0, x0, fin      # fin del programa
