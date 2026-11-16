# E2 - Programa 3: Load-Use y conflictos por el único puerto de memoria de datos.
        addi x1, x0, 20       # x1 = 20
        addi x2, x0, 7        # x2 = 7
        sw   x1, 40(x0)       # Mem[40] = 20
        sw   x2, 44(x0)       # Mem[44] = 7    dos sw en el par: no salen juntos
        lw   x3, 40(x0)       # x3 = 20        sw y lw en el par: no salen juntos
        add  x4, x3, x2       # x4 = 27        Load-Use: no sale ninguna hasta que el lw pasa a Memory
        lw   x5, 44(x0)       # x5 = 7         sale junto con el add (ALU + lw)
        addi x6, x0, 1        # x6 = 1         sale sola: su pareja depende del lw x5
        add  x7, x5, x2       # x7 = 14        Load-Use en la segunda posición del par
        sw   x4, 48(x0)       # Mem[48] = 27   sale junto con el add (ALU + sw)
        lw   x8, 48(x0)       # x8 = 27        sale junto con el sub (lw + ALU)
        sub  x9, x7, x6       # x9 = 13
        sw   x9, 100(x0)      # Mem[100] = 13
fin:    beq  x0, x0, fin      # fin del programa
