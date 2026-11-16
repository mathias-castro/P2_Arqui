# Diagramas de pipeline de la seccion 7 (cada fila es una instruccion y cada columna un ciclo).
STYLE = """<style>
  text { font-family: 'Liberation Mono', 'DejaVu Sans Mono', monospace; font-size: 14px; fill: #111; }
  .cyc { font-family: Arial, 'Liberation Sans', sans-serif; font-size: 13px; fill: #5b6470; }
  .cell { fill: #fff; stroke: #5b6470; stroke-width: 1.2; }
  .st { font-family: Arial, 'Liberation Sans', sans-serif; font-size: 13px; font-weight: bold; }
  .cell.w { fill: #e3eefb; stroke: #1565c0; stroke-width: 2.5; }
  .cell.fw { fill: #fff0e0; stroke: #d9480f; stroke-width: 2.5; }
  .cell.bad { fill: #ffe3e3; stroke: #c92a2a; stroke-width: 2.5; }
  .cell.ok { fill: #e3f6e8; stroke: #2b8a3e; stroke-width: 2.5; }
  .cell.off { stroke-dasharray: 4 3; }
  .asm.off { fill: #5b6470; font-style: italic; }
  .halo { stroke: #fff; stroke-width: 7; }
  .ar { stroke-width: 2.5; fill: none; }
  .ar.fw { stroke: #d9480f; } .ah.fw { fill: #d9480f; }
  .ar.bad { stroke: #c92a2a; stroke-dasharray: 7 4; } .ah.bad { fill: #c92a2a; }
  .ar.ok { stroke: #2b8a3e; } .ah.ok { fill: #2b8a3e; }
  .ar.w { stroke: #1565c0; } .ah.w { fill: #1565c0; }
  .ar.off { stroke: #5b6470; stroke-dasharray: 4 4; } .ah.off { fill: #5b6470; }
  .nt { font-family: Arial, 'Liberation Sans', sans-serif; font-size: 14.5px; font-weight: bold; }
  .nt.w { fill: #1565c0; } .nt.fw { fill: #d9480f; } .nt.bad { fill: #c92a2a; } .nt.ok { fill: #2b8a3e; } .nt.off { fill: #5b6470; }
</style>"""
ETAPAS = "FDEMW"
COL, ROW, CW, CH = 58, 46, 48, 30     # ancho de columna, alto de fila, tamaño de celda
LBL, TOP = 190, 34                    # ancho de la columna de instrucciones, alto del encabezado


def diagrama(ident, insts, ciclos, marcas=None, flechas=None, notas=None, ancho_notas=230):
    """insts: lista de (texto, ciclo_de_fetch) o (texto, ciclo_de_fetch, secuencia), por ejemplo "FDDEMW"
    para un stall; "." deja la celda vacía.
    marcas: {(fila, etapa): clase}  clase en w (escribe/produce), bad, ok, fw, off
    flechas: [((fila, etapa, ancla), (fila, etapa, ancla), clase)]  ancla: t, b, l, r, c
    notas: {fila: (texto, clase)}"""
    marcas, flechas, notas = marcas or {}, flechas or [], notas or {}
    W = LBL + ciclos * COL + (ancho_notas if notas else 10)
    H = TOP + len(insts) * ROW + 6
    s = [f'<svg class="pd" viewBox="0 0 {W} {H}" role="img" aria-label="Diagrama de pipeline">',
         '<defs>']
    for c in ("fw", "bad", "ok", "off", "w"):
        s.append(f'<marker id="{ident}-{c}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
                 f'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="ah {c}"/></marker>')
    s.append('</defs>')
    for k in range(ciclos):
        x = LBL + k * COL + COL / 2
        s.append(f'<text class="cyc" x="{x}" y="20" text-anchor="middle">{k + 1}</text>')
    s.append(f'<text class="cyc" x="{LBL - 12}" y="20" text-anchor="end">ciclo</text>')

    def seq(fila):
        return insts[fila][2] if len(insts[fila]) > 2 else ETAPAS

    def idx(fila, e):
        # e puede ser la letra de la etapa (primera vez que aparece) o la posición en la secuencia
        return e if isinstance(e, int) else seq(fila).index(e)

    def celda(fila, e):
        c0 = insts[fila][1] + idx(fila, e)
        x = LBL + (c0 - 1) * COL + (COL - CW) / 2
        y = TOP + fila * ROW + (ROW - CH) / 2
        return x, y

    for i, ins in enumerate(insts):
        txt, c0 = ins[0], ins[1]
        y = TOP + i * ROW + ROW / 2
        cla = "asm off" if txt.startswith("(") else "asm"
        s.append(f'<text class="{cla}" x="8" y="{y + 5}">{txt}</text>')
        for k, e in enumerate(seq(i)):
            if e == "." or c0 + k > ciclos:
                continue
            x, yy = celda(i, k)
            cl = marcas.get((i, k), marcas.get((i, e), "") if seq(i).index(e) == k else "")
            s.append(f'<rect class="cell {cl}" x="{x}" y="{yy}" width="{CW}" height="{CH}" rx="4"/>')
            s.append(f'<text class="st {cl}" x="{x + CW / 2}" y="{yy + CH / 2 + 5}" text-anchor="middle">{e}</text>')

    def punto(fila, etapa, a):
        x, y = celda(fila, etapa)
        a, _, off = a.partition(":")
        x += float(off or 0)
        dx = {"l": 0, "r": CW, "t": CW / 2, "b": CW / 2, "c": CW / 2}[a]
        dy = {"l": CH / 2, "r": CH / 2, "t": 0, "b": CH, "c": CH / 2}[a]
        return x + dx, y + dy

    for (f1, e1, a1), (f2, e2, a2), cl in flechas:
        x1, y1 = punto(f1, e1, a1)
        x2, y2 = punto(f2, e2, a2)
        s.append(f'<line class="halo" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>')
        s.append(f'<line class="ar {cl}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" marker-end="url(#{ident}-{cl})"/>')

    for fila, (txt, cl) in notas.items():
        y = TOP + fila * ROW + ROW / 2 + 5
        s.append(f'<text class="nt {cl}" x="{LBL + ciclos * COL + 14}" y="{y}">{txt}</text>')
    s.append('</svg>')
    return "\n".join(s)




def guardar(nombre, svg):
    svg = svg.replace('<svg class="pd" ', '<svg xmlns="http://www.w3.org/2000/svg" ', 1)
    vb = svg.split('viewBox="')[1].split('"')[0].split()
    svg = svg.replace('role="img"', 'width="%s" height="%s"' % (vb[2], vb[3]), 1)
    svg = svg.replace('<defs>', STYLE + '<defs>', 1)
    open(nombre, 'w').write(svg)

# Sin prediccion: el beq que cierra el bucle se resuelve en Execute y se anula todo lo que entro detras
guardar('pred_sin.svg', diagrama("ps", [("beq  x3, x9, bucle", 1), ("sw   x2, 100(x0)", 1, "FDE"),
        ("(siguiente)", 2, "FD"), ("(siguiente)", 2, "FD"), ("(siguiente)", 3, "F"), ("(siguiente)", 3, "F"),
        ("bucle: addi x1, x1, 1", 4), ("add  x2, x2, x1", 4)], 8,
    marcas={(0, "E"): "w", (1, "E"): "bad off", (2, "F"): "bad off", (2, "D"): "bad off", (3, "F"): "bad off", (3, "D"): "bad off",
            (4, "F"): "bad off", (5, "F"): "bad off", (6, "F"): "ok", (7, "F"): "ok"},
    flechas=[((0, "E", "b:14"), (6, "F", "t"), "ok")],
    notas={0: ("en Execute se ve que salta", "w"), 1: ("su pareja: FlushM1", "bad"), 2: ("FlushE0", "bad"), 3: ("FlushE1", "bad"),
           4: ("FlushD", "bad"), 5: ("FlushD", "bad"), 6: ("el destino entra en el ciclo 4", "ok")}, ancho_notas=260))

# Con prediccion: el beq se predice tomado en Fetch y el destino entra en el ciclo siguiente
guardar('pred_con.svg', diagrama("pc", [("beq  x3, x9, bucle", 1), ("(burbuja)", 1),
        ("bucle: addi x1, x1, 1", 2), ("add  x2, x2, x1", 2)], 8,
    marcas={(0, "F"): "w", (1, "F"): "off", (1, "D"): "off", (1, "E"): "off", (1, "M"): "off", (1, "W"): "off", (2, "F"): "ok", (3, "F"): "ok"},
    flechas=[((0, "F", "b:-14"), (2, "F", "t:-14"), "ok")],
    notas={0: ("en Fetch se predice que salta", "w"), 1: ("en lugar del sw entra una burbuja", "off"),
           2: ("el destino entra en el ciclo 2", "ok")}, ancho_notas=260))

# Forwarding del resultado de un jal predicho
guardar('jal_fw.svg', diagrama("jf", [("jal  x1, L", 1), ("(burbuja)", 1), ("L: add x5, x5, x1", 2)], 7,
    marcas={(0, "F"): "w", (0, "M"): "fw", (1, "F"): "off", (1, "D"): "off", (1, "E"): "off", (1, "M"): "off", (1, "W"): "off", (2, "E"): "fw"},
    flechas=[((0, "M", "b:14"), (2, "E", "t:14"), "fw")],
    notas={0: ("en Memory, x1 = PC + 4 está en PCPlus4M", "fw"), 1: ("", ""), 2: ("lee x1 desde Memory", "fw")}, ancho_notas=330))

# Seccion 2.3: forwarding, stall y flush en el pipeline Single-Issue (programas 2, 3 y 4)
guardar('hz_forward.svg', diagrama("hf", [("addi x1, x0, 5", 1), ("addi x2, x1, 3", 2), ("add  x3, x1, x2", 3)], 7,
    marcas={(0, "M"): "fw", (0, "W"): "fw", (1, "M"): "fw", (1, "E"): "w", (2, "E"): "w"},
    flechas=[((0, "M", "b"), (1, "E", "t"), "fw"), ((0, "W", "b:-17"), (2, "E", "t:-17"), "fw"),
             ((1, "M", "b:15"), (2, "E", "t:15"), "fw")],
    notas={1: ("x1 desde Memory (ForwardAE = 10)", "fw"), 2: ("x1 desde Writeback (01), x2 desde Memory (10)", "fw")},
    ancho_notas=400))

guardar('hz_stall.svg', diagrama("hs", [("lw   x2, 40(x0)", 1), ("(burbuja)", 2, "..EMW"),
        ("add  x3, x2, x1", 2, "FDDEMW"), ("sw   x3, 44(x0)", 3, "FFDEMW")], 8,
    marcas={(0, "M"): "w", (1, 2): "off", (1, 3): "off", (1, 4): "off", (2, 2): "bad", (3, 1): "bad", (2, "E"): "fw", (0, "W"): "fw"},
    flechas=[((0, "W", "b:-16"), (2, 3, "t:-16"), "fw")],
    notas={0: ("el dato sale de la memoria en Memory", "w"), 1: ("FlushE: entra una burbuja", "off"),
           2: ("StallD: se queda en Decode; x2 por forwarding", "bad"), 3: ("StallF: se queda en Fetch", "bad")}, ancho_notas=420))

guardar('hz_flush.svg', diagrama("hl", [("beq  x1, x1, L1", 1), ("addi x9, x9, 1", 2, "FD"), ("addi x9, x9, 1", 3, "F"),
        ("L1: beq x1, x0, L2", 4)], 8,
    marcas={(0, "E"): "w", (1, "F"): "bad off", (1, "D"): "bad off", (2, "F"): "bad off", (3, "F"): "ok"},
    flechas=[((0, "E", "b:14"), (3, "F", "t"), "ok")],
    notas={0: ("en Execute se ve que salta: PCSrcE = 1", "w"), 1: ("FlushE la anula", "bad"), 2: ("FlushD la anula", "bad"),
           3: ("el destino entra en el ciclo 4", "ok")}, ancho_notas=330))

# Seccion 4: RAW dentro del par (programa 2 del Dual-Issue)
guardar('issue_raw.svg', diagrama("ir", [("addi x1, x0, 5", 1), ("addi x2, x1, 3", 1, "FDDEMW"),
        ("addi x3, x0, 7", 2, "FDEMW")], 7,
    marcas={(0, "M"): "fw", (1, 2): "bad", (1, "E"): "w", (2, "D"): "ok"},
    flechas=[((0, "M", "b:-14"), (1, 3, "t:-14"), "fw")],
    notas={0: ("vía 0: sale sola (Issue1 = 0)", "w"), 1: ("vía 1: lee x1, espera en Decode", "bad"),
           2: ("entra a su lado y salen juntas", "ok")}, ancho_notas=360))

# Seccion 5.3: salto tomado en la via 0 (programa 4 del Dual-Issue)
guardar('flush_dual.svg', diagrama("fd", [("beq  x1, x1, L1", 1), ("addi x9, x9, 1", 1, "FDE"),
        ("addi x9, x9, 1", 2, "FD"), ("addi x9, x9, 1", 2, "FD"), ("L1: sw x1, 40(x0)", 3, "F"), ("beq  x1, x0, L2", 3, "F"),
        ("L1: sw x1, 40(x0)", 4), ("beq  x1, x0, L2", 4)], 8,
    marcas={(0, "E"): "w", (1, "E"): "bad off", (2, "F"): "bad off", (2, "D"): "bad off", (3, "F"): "bad off", (3, "D"): "bad off",
            (4, "F"): "bad off", (5, "F"): "bad off", (6, "F"): "ok", (7, "F"): "ok"},
    flechas=[((0, "E", "b:14"), (6, "F", "t"), "ok")],
    notas={0: ("vía 0: el salto se toma", "w"), 1: ("vía 1, su pareja: FlushM1", "bad"), 2: ("FlushE0", "bad"), 3: ("FlushE1", "bad"),
           4: ("FlushD", "bad"), 5: ("FlushD", "bad"), 6: ("el destino entra en el ciclo 4", "ok")}, ancho_notas=280))
