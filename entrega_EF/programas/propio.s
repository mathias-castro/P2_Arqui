# Programa propio de la entrega final.
# 1) Llena un arreglo de 16 numeros en las direcciones 0 a 60: A[i] = (3 + 5(i+1)) mod 16.
# 2) Recorre el arreglo: suma todos los numeros, cuenta los menores que 8 y suma los
#    que son 8 o mas.
# 3) Guarda los resultados: Mem[100] = suma total, Mem[104] = cuantos son menores
#    que 8 y Mem[108] = suma de los mayores o iguales a 8.
        addi x1, x0, 0        # direccion del elemento i
        addi x2, x0, 64       # direccion final (16 palabras)
        addi x3, x0, 3        # v = 3
gen:    addi x3, x3, 5        # v = v + 5
        andi x4, x3, 15       # A[i] = v mod 16
        sw   x4, 0(x1)        # guarda A[i]
        addi x1, x1, 4        # siguiente elemento
        beq  x1, x2, sigue    # termino de llenar
        jal  x0, gen          # vuelve a gen
sigue:  addi x1, x0, 0        # direccion del elemento i
        addi x5, x0, 0        # suma total
        addi x6, x0, 0        # cuantos son menores que 8
        addi x7, x0, 0        # suma de los mayores o iguales a 8
rec:    lw   x8, 0(x1)        # x8 = A[i]
        addi x1, x1, 4        # siguiente elemento
        add  x5, x5, x8       # suma total
        slti x9, x8, 8        # x9 = 1 si A[i] < 8
        beq  x9, x0, grande   # A[i] >= 8
        addi x6, x6, 1        # uno menor que 8 mas
        jal  x0, prox
grande: add  x7, x7, x8       # suma de los mayores o iguales a 8
prox:   beq  x1, x2, listo    # termino de recorrer
        jal  x0, rec          # vuelve a rec
listo:  sw   x5, 100(x0)      # Mem[100] = 120
        sw   x6, 104(x0)      # Mem[104] = 8
        sw   x7, 108(x0)      # Mem[108] = 92
fin:    beq  x0, x0, fin      # fin del programa
