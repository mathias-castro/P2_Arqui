# E2 - Programa 3: dependencias Load-Use y conflictos del puerto de memoria.
    addi x1, x0, 21      # x1 = 21
    addi x2, x0, 8       # x2 = 8
    sw   x1, 0(x2)       # Mem[8] = 21
    sw   x2, 4(x2)       # dos accesos a memoria: espera; Mem[12] = 8
    lw   x3, 0(x2)       # x3 = 21; otro conflicto con el sw anterior
    add  x4, x3, x1      # RAW con lw y luego Load-Use; x4 = 42
    addi x5, x0, 3       # ALU + lw en el mismo par
    lw   x6, 4(x2)       # lw en la via 0; x6 = 8
    add  x7, x6, x4      # Load-Use en el slot 0: un stall; x7 = 50
    addi x10, x0, 1      # x10 = 1
    lw   x9, 0(x2)       # lw + ALU en el mismo par; x9 = 21
    addi x11, x0, 2      # x11 = 2
    addi x12, x0, 7      # x12 = 7; el slot 0 es independiente y sale
    add  x13, x9, x1     # Load-Use solo en el slot 1: espera; x13 = 42
    sw   x13, 252(x0)    # senal de fin
fin:
    beq  x0, x0, fin
