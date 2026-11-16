# EF - Prueba 1: un bucle de 10 vueltas cerrado con un salto hacia atras.
# El beq se toma 9 veces y la ultima no. Sirve para ver como aprende el predictor:
# la primera vez no lo conoce, despues acierta, y en la ultima vuelta se equivoca.
        addi x1, x0, 0        # i = 0
        addi x2, x0, 0        # suma = 0
        addi x9, x0, 1        # constante 1
bucle:  addi x1, x1, 1        # i = i + 1
        add  x2, x2, x1       # suma = suma + i
        slti x3, x1, 10       # x3 = 1 mientras i < 10
        beq  x3, x9, bucle    # vuelve mientras i < 10
        sw   x2, 100(x0)      # Mem[100] = 1 + 2 + ... + 10 = 55
fin:    beq  x0, x0, fin      # fin del programa
