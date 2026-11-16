# E2 - Programa 4: saltos en la primera y en la segunda posición del par.
# x9 cuenta las instrucciones que no debían ejecutarse; al final tiene que seguir en 0.
        addi x1, x0, 5        # x1 = 5
        addi x9, x0, 0        # x9 = 0
        beq  x1, x1, L1       # primera del par, se toma
        addi x9, x9, 1        # su pareja es más joven: se anula
        addi x9, x9, 1        # se anula
        addi x9, x9, 1        # se anula
L1:     sw   x1, 40(x0)       # Mem[40] = 5
        beq  x1, x0, L2       # segunda del par, no se toma (5 != 0)
        lw   x2, 40(x0)       # x2 = 5   es más antigua que el salto: se conserva
        beq  x1, x1, L2       # segunda del par, se toma
        add  x9, x9, x2       # se anula (además depende del lw: Load-Use y salto a la vez)
        addi x9, x9, 1        # se anula
L2:     beq  x1, x0, L3       # primera del par, no se toma
        jal  x3, L3           # dos saltos en el par: no salen juntos.  x3 = 56
        addi x9, x9, 1        # pareja del jal: se anula
L3:     addi x4, x0, 2        # x4 = 2   se conserva
        jal  x5, L4           # segunda del par, x5 = 68
        addi x9, x9, 1        # se anula
L4:     add  x6, x2, x4       # x6 = 7
        add  x7, x3, x5       # x7 = 124
        sw   x9, 100(x0)      # Mem[100] = 0
fin:    beq  x0, x0, fin      # fin del programa
