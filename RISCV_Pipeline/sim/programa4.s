    addi x1, x0, 5  # x1 = 5
    addi x2, x0, 5  # x2 = 5
    addi x3, x0, 3  # x3 = 3
    addi x4, x0, 0  # x4 debe quedar en 0
    addi x5, x0, 0  # x5 debe quedar en 0
    beq  x1, x2, salto1  # 5 = 5, salta
    sw   x1, 16(x0)  # trampa: se elimina
    addi x4, x0, 99  # trampa: se elimina
salto1:
    beq  x1, x3, salto2  # 5 != 3, no salta
    addi x6, x0, 10  # se ejecuta: x6 = 10
salto2:
    jal  x7, salto3  # salta y guarda x7 = 44
    sw   x1, 20(x0)  # trampa: se elimina
    addi x5, x0, 99  # trampa: se elimina
salto3:
    addi x8, x0, 4  # x8 = 4
    nop  # separa la escritura de la lectura
    nop
    sw   x8, 252(x0)  # senal de fin
    nop  # evita activar el bucle final
    nop  # evita activar el bucle final
fin:
    beq  x0, x0, fin  # bucle final
