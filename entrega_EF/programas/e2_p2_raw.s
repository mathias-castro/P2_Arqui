# E2 - Programa 2: RAW dentro del par y forwarding entre vías y etapas.
        addi x1, x0, 5        # x1 = 5
        addi x2, x1, 3        # x2 = 8    lee x1, que escribe la anterior: no salen juntas
        addi x3, x0, 7        # x3 = 7
        add  x4, x2, x3       # x4 = 15   x2 desde Memory vía 0, x3 desde Memory vía 1
        add  x5, x1, x3       # x5 = 12   x1 desde Writeback vía 0, x3 desde Memory vía 1
        sub  x6, x4, x2       # x6 = 7    x4 desde Memory vía 0, x2 desde Writeback vía 0
        or   x7, x5, x3       # x7 = 15   x5 desde Memory vía 1, x3 desde Writeback vía 1
        addi x8, x0, 1        # x8 = 1
        addi x8, x0, 2        # x8 = 2    mismo destino que la anterior
        add  x9, x8, x8       # x9 = 4    x8 está en Memory en las dos vías: se usa la vía 1
        add  x10, x6, x7      # x10 = 22  x6 desde Writeback vía 0, x7 desde Writeback vía 1
        add  x11, x9, x10     # x11 = 26
        sw   x11, 100(x0)     # Mem[100] = 26   lee x11, que escribe la anterior: no salen juntas
fin:    beq  x0, x0, fin      # fin del programa
