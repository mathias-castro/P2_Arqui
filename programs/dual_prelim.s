# Prueba de conexiones, no programa de un procesador Dual-Issue completo.
# El testbench precarga x1=12, x2=5, x3=4, x4=9; WB esta desconectado.
.option norvc
.text
add  x5, x1, x2       # ALU0 = 17
sub  x6, x1, x3       # ALU1 = 8
lw   x7, 8(x1)        # direccion = 20, sin lectura MEM todavia
and  x8, x2, x3       # ALU1 = 4
or   x9, x1, x2       # ALU0 = 13
sw   x4, 12(x3)       # direccion = 16, dato = 9; no se escribe MEM
beq  x1, x2, fin      # se decodifica; aun no redirige PC
addi x11, x1, -4      # ALU1 = 8
slt  x12, x2, x1      # ALU0 = 1
jal  x10, fin         # se decodifica; aun no escribe el link
fin:
addi x13, x0, 1
addi x14, x0, 2
