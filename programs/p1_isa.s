# ISA sin dependencias RAW que necesiten forwarding o stalls.
# beq no tomado y jal comprueban tambien las instrucciones de control.
.option norvc
.text
addi x1, x0, 12
addi x2, x0, 5
addi x3, x0, -3
nop
nop
add  x4, x1, x2       # 17
sub  x5, x1, x2       # 7
and  x6, x1, x2       # 4
or   x7, x1, x2       # 13
slt  x8, x3, x2       # 1, comparacion con signo
slti x9, x3, 0        # 1
andi x10, x1, 7       # 4
ori  x11, x2, 8       # 13
addi x12, x3, -1      # -4
sw   x1, 0(x0)        # Mem[0] = 12
lw   x13, 0(x0)       # x13 = 12
beq  x1, x2, fallo    # no tomado
jal  x14, destino     # x14 = 72
nop
nop
destino:
addi x15, x0, 1
nop
nop
sw   x15, 252(x0)     # fin del test
nop
nop
fallo:
nop
