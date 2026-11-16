# Grafico de barras de ciclos (A, B, C) para los programas de comparacion.
datos = [("Programa propio", 341, 289, 204), ("riscvtest", 28, 24, 24)]
cols = [("A Single-Issue", "#9e9e9e"), ("B Dual-Issue", "#64b5f6"), ("C con predicción", "#1565c0")]
W, H = 760, 120 + 150 * len(datos)
mx = max(max(d[1:]) for d in datos)
esc = 470 / mx
s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="Arial, Liberation Sans, sans-serif">']
x = 190
for n, c in cols:
    s.append(f'<rect x="{x}" y="14" width="16" height="16" fill="{c}"/><text x="{x+22}" y="27" font-size="16">{n}</text>')
    x += 190
for i, (nom, *v) in enumerate(datos):
    y0 = 70 + i * 150
    s.append(f'<text x="175" y="{y0+62}" font-size="18" text-anchor="end" font-weight="bold">{nom}</text>')
    for k, (val, (n, c)) in enumerate(zip(v, cols)):
        y = y0 + k * 40
        s.append(f'<rect x="190" y="{y}" width="{val*esc:.1f}" height="32" fill="{c}"/>')
        s.append(f'<text x="{196+val*esc:.1f}" y="{y+23}" font-size="17">{val} ciclos</text>')
s.append('</svg>')
open('figs/resultados.svg', 'w').write('\n'.join(s))
