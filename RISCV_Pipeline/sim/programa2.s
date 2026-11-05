    addi x1, x0, 5  # x1 = 5
    addi x2, x0, 7  # x2 = 7
    add  x3, x1, x2  # x3 = 12, ForwardAE = 01 y ForwardBE = 10
    sub  x4, x3, x1  # x4 = 7, ForwardAE = 10
    add  x5, x4, x3  # x5 = 19, ForwardAE = 10 y ForwardBE = 01
    addi x6, x0, 1  # x6 = 1
    addi x6, x0, 9  # x6 = 9
    add  x7, x6, x6  # x7 = 18, MEM tiene prioridad sobre WB
    sw   x7, 4(x0)  # Mem[4] = 18, ForwardBE = 10
    addi x0, x0, 99  # intenta escribir en x0
    add  x8, x0, x0  # x8 = 0, x0 no se reenvia
    addi x9, x0, 2  # x9 = 2
    sw   x9, 252(x0)  # senal de fin, ForwardBE = 10
    nop  # evita activar el bucle final
    nop  # evita activar el bucle final
fin:
    beq  x0, x0, fin  # bucle final
