# E1 - Programa 3: dependencias Load-Use, que necesitan un stall.
        addi x1, x0, 21       # x1 = 21
        sw   x1, 40(x0)       # Mem[40] = 21
        lw   x2, 40(x0)       # x2 = 21
        add  x3, x2, x1       # x3 = 42   usa x2 justo después del lw: stall
        sw   x3, 44(x0)       # Mem[44] = 42
        lw   x4, 44(x0)       # x4 = 42
        sw   x4, 100(x0)      # Mem[100] = 42   el dato del sw viene del lw: stall
fin:    beq  x0, x0, fin      # fin del programa
