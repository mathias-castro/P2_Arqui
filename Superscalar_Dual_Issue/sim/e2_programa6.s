# E2 - Programa 6: reagrupamiento despues de emision parcial,
# orden del programa y ausencia de instrucciones perdidas o duplicadas.
# Si una suma se perdiera o se repitiera, x1 o x2 tendrian otro valor.
    addi x1, x0, 1       # x1 = 1
    addi x1, x1, 1       # RAW: emision parcial
    addi x2, x0, 10
    addi x1, x1, 1
    addi x2, x2, 10
    addi x1, x1, 1
    addi x2, x2, 10
    addi x1, x1, 1
    addi x1, x1, 1       # RAW: emision parcial; x1 = 6
    addi x2, x2, 10      # x2 = 40
    add  x3, x1, x2      # x3 = 46
    sw   x3, 0(x0)       # Mem[0] = 46
    lw   x4, 0(x0)       # x4 = 46
    addi x4, x4, 1       # RAW y Load-Use: x4 = 47
    sw   x4, 252(x0)     # senal de fin
fin:
    beq  x0, x0, fin
