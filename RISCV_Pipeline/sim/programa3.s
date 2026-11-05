    addi x1, x0, 21  # x1 = 21
    sw   x1, 0(x0)  # Mem[0] = 21
    lw   x2, 0(x0)  # x2 = 21
    add  x3, x2, x1  # stall 1, x3 = 42
    sw   x3, 4(x0)  # Mem[4] = 42
    lw   x4, 4(x0)  # x4 = 42
    sw   x4, 8(x0)  # stall 2, Mem[8] = 42
    addi x9, x0, 3  # x9 = 3
    sw   x9, 252(x0)  # senal de fin
    nop  # evita activar el bucle final
    nop  # evita activar el bucle final
fin:
    beq  x0, x0, fin  # bucle final
