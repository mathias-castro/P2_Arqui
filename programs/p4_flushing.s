# Branches tomados/no tomados, jal, offset negativo y efectos anulados.
.option norvc
.text
addi x1, x0, 1
addi x2, x0, 2
addi x10, x0, 0
beq  x1, x2, incorrecto   # no tomado
addi x3, x0, 7
beq  x3, x3, tomado       # tomado, operandos desde MEM
sw   x2, 16(x0)           # se anula
addi x10, x0, 99          # se anula
tomado:
jal  x5, destino          # x5 = 36
sw   x2, 20(x0)           # se anula
addi x10, x0, 88          # se anula
destino:
addi x6, x5, 4            # x6 = 40
addi x7, x0, 2
bucle:
addi x7, x7, -1
beq  x7, x0, fin          # no tomado, luego tomado
jal  x0, bucle            # offset negativo
incorrecto:
sw   x2, 24(x0)           # se anula
addi x10, x0, 77          # se anula
fin:
sw   x6, 12(x0)
addi x15, x0, 4
sw   x15, 252(x0)
