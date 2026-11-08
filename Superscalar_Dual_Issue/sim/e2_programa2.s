# E2 - Programa 2: RAW entre candidatas y forwarding entre vias y etapas.
    addi x1, x0, 5       # x1 = 5
    addi x2, x1, 3       # RAW con el slot 0: se emite sola en el ciclo siguiente; x2 = 8
    addi x3, x0, 7       # x3 = 7; se reagrupa con addi x2
    add  x4, x2, x3      # x2 desde MEM via 0 y x3 desde MEM via 1; x4 = 15
    addi x5, x0, 1       # x5 = 1
    addi x13, x0, 3      # x13 = 3
    add  x6, x3, x0      # x3 desde WB via 1; x6 = 7
    add  x7, x4, x5      # x4 desde WB via 0 y x5 desde WB via 1; x7 = 16
    addi x14, x0, 6      # x14 = 6; alinea el par siguiente
    addi x9, x0, 1       # las dos vias escriben x9 en el mismo ciclo
    addi x9, x0, 9       # gana la via 1: x9 = 9
    add  x10, x9, x9     # x9 en MEM via 0 y MEM via 1: se usa la via 1; x10 = 18
    addi x12, x0, 4      # x12 = 4
    sw   x10, 252(x0)    # dato desde MEM via 0; senal de fin
fin:
    beq  x0, x0, fin
