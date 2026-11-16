# E1 - Programa 2: dependencias que se resuelven con forwarding.
        addi x1, x0, 5        # x1 = 5
        addi x2, x1, 3        # x2 = 8    x1 viene de Memory
        add  x3, x1, x2       # x3 = 13   x1 viene de Writeback y x2 de Memory
        sub  x4, x3, x1       # x4 = 8    x3 viene de Memory
        addi x5, x0, 1        # x5 = 1
        addi x5, x5, 1        # x5 = 2
        add  x6, x5, x5       # x6 = 4    x5 está en Memory (2) y en Writeback (1): se usa Memory
        sw   x6, 100(x0)      # Mem[100] = 4   el dato del sw viene de Memory
fin:    beq  x0, x0, fin      # fin del programa
