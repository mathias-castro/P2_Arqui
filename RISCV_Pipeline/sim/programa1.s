    addi x1, x0, 12  # x1 = 12
    addi x2, x0, 5  # x2 = 5
    addi x3, x0, -3  # x3 = -3
    nop  # separa las escrituras de las lecturas
    nop
    add  x4, x1, x2  # x4 = 17
    sub  x5, x1, x2  # x5 = 7
    and  x6, x1, x2  # x6 = 4
    or   x7, x1, x2  # x7 = 13
    slt  x8, x3, x2  # -3 < 5, x8 = 1
    slti x9, x3, 0  # -3 < 0, x9 = 1
    andi x10, x1, 7  # x10 = 4
    ori  x11, x2, 8  # x11 = 13
    addi x12, x3, -1  # x12 = -4
    sw   x1, 0(x0)  # Mem[0] = 12
    lw   x13, 0(x0)  # x13 = 12
    beq  x1, x2, fin  # 12 != 5, no salta
    jal  x14, destino  # x14 = 72
    nop  # espacio del salto: no cambia el resultado
    nop  # espacio del salto: no cambia el resultado
destino:
    addi x15, x0, 1  # x15 = 1
    nop  # separa la escritura de la lectura
    nop
    sw   x15, 252(x0)  # senal de fin
    nop  # evita activar el bucle final
    nop  # evita activar el bucle final
fin:
    beq  x0, x0, fin  # bucle final
