# Ciclos del programa propio en las tres arquitecturas, separando los ciclos que se pierden en flushes por saltos.
datos = [("A Single-Issue", 341, 48), ("B Dual-Issue", 289, 48), ("C con predicción", 204, 16)]
esc = 1.55
s = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 210" width="800" height="210" font-family="Arial, Liberation Sans, sans-serif">']
s.append('<rect x="170" y="8" width="16" height="16" fill="#90a4ae"/><text x="192" y="21" font-size="14">resto de los ciclos</text>')
s.append('<rect x="350" y="8" width="16" height="16" fill="#e57373"/><text x="372" y="21" font-size="14">ciclos perdidos en flushes (sin contar el beq final)</text>')
for i, (n, c, f) in enumerate(datos):
    y = 45 + i * 55
    p = 2 * f
    s.append(f'<text x="160" y="{y+24}" font-size="15" font-weight="bold" text-anchor="end">{n}</text>')
    s.append(f'<rect x="170" y="{y}" width="{(c-p)*esc:.1f}" height="36" fill="#90a4ae"/>')
    s.append(f'<rect x="{170+(c-p)*esc:.1f}" y="{y}" width="{p*esc:.1f}" height="36" fill="#e57373"/>')
    s.append(f'<text x="{170+(c-p)*esc+p*esc/2:.1f}" y="{y+24}" font-size="14" text-anchor="middle" fill="#fff" font-weight="bold">{p}</text>')
    s.append(f'<text x="{176+c*esc:.1f}" y="{y+24}" font-size="15">{c} ciclos</text>')
s.append('</svg>')
open('ciclos_propio.svg', 'w').write('\n'.join(s))
