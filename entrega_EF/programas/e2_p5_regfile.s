# E2 - Programa 5: dos escrituras por ciclo en el Register File.
        addi x1, x0, 11       # x1 = 11
        addi x2, x0, 22       # x2 = 22   se escribe en el mismo ciclo que x1
        addi x3, x0, 5        # x3 = 5
        addi x3, x0, 9        # x3 = 9    las dos escriben x3 a la vez: queda la segunda
        addi x0, x0, 7        # el destino es x0: se sigue leyendo 0
        addi x4, x0, 4        # x4 = 4
        sw   x2, 40(x0)       # Mem[40] = 22
        add  x5, x1, x3       # x5 = 20   x3 está en Writeback en las dos vías: se usa la vía 1
        lw   x6, 40(x0)       # x6 = 22   dato que viene de memoria
        add  x7, x3, x4       # x7 = 13   se escribe en el mismo ciclo que x6
        add  x8, x5, x0       # x8 = 20   (x0 sigue en 0)
        add  x9, x4, x2       # x9 = 26
        add  x10, x8, x6      # x10 = 42
        add  x11, x9, x7      # x11 = 39
        sw   x10, 100(x0)     # Mem[100] = 42
fin:    beq  x0, x0, fin      # fin del programa
