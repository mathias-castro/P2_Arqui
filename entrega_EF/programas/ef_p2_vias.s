# EF - Prueba 2: saltos predichos en las dos vias y camino equivocado.
# Los dos bucles se cierran con un jal, que siempre se toma. En el primero el jal
# queda en la via 0 y en el segundo en la via 1. Despues de cada jal hay una
# instruccion que suma 1 a x9 y que no debe ejecutarse; al final x9 tiene que seguir en 0.
        addi x1, x0, 0        # i = 0
        addi x2, x0, 4        # vueltas
        addi x5, x0, 0        # x5 = 0
        addi x7, x0, 0        # x7 = 0
        addi x9, x0, 0        # x9 = 0
L1:     addi x1, x1, 1        # i = i + 1
        beq  x1, x2, sale1    # sale en la cuarta vuelta
        addi x5, x5, 2        # x5 = x5 + 2
        jal  x0, L1           # vuelve al inicio (via 0)
        addi x9, x9, 1        # no debe ejecutarse
sale1:  addi x1, x0, 0        # i = 0
L2:     beq  x1, x2, sale2    # sale cuando i = 4
        addi x1, x1, 1        # i = i + 1
        addi x7, x7, 3        # x7 = x7 + 3
        jal  x0, L2           # vuelve al inicio (via 1)
        addi x9, x9, 1        # no debe ejecutarse
sale2:  add  x6, x5, x7       # x6 = 6 + 12 = 18
        add  x6, x6, x9       # x6 = 18 + x9
        sw   x6, 100(x0)      # Mem[100] = 18
fin:    beq  x0, x0, fin      # fin del programa
