# E1 - Programa 1: instrucciones soportadas, sin dependencias que necesiten la Hazard Unit.
# Los nop separan cada escritura de las lecturas del mismo registro.
        addi x1, x0, 12       # x1 = 12
        addi x2, x0, 5        # x2 = 5
        addi x3, x0, -3       # x3 = -3
        nop
        nop
        add  x4, x1, x2       # x4 = 17
        sub  x5, x1, x2       # x5 = 7
        and  x6, x1, x2       # x6 = 4
        or   x7, x1, x2       # x7 = 13
        slt  x8, x3, x2       # x8 = 1   (-3 < 5)
        slti x9, x3, 0        # x9 = 1   (-3 < 0)
        andi x10, x1, 6       # x10 = 4
        ori  x11, x2, 8       # x11 = 13
        sw   x1, 40(x0)       # Mem[40] = 12
        lw   x13, 40(x0)      # x13 = 12
        beq  x1, x2, fin      # no se toma (12 != 5)
        jal  x12, sigue       # salta, x12 = 68
        nop
        nop
sigue:  sw   x4, 100(x0)      # Mem[100] = 17
fin:    beq  x0, x0, fin      # fin del programa
