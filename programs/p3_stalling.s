# Load-Use hacia la ALU y hacia el dato de un store.
.option norvc
.text
addi x1, x0, 21
sw   x1, 0(x0)
lw   x2, 0(x0)
add  x3, x2, x2       # stall 1: ambos operandos
sw   x3, 4(x0)
lw   x4, 4(x0)
sw   x4, 8(x0)        # stall 2: dato del store
addi x15, x0, 3
sw   x15, 252(x0)
