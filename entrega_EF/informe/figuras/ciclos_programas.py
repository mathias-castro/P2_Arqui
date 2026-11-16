# Ciclos de los dos programas de comparacion en las tres arquitecturas.
# En rojo, los ciclos que se pierden en flushes por saltos (2 por flush). fin no se cuenta.
grupos = [("Programa del profesor", [("A Single-Issue", 459, 67), ("B Dual-Issue", 387, 67), ("C con predicción", 292, 32)]),
          ("Programa propio",       [("A Single-Issue", 340, 48), ("B Dual-Issue", 289, 48), ("C con predicción", 204, 16)])]
esc, x0, alto = 1.18, 170, 30
H = 40 + sum(30 + 40 * len(b) for _, b in grupos) + 10
s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 {H}" width="800" height="{H}" font-family="Arial, Liberation Sans, sans-serif">']
s.append(f'<rect x="{x0}" y="8" width="16" height="16" fill="#90a4ae"/><text x="{x0+22}" y="21" font-size="14">resto de los ciclos</text>')
s.append(f'<rect x="{x0+175}" y="8" width="16" height="16" fill="#e57373"/><text x="{x0+197}" y="21" font-size="14">ciclos perdidos en flushes por saltos</text>')
y = 40
for titulo, barras in grupos:
    s.append(f'<text x="10" y="{y+18}" font-size="15" font-weight="bold" fill="#1565c0">{titulo}</text>')
    y += 30
    for n, c, f in barras:
        p = 2 * f
        s.append(f'<text x="{x0-10}" y="{y+20}" font-size="14" text-anchor="end">{n}</text>')
        s.append(f'<rect x="{x0}" y="{y}" width="{(c-p)*esc:.1f}" height="{alto}" fill="#90a4ae"/>')
        s.append(f'<rect x="{x0+(c-p)*esc:.1f}" y="{y}" width="{p*esc:.1f}" height="{alto}" fill="#e57373"/>')
        s.append(f'<text x="{x0+(c-p)*esc+p*esc/2:.1f}" y="{y+20}" font-size="13" text-anchor="middle" fill="#fff" font-weight="bold">{p}</text>')
        s.append(f'<text x="{x0+6+c*esc:.1f}" y="{y+20}" font-size="14">{c} ciclos</text>')
        y += 40
s.append('</svg>')
open('ciclos_programas.svg', 'w').write('\n'.join(s))
