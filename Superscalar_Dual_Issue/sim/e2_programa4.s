# E2 - Programa 4: branches en primera y segunda posicion y flushing.
    addi x1, x0, 1       # x1 = 1
    addi x2, x0, 2       # x2 = 2
    beq  x1, x2, trampa  # slot 0, no se toma
    addi x3, x0, 3       # slot 1, se ejecuta: x3 = 3
    beq  x1, x1, salto1  # slot 0, se toma
    addi x4, x0, 99      # slot 1 del mismo par: se anula en EX
    addi x4, x0, 98      # se anula en Decode
    addi x4, x0, 97      # se anula en Decode
salto1:
    addi x5, x0, 5       # slot 0 del par: se conserva, x5 = 5
    beq  x0, x0, salto2  # slot 1, se toma
    addi x6, x0, 99      # se anula
    addi x6, x0, 99      # se anula
salto2:
    jal  x7, salto3      # slot 0: x7 = 52 y se anula la via 1
    addi x8, x0, 99      # se anula en EX
trampa:
    addi x8, x0, 98      # no debe ejecutarse
    addi x8, x0, 97
salto3:
    addi x9, x7, 0       # x9 = 52
    jal  x14, sigue      # slot 1: x14 = 72; el slot 0 se conserva
    addi x15, x0, 99     # se anula
sigue:
    addi x10, x0, 3      # contador del bucle
    addi x11, x0, 0      # x11 = 0
bucle:
    addi x10, x10, -1
    addi x11, x11, 2     # x11 = 6 al terminar
    beq  x10, x0, salida
    beq  x0, x0, bucle   # dos saltos en el mismo par: se emiten por separado
salida:
    sw   x11, 252(x0)    # senal de fin
fin:
    beq  x0, x0, fin
