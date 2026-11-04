# Resultados de MEM y WB, prioridad MEM, dato de sw y proteccion de x0.
.option norvc
.text
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2       # 12: A desde WB y B desde MEM
sub  x4, x3, x1       # 7: A desde MEM
add  x5, x3, x4       # 19: A desde WB y B desde MEM
addi x6, x0, 1
addi x6, x0, 9
add  x7, x6, x6       # 18: ambos deben usar el 9 de MEM
sw   x7, 4(x0)        # dato del store desde MEM
addi x0, x0, 99       # se descarta
add  x8, x0, x0       # debe seguir dando 0
addi x15, x0, 2
sw   x15, 252(x0)
