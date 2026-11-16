# Recortes de las capturas de Vivado de las secciones 2 y 6.
# Cada recorte toma solo algunas filas y algunos ciclos de una captura, escribe arriba
# qué instrucción hay en Fetch, Decode y Execute en cada ciclo, y encierra los valores
# que se explican en el texto. Los valores se sacan de una simulación con Icarus Verilog
# del mismo testbench, así coinciden con lo que muestra Vivado.
import json, os, re, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

AQUI = os.path.dirname(os.path.abspath(__file__))
EF = os.path.abspath(os.path.join(AQUI, '..', '..'))
SPECS = os.path.join(EF, '..', 'herramientas', 'waves')


def carpeta(tb):
    # arquitectura a la que pertenece cada testbench
    if tb.startswith('tb_ef') or tb.endswith('_opt'):
        return 'dual_issue_opt'
    if tb.endswith('_dual') or 'e2' in tb or 'riscvtest' in tb:
        return 'dual_issue'
    return 'single_issue'
FM = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 16)
FS = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 16)
FV = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 17)
COL = {'o': (255, 150, 0), 'y': (255, 235, 40), 'r': (255, 70, 70), 'p': (190, 150, 255)}


def filas(spec):
    out = []
    for x in spec['signals']:
        if 'divider' in x:
            out.append(('--' + x['divider'], None))
        else:
            out.append((x.get('name') or x['path'].split('/')[-1], x.get('radix', 'bin')))
    return out


def ensamblador(mem):
    # direccion -> instruccion corta (mnemonico y primer operando, o destino del salto)
    s = os.path.join(EF, 'programas', mem.replace('.mem', '.s'))
    insts = []
    for ln in open(s):
        ln = ln.split('#')[0].strip()
        if ':' in ln:
            ln = ln.split(':', 1)[1].strip()
        if ln and not ln.startswith('.'):
            insts.append(ln)
    hexs = [h.strip() for h in open(os.path.join(EF, 'programas', mem)) if h.strip()]
    corto = {}
    for h, t in zip(hexs, insts):
        p = t.replace(',', ' ').split()
        if p[0] in ('beq', 'jal'):
            c = p[0] + ' ' + p[-1]
        elif p[0] == 'nop':
            c = 'nop'
        else:
            c = p[0] + ' ' + p[1]
        if h.lower() in corto and corto[h.lower()] != c:
            c = p[0] + ' ' + p[1]          # mismo codigo con otra etiqueta (mismo desplazamiento)
            corto[h.lower()] = c
        corto.setdefault(h.lower(), c)
    corto['00000013'] = 'nop'
    corto['00000000'] = '—'
    return corto


def simular(spec, nombres):
    # nombres: {nombre de la fila: ruta en Vivado}; se agregan las Instr de todas las etapas para las tiras
    tb = spec['top']
    src = os.path.join(EF, carpeta(tb))
    dual = carpeta(tb) != 'single_issue'
    dp = '/%s/dut/%s/dp/' % (tb, 'rvdual' if dual else 'rv')
    for e in 'FDEMW':
        for v in (('0', '1') if dual else ('',)):
            nombres.setdefault('Instr' + e + v, dp + 'Instr' + e + v)
    nombres = dict(sorted(nombres.items()))
    refs = [p.strip('/').replace('/', '.') for p in nombres.values()]
    mon = 'module mon; always @(negedge %s.clk) $display("%%0t %s", $time, %s); endmodule\n' % (
        tb, ' '.join(['%b'] * len(refs)), ', '.join(refs))
    d = tempfile.mkdtemp()
    open(os.path.join(d, 'mon.v'), 'w').write(mon)
    fuentes = [os.path.join(src, 'src', f) for f in os.listdir(os.path.join(src, 'src'))]
    subprocess.run(['iverilog', '-g2012', '-o', os.path.join(d, 'sim'), *fuentes,
                    os.path.join(src, 'tb', tb + '.v'), os.path.join(d, 'mon.v')], check=True)
    out = subprocess.run(['vvp', '-n', os.path.join(d, 'sim')], cwd=os.path.join(EF, 'programas'),
                         capture_output=True, text=True).stdout
    vals = {}
    for ln in out.splitlines():
        p = ln.split()
        if len(p) == len(nombres) + 1 and p[0].isdigit():
            t = (int(p[0]) // 10) * 10        # inicio del ciclo
            vals[t] = dict(zip(list(nombres), p[1:]))
    return vals, dual


def formato(b, radix):
    if 'x' in b or 'z' in b:
        return 'X'
    v = int(b, 2)
    if radix == 'hex':
        return '%08x' % v
    if radix == 'ascii':
        return chr(v) if 32 < v < 127 else ' '
    if radix == 'dec' and len(b) == 32 and v >= 2 ** 31:
        return str(v - 2 ** 32)
    if radix in ('dec', 'unsigned'):
        return str(v)
    return b


def recorte(wave, salida, t0, t1, mostrar, cajas, etapas=('F', 'D', 'E')):
    spec = json.load(open(next(p for p in (os.path.join(SPECS, d, wave + '.json') for d in ('specs_E2', 'specs_EF')) if os.path.exists(p))))
    fs = filas(spec)
    Y = {n: 102 + 37 * i for i, (n, _) in enumerate(fs)}
    radix = dict(fs)
    img = Image.open(os.path.join(AQUI, wave + '.png')).convert('RGB')
    px = img.load()
    x0 = next(x for x in range(img.width) if px[x, 12][0] > 200 and px[x, 12][1] > 200 and px[x, 12][2] < 90)
    pxns = (img.width - x0) / (spec['t1_ns'] - spec['t0_ns'])
    x_of = lambda ns: x0 + (ns - spec['t0_ns']) * pxns
    # ancho de la columna Name: hasta el primer pixel gris oscuro de la cabecera
    namew = next(x for x in range(100, x0) if sum(px[x, 60]) < 650)
    tb = spec['top']
    mem = re.search(r'MEMFILE\("([^"]+)"\)', open(os.path.join(EF, carpeta(tb), 'tb', tb + '.v')).read()).group(1)
    corto = ensamblador(mem)
    nombres = {(x.get('name') or x['path'].split('/')[-1]): x['path'] for x in spec['signals'] if 'path' in x and not x['path'].endswith('/clk')}
    vals, dual = simular(spec, nombres)
    tiras = []
    titulo = {'F': 'Fetch', 'D': 'Decode', 'E': 'Execute', 'M': 'Memory', 'W': 'Writeback'}
    for e in etapas:
        lineas_t = []
        for via in (('0', '1') if dual else ('',)):
            lineas_t.append([corto.get(formato(vals.get(t, {}).get('Instr' + e + via, '0'), 'hex'), '?')
                             for t in range(t0, t1, 10)])
        tiras.append((titulo[e], lineas_t))
    xa, xb = int(x_of(t0)) - 2, min(int(x_of(t1)) + 2, img.width)
    partes = [(0, 88)] + [(Y[r] - 18, Y[r] + 19) for r in mostrar]
    LH = 22
    top = 8 + sum(LH * len(l) + 6 for _, l in tiras)
    out = Image.new('RGB', (namew + xb - xa, top + sum(b - a for a, b in partes)), 'white')
    d = ImageDraw.Draw(out)
    cw = 10 * pxns
    yy = 5
    for j, (tit, lineas_t) in enumerate(tiras):
        if j:
            d.line((4, yy - 4, out.width - 4, yy - 4), fill=(215, 215, 215), width=1)
        d.text((8, yy), tit, font=FS, fill=(40, 40, 40))
        for k, labs in enumerate(lineas_t):
            if dual:
                v = 'vía %d' % k
                d.text((namew - 10 - d.textlength(v, font=FS), yy), v, font=FS, fill=(110, 110, 110))
            for i, t in enumerate(labs):
                cx = namew + (x_of(t0 + 10 * i) + x_of(t0 + 10 * i + 10)) / 2 - xa
                f = FM
                while d.textlength(t, font=f) > cw - 6 and f.size > 9:
                    f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', f.size - 1)
                col = (205, 30, 30) if t == '—' else (21, 101, 192)
                d.text((max(namew + 4, cx - d.textlength(t, font=f) / 2), yy), t, font=f, fill=col)
            yy += LH
        yy += 6
    y = top; pos = {}
    for (a, b), r in zip(partes, ['_'] + list(mostrar)):
        out.paste(img.crop((0, a, namew, b)), (0, y)); out.paste(img.crop((xa, a, xb, b)), (namew, y))
        pos[r] = y; y += b - a
    d.rectangle((namew, top, out.width, top + 21), fill=(0, 0, 0))
    op = out.load()
    for xx in range(namew, out.width):
        for yv in range(top, out.height):
            p = op[xx, yv]
            if p[0] > 200 and p[1] > 200 and p[2] < 90:
                op[xx, yv] = (0, 0, 0)
    # los marcadores de Vivado se numeran de nuevo desde 1 dentro del recorte
    cian = lambda p: p[2] > 200 and p[1] > 180 and p[0] < 80
    lineas = [x for x in range(xa, xb) if cian(px[x, 70])]
    grupos = []
    for x in lineas:
        if grupos and x - grupos[-1][-1] <= 3:
            grupos[-1].append(x)
        else:
            grupos.append([x])
    for k, g in enumerate(grupos, 1):
        cx = namew + (g[0] + g[-1]) / 2 - xa; cy = top + 40
        d.rectangle((cx - 21, top + 22, cx + 21, top + 53), fill=(0, 0, 0))
        d.line((cx, top + 40, cx, top + 54), fill=(0, 200, 230), width=2)
        d.ellipse((cx - 11, cy - 11, cx + 11, cy + 11), fill=(0, 200, 230))
        n = str(k)
        d.text((cx - d.textlength(n, font=FV) / 2, cy - 11), n, font=FV, fill=(0, 0, 0))
    for r, t, c in cajas:
        val = formato(vals[t][r], radix[r])
        x = namew + x_of(t) - xa; yy = pos[r]
        d.rectangle((x + 3, yy + 1, x + cw - 3, yy + 36), fill=(0, 0, 0), outline=COL[c], width=4)
        d.text((x + cw / 2 - d.textlength(val, font=FV) / 2, yy + 9), val, font=FV, fill=(255, 255, 255))
    out.save(os.path.join(AQUI, salida))
    return out.size


if __name__ == '__main__':
    import sys
    exec(open(os.path.join(AQUI, 'recortes_lista.py')).read())
