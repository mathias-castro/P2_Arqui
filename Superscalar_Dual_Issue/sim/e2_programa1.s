# E2 - Programa 1: dos operaciones ALU independientes emitidas juntas.
# Ningun par tiene dependencia interna, asi que cada ciclo se emiten dos.
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 20      # x2 = 20
    addi x3, x0, 30      # x3 = 30
    addi x4, x0, 40      # x4 = 40
    and  x5, x1, x2      # x5 = 0
    or   x6, x3, x4      # x6 = 62
    add  x7, x1, x3      # x7 = 40
    sub  x8, x4, x2      # x8 = 20
    slt  x9, x1, x2      # x9 = 1
    slti x10, x4, 5      # x10 = 0
    andi x11, x3, 12     # x11 = 12
    ori  x12, x1, 5      # x12 = 15
    add  x13, x5, x6     # x13 = 62
    sub  x14, x7, x8     # x14 = 20
    sw   x13, 252(x0)    # senal de fin
fin:
    beq  x0, x0, fin
