# E2 - Programa 6: reagrupamiento después de una emisión parcial.
# x1 cuenta de 1 en 1 y x2 de 10 en 10. Si una instrucción se perdiera
# o se repitiera, el resultado final sería otro.
        addi x1, x0, 1        # x1 = 1
        addi x2, x0, 10       # x2 = 10
        addi x1, x1, 1        # x1 = 2
        addi x1, x1, 1        # x1 = 3    depende de la anterior: se queda y se reagrupa
        addi x2, x2, 10       # x2 = 20
        addi x2, x2, 10       # x2 = 30
        addi x1, x1, 1        # x1 = 4
        addi x1, x1, 1        # x1 = 5
        addi x1, x1, 1        # x1 = 6
        addi x1, x1, 1        # x1 = 7
        add  x3, x1, x2       # x3 = 37
        sw   x3, 100(x0)      # Mem[100] = 37
fin:    beq  x0, x0, fin      # fin del programa
