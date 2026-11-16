#!/usr/bin/env python3
"""Genera datapath_single.svg: datapath del pipeline RISC-V Single-Issue de cinco
etapas (entrega_E2/single_issue/src/datapath.v) en el estilo de Harris & Harris
(Fig. 7.61). Mismos helpers y estilo que datapath_dual.py. Coordenadas a mano.
"""
import sys
from PIL import ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'datapath_single.svg'

# ------------------------------------------------------------------ estilo
BLACK = '#000000'
BLUE = '#1f8fd0'
GRAY = '#6b6b6b'
FS = 17          # nombres de senal
FP = 16          # puertos dentro de bloques
FB = 13.5        # campos de bits / indices
FI = 14          # nombres de instancia
WD = 3.0         # cable de datos
WC = 1.7         # cable de control
WBUS = 7.0       # bus agrupado
FONT = "Arial, 'Liberation Sans', Helvetica, sans-serif"

_fr = ImageFont.truetype('/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf', 100)
_fb = ImageFont.truetype('/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf', 100)


def tw(s, size=FS, bold=False):
    return (_fb if bold else _fr).getlength(s) * size / 100.0


W, H = 3170, 2175
YC = 1095


def M(y):
    return 2 * YC - y


def Y(v, y):
    return y if v == 0 else M(y)


L = {k: [] for k in ('tint', 'wire', 'block', 'dot', 'text')}
TXT = []   # (x0,y0,x1,y1,texto) para la verificacion de solapes
SEG = []   # segmentos de cable (x0,y0,x1,y1,kind)


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def fmt(v):
    return ('%.2f' % v).rstrip('0').rstrip('.')


# ------------------------------------------------------------------ primitivas
def wire(pts, kind='d'):
    col, w = {'d': (BLACK, WD), 'c': (BLUE, WC), 'b': (BLACK, WBUS), 'cb': (BLUE, 3.6)}[kind]
    for (a, b) in zip(pts, pts[1:]):
        SEG.append((a[0], a[1], b[0], b[1], kind))
    p = ' '.join('%s,%s' % (fmt(x), fmt(y)) for x, y in pts)
    L['wire'].append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" '
                     'stroke-linejoin="miter" stroke-linecap="butt"/>' % (p, col, w))


def dot(x, y, kind='d'):
    col, r = {'d': (BLACK, 5), 'c': (BLUE, 3.6), 'b': (BLACK, 7)}[kind]
    L['dot'].append('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (fmt(x), fmt(y), r, col))


def text(x, y, s, size=FS, anchor='start', col=BLACK, bold=False, italic=False, rot=0,
         halo=True, layer='text'):
    if s:
        w_ = tw(s, size, bold)
        dx = {'start': 0, 'middle': -w_ / 2, 'end': -w_}[anchor]
        if rot == 0:
            TXT.append((x + dx, y - 0.72 * size, x + dx + w_, y + 0.2 * size, s))
        else:   # rot -90: el texto sube desde y
            TXT.append((x - 0.72 * size, y - dx - w_, x + 0.2 * size, y - dx, s))
    st = ''
    if bold:
        st += ' font-weight="bold"'
    if italic:
        st += ' font-style="italic"'
    if halo:
        st += ' stroke="#ffffff" stroke-width="4" stroke-linejoin="round" paint-order="stroke"'
    tr = ' transform="rotate(%s %s %s)"' % (rot, fmt(x), fmt(y)) if rot else ''
    L[layer].append('<text x="%s" y="%s" font-size="%s" text-anchor="%s" fill="%s"%s%s>%s</text>'
                    % (fmt(x), fmt(y), size, anchor, col, st, tr, esc(s)))


def lab(x, y, s, kind='d', anchor='start', v=0):
    """Nombre de senal sobre un cable horizontal en altura y: encima en la via 0,
    debajo en la via 1 (espejo)."""
    yy = y - 5 if v == 0 else y + FS - 1
    text(x, yy, s, FS, anchor, BLUE if kind == 'c' else BLACK)


def tag(x, y, name, side, kind='d'):
    """Etiqueta de red. (x,y) es el extremo del tramo de cable; la caja se
    dibuja hacia `side` ('l','r','u','d')."""
    col = BLUE if kind == 'c' else BLACK
    w = tw(name) + 12
    h = FS + 6
    if side in ('l', 'r'):
        x0 = x - w if side == 'l' else x
        L['block'].append('<rect x="%s" y="%s" width="%s" height="%s" rx="5" fill="#fff" '
                          'stroke="%s" stroke-width="1.3"/>' % (fmt(x0), fmt(y - h / 2), fmt(w), h, col))
        text(x0 + w / 2, y + FS * 0.36, name, FS, 'middle', col, halo=False, layer='block')
    else:
        y0 = y - w if side == 'u' else y
        L['block'].append('<rect x="%s" y="%s" width="%s" height="%s" rx="5" fill="#fff" '
                          'stroke="%s" stroke-width="1.3"/>' % (fmt(x - h / 2), fmt(y0), h, fmt(w), col))
        cy = y0 + w / 2
        text(x + FS * 0.36, cy, name, FS, 'middle', col, halo=False, rot=-90, layer='block')
    return w


def vtag_text(x, y, s, size=FS, col=BLUE):
    """texto rotado (lee de abajo hacia arriba) con base en x, empezando en y."""
    text(x, y, s, size, 'start', col, rot=-90)


def poly(pts, stroke=BLACK, sw=WD, fill='#fff', layer='block', extra=''):
    p = ' '.join('%s,%s' % (fmt(x), fmt(y)) for x, y in pts)
    L[layer].append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" '
                    'stroke-linejoin="miter"%s/>' % (p, fill, stroke, sw, extra))


def rect(x, y, w, h, stroke=BLACK, sw=WD, fill='#fff', rx=0, layer='block'):
    L[layer].append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" stroke="%s" '
                    'stroke-width="%s"/>' % (fmt(x), fmt(y), fmt(w), fmt(h), rx, fill, stroke, sw))


def mux(x, ys, w, ins, sel, sel_y_end=None, name=None, name_pos=None, slant=None, kind_sel='c'):
    """Mux de izquierda a derecha. ys=(ytop,ybot). ins=[(y,label)].
    sel = 'top'|'bottom'. Devuelve (xout, yout, xsel, ysel_edge)."""
    y0, y1 = ys
    s = slant if slant is not None else min(14, (y1 - y0) * 0.14)
    poly([(x, y0), (x + w, y0 + s), (x + w, y1 - s), (x, y1)])
    for (yy, lb) in ins:
        text(x + 4, yy + FP * 0.36, lb, 14.5 if len(lb) > 2 else FP, 'start', BLACK, halo=False,
             layer='block')
    xs = x + w * 0.72
    ysel = y0 + s * 0.72 if sel == 'top' else y1 - s * 0.72
    return x + w, (y0 + y1) / 2, xs, ysel


def regbar(x, y0, y1, w=30, en=False, clr=False, names=(), dividers=(), clk_top=True):
    rect(x, y0, w, y1 - y0, sw=WD)
    for d in dividers:
        L['block'].append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"/>'
                          % (fmt(x), fmt(d), fmt(x + w), fmt(d), BLACK))
    # CLK
    cx = x + w / 2
    poly([(cx - 10, y0), (cx + 10, y0), (cx, y0 + 12)], sw=2)
    L['block'].append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2"/>'
                      % (fmt(cx), fmt(y0 - 16), fmt(cx), fmt(y0), BLACK))
    text(cx, y0 - 20, 'CLK', FP, 'middle', BLACK, halo=False)
    for (ym, nm) in names:
        text(cx + 5, ym, nm, FI, 'middle', GRAY, italic=True, rot=-90, halo=False, layer='block')
    ports = {}
    if en and clr:
        xe, xc = x + 8, x + w - 8
        text(xe + 5, y1 - 4, 'EN', 12.5, 'start', BLACK, rot=-90, halo=False, layer='block')
        text(xc + 5, y1 - 4, 'CLR', 12.5, 'start', BLACK, rot=-90, halo=False, layer='block')
        L['block'].append('<circle cx="%s" cy="%s" r="5.5" fill="#fff" stroke="%s" stroke-width="2"/>'
                          % (fmt(xe), fmt(y1 + 5.5), BLACK))
        ports['en'] = (xe, y1 + 11)
        ports['clr'] = (xc, y1)
    elif clr:
        xc = cx
        text(xc + 5, y1 - 4, 'CLR', 12.5, 'start', BLACK, rot=-90, halo=False, layer='block')
        ports['clr'] = (xc, y1)
    elif en:
        xe = cx
        text(xe + 5, y1 - 4, 'EN', 12.5, 'start', BLACK, rot=-90, halo=False, layer='block')
        L['block'].append('<circle cx="%s" cy="%s" r="5.5" fill="#fff" stroke="%s" stroke-width="2"/>'
                          % (fmt(xe), fmt(y1 + 5.5), BLACK))
        ports['en'] = (xe, y1 + 11)
    return ports


def alu_shape(x, y0, w, h, label='ALU', plus=False):
    pts = [(x, y0), (x + w, y0 + 0.2 * h), (x + w, y0 + 0.8 * h), (x, y0 + h),
           (x, y0 + 0.58 * h), (x + 0.28 * w, y0 + 0.5 * h), (x, y0 + 0.42 * h)]
    poly(pts)
    if plus:
        text(x + 0.62 * w, y0 + 0.5 * h + 7, '+', 22, 'middle', BLACK, halo=False, layer='block')
    else:
        text(x + 0.66 * w + 8, y0 + 0.5 * h, label, 20, 'middle', BLACK, rot=-90, halo=False,
             layer='block')


def and_gate(x, y0, h, col=BLUE, w=None):
    w = w or h * 0.95
    r = h / 2
    d = 'M %s %s L %s %s A %s %s 0 0 1 %s %s L %s %s Z' % (
        fmt(x), fmt(y0), fmt(x + w - r), fmt(y0), fmt(r), fmt(r), fmt(x + w - r), fmt(y0 + h),
        fmt(x), fmt(y0 + h))
    L['block'].append('<path d="%s" fill="#fff" stroke="%s" stroke-width="2"/>' % (d, col))
    return x + w, y0 + h / 2


def or_gate(x, y0, h, col=BLUE, w=None):
    w = w or h * 1.05
    d = ('M %s %s Q %s %s %s %s Q %s %s %s %s Q %s %s %s %s Z' % (
        fmt(x), fmt(y0),
        fmt(x + w * 0.6), fmt(y0), fmt(x + w), fmt(y0 + h / 2),
        fmt(x + w * 0.6), fmt(y0 + h), fmt(x), fmt(y0 + h),
        fmt(x + w * 0.3), fmt(y0 + h / 2), fmt(x), fmt(y0)))
    L['block'].append('<path d="%s" fill="#fff" stroke="%s" stroke-width="2"/>' % (d, col))
    return x + w, y0 + h / 2


def or_in_x(x, y0, h, yy, w=None):
    """x del borde izquierdo (concavo) del OR en la altura yy."""
    t = abs((yy - (y0 + h / 2)) / (h / 2))
    w = w or h * 1.05
    # curva cuadratica aproximada: profundidad maxima 0.15w en el centro
    return x + w * 0.15 * (1 - t * t)


def busbar(x, ya, yb, w=6):
    rect(x, ya, w, yb - ya, stroke=BLACK, sw=1, fill=BLACK)


# =================================================================== GEOMETRIA
W, H = 2135, 1140
BT, BB = 155, 830               # barras de pipeline
X_FD, X_DE, X_EM, X_MW = 415, 880, 1465, 1860
BW = 30
HZ0, HZ1 = 1075, 1120           # Hazard Unit
TOP_PCSRC, TOP_REGW = 46, 64    # cables que vuelven por arriba
# filas
C = dict(RegWrite=170, ResultSrc=194, MemWrite=218, Jump=242, Branch=266, ALUControl=290,
         ALUSrc=314, ImmSrc=338)
D = dict(Instr=395, RD1=420, RD2=490, PC=625, Rs1=650, Rs2=675, Rd=705, Imm=755, PCPlus4=810)
LP = dict(PCPlus4F=840, PCTarget=870, ALUResultM=895, ResultW=920, RdW=945)   # lazos de abajo


def ginst(x, y, s, anchor='middle'):
    text(x, y, s, FI, anchor, GRAY, italic=True, halo=False)


def hz(x, y_top, name, side='l'):
    """Cable azul vertical desde y_top hasta la Hazard Unit, con su nombre al costado."""
    wire([(x, y_top), (x, HZ0)], 'c')
    if side == 'l':
        text(x - 4, HZ0 - 6, name, FS, 'start', BLUE, rot=-90)
    else:
        text(x + 16, HZ0 - 6, name, FS, 'start', BLUE, rot=-90)


# =================================================================== FETCH
def fetch():
    # pcmux: 0 PCPlus4F, 1 PCTargetE, s = PCSrcE
    xo, yo, xs, ys = mux(38, (390, 450), 30, [(405, '0'), (435, '1')], 'top', slant=8)
    ginst(53, 472, 'pcmux')
    wire([(xo, yo), (140, 420)])
    text(102, 415, 'PCNextF', 15, 'middle')
    p = regbar(140, 380, 460, en=True)
    ginst(136, 456, 'pcreg', 'end')
    hz(p['en'][0], p['en'][1], 'StallF')
    # PCF
    wire([(170, 420), (215, 420)])
    lab(176, 420, 'PCF')
    dot(190, 420)
    wire([(190, 420), (190, 650), (235, 650)])
    dot(190, D['PC'])
    wire([(190, D['PC']), (X_FD, D['PC'])])
    lab(330, D['PC'], 'PCF')
    # Instruction Memory (imem de top.v)
    rect(215, 360, 130, 150)
    text(221, 420 + 6, 'A', FP, halo=False, layer='block')
    text(339, D['Instr'] + 6, 'RD', FP, 'end', halo=False, layer='block')
    text(280, 455, 'Instruction', 17, 'middle', bold=True, halo=False, layer='block')
    text(280, 476, 'Memory', 17, 'middle', bold=True, halo=False, layer='block')
    ginst(280, 528, 'imem (top)')
    wire([(345, D['Instr']), (X_FD, D['Instr'])])
    lab(352, D['Instr'], 'InstrF')
    # pcadd4: a = PCF (650), b = 4 (700), y = PCPlus4F (675)
    alu_shape(235, 639, 60, 71, plus=True)
    ginst(265, 728, 'pcadd4')
    wire([(215, 700), (235, 700)])
    text(209, 700 + 6, '4', FP, 'end', halo=False)
    wire([(295, 675), (320, 675), (320, D['PCPlus4']), (X_FD, D['PCPlus4'])])
    dot(320, D['PCPlus4'])
    lab(328, D['PCPlus4'], 'PCPlus4F')
    wire([(320, D['PCPlus4']), (320, LP['PCPlus4F']), (24, LP['PCPlus4F']), (24, 405), (38, 405)])
    # PCSrcE -> seleccion del pcmux (vuelve por arriba)
    wire([(xs, ys), (xs, TOP_PCSRC)], 'c')
    # PCTargetE -> entrada 1 (vuelve por abajo)
    wire([(11, LP['PCTarget']), (11, 435), (38, 435)])


# =================================================================== REGISTROS
def bars():
    p = regbar(X_FD, BT, BB, en=True, clr=True, names=[(480, 'fdreg')])
    hz(p['en'][0], p['en'][1], 'StallD')
    hz(p['clr'][0], p['clr'][1], 'FlushD', 'r')
    dv = 380
    p = regbar(X_DE, BT, BB, clr=True, dividers=[dv],
               names=[(268, 'controlereg'), (560, 'dereg')])
    hz(p['clr'][0], p['clr'][1], 'FlushE')
    regbar(X_EM, BT, BB, dividers=[dv], names=[(268, 'controlmreg'), (560, 'emreg')])
    regbar(X_MW, BT, BB, dividers=[dv], names=[(268, 'controlwreg'), (560, 'mwreg')])


# =================================================================== DECODE
def decode():
    xr = X_FD + BW            # 445
    bus = 475
    # InstrD -> bus de campos de bits
    wire([(xr, D['Instr']), (bus, D['Instr'])])
    text(bus + 6, D['Instr'] - 7, 'InstrD', FS)
    wire([(bus, 290), (bus, D['Imm'])])
    dot(bus, D['Instr'])
    # PCD / PCPlus4D
    wire([(xr, D['PC']), (X_DE, D['PC'])])
    lab(600, D['PC'], 'PCD')
    wire([(xr, D['PCPlus4']), (X_DE, D['PCPlus4'])])
    lab(600, D['PCPlus4'], 'PCPlus4D')
    # Control Unit (controller c de riscv.v)
    rect(515, 155, 90, 210, stroke=BLUE, sw=2.2, rx=14)
    text(560, 190, 'Control', 17, 'middle', BLUE, bold=True, halo=False, layer='block')
    text(560, 210, 'Unit', 17, 'middle', BLUE, bold=True, halo=False, layer='block')
    text(560, 232, 'c (riscv)', FI, 'middle', GRAY, italic=True, halo=False, layer='block')
    for q, pn, bits in ((290, 'op', '6:0'), (315, 'funct3', '14:12'), (340, 'funct7b5', '30')):
        wire([(bus, q), (515, q)])
        text(521, q + 6, pn, 15, 'start', BLACK, halo=False, layer='block')
        text(bus + 3, q - 4, bits, 12.5)
        if q != 290:
            dot(bus, q)
    for k in ('RegWrite', 'ResultSrc', 'MemWrite', 'Jump', 'Branch', 'ALUControl', 'ALUSrc'):
        wire([(605, C[k]), (X_DE, C[k])], 'c')
        lab(707, C[k], k + 'D', 'c')
    # ImmSrcD -> Extend
    ex0, ex1 = 585, 730
    ext_top = lambda xx: 745 + (730 - 745) * (xx - ex0) / (ex1 - ex0)
    wire([(605, C['ImmSrc']), (715, C['ImmSrc']), (715, ext_top(715))], 'c')
    lab(707, C['ImmSrc'], 'ImmSrcD', 'c')
    # Register File (rf): A1 = Rs1D, A2 = Rs2D, A3 = RdW, WD3 = ResultW, WE3 = RegWriteW
    x0, y0, x1, y1 = 545, 400, 705, 575
    rect(x0, y0, x1 - x0, y1 - y0)
    cx = 570
    poly([(cx - 10, y0), (cx + 10, y0), (cx, y0 + 12)], sw=2)
    L['block'].append('<circle cx="%s" cy="%s" r="5" fill="#fff" stroke="#000" stroke-width="2"/>'
                      % (cx, y0 - 5))
    text(cx + 10, y0 - 6, 'CLK', 15, 'start', halo=False, layer='block')
    for yy, pn in ((D['RD1'], 'A1'), (D['RD2'], 'A2'), (525, 'A3'), (555, 'WD3')):
        text(x0 + 6, yy + 6, pn, FP, halo=False, layer='block')
    text(x1 - 6, D['RD1'] + 6, 'RD1', FP, 'end', halo=False, layer='block')
    text(x1 - 6, D['RD2'] + 6, 'RD2', FP, 'end', halo=False, layer='block')
    text(620, y0 + 22, 'WE3', FP, 'middle', halo=False, layer='block')
    text(630, 528, 'Register', 17, 'middle', bold=True, halo=False, layer='block')
    text(630, 549, 'File', 17, 'middle', bold=True, halo=False, layer='block')
    text(630, 569, 'rf', FI, 'middle', GRAY, italic=True, halo=False, layer='block')
    for q, bits in ((D['RD1'], '19:15'), (D['RD2'], '24:20')):
        dot(bus, q)
        wire([(bus, q), (x0, q)])
        text(bus + 5, q - 4, bits, FB)
    wire([(x1, D['RD1']), (X_DE, D['RD1'])])
    lab(750, D['RD1'], 'RD1D')
    wire([(x1, D['RD2']), (X_DE, D['RD2'])])
    lab(750, D['RD2'], 'RD2D')
    # Rs1D, Rs2D, RdD
    for k, bits, nm in (('Rs1', '19:15', 'Rs1D'), ('Rs2', '24:20', 'Rs2D'), ('Rd', '11:7', 'RdD')):
        dot(bus, D[k])
        wire([(bus, D[k]), (X_DE, D[k])])
        text(bus + 5, D[k] - 4, bits, FB)
        lab(600 if k != 'Rd' else 600, D[k], nm)
    # Extend (ext)
    poly([(ex0, 745), (ex1, 730), (ex1, 780), (ex0, 780)])
    text((ex0 + ex1) / 2 + 10, 762 + 7, 'Extend', 17, 'middle', bold=True, halo=False, layer='block')
    ginst(ex1 + 6, 794, 'ext', 'start')
    wire([(bus, D['Imm']), (ex0, D['Imm'])])
    text(bus + 5, D['Imm'] - 4, '31:7', FB)
    wire([(ex1, D['Imm']), (X_DE, D['Imm'])])
    lab(738, D['Imm'], 'ImmExtD')
    # escritura del Register File: RegWriteW (por arriba), RdW y ResultW (por abajo)
    wire([(620, TOP_REGW), (620, y0)], 'c')
    wire([(518, LP['RdW']), (518, 525), (x0, 525)])
    wire([(533, LP['ResultW']), (533, 555), (x0, 555)])
    # Rs1D / Rs2D -> Hazard Unit
    dot(820, D['Rs1'])
    hz(820, D['Rs1'], 'Rs1D')
    dot(840, D['Rs2'])
    hz(840, D['Rs2'], 'Rs2D')


# =================================================================== EXECUTE
def execute():
    xr = X_DE + BW            # 910
    for k in ('RegWrite', 'ResultSrc', 'MemWrite'):
        wire([(xr, C[k]), (X_EM, C[k])], 'c')
        lab(916, C[k], k + 'E', 'c')
    # ResultSrcE[0] -> Hazard Unit (puerto ResultSrcE0)
    dot(1440, C['ResultSrc'], 'c')
    hz(1440, C['ResultSrc'], 'ResultSrcE[0]')
    # ALU (alu): a = SrcAE (440), b = SrcBE (530)
    ax, ay0, ah = 1195, 421, 129
    wire([(xr, C['ALUControl']), (1225, C['ALUControl']), (1225, ay0 + 0.2 * ah * 0.5)], 'c')
    lab(916, C['ALUControl'], 'ALUControlE', 'c')
    # srcbmux: 0 WriteDataE (510), 1 ImmExtE (550), s = ALUSrcE
    xso, yso, xss, yss = mux(1135, (495, 565), 30, [(510, '0'), (550, '1')], 'top', slant=8)
    ginst(1131, 600, 'srcbmux', 'start')
    wire([(xr, C['ALUSrc']), (xss, C['ALUSrc']), (xss, yss)], 'c')
    lab(916, C['ALUSrc'], 'ALUSrcE', 'c')
    # Jump / Branch / Zero -> PCSrcE = (BranchE & ZeroE) | JumpE
    and_x, and_y0, and_h = 1295, 78, 44           # entradas 88 y 112, salida 100
    ax_, ay_ = and_gate(and_x, and_y0, and_h)
    or_x, or_y0, or_h = 1355, 88, 58              # entradas 100 y 134, salida 117
    ox, oy = or_gate(or_x, or_y0, or_h)
    wire([(xr, C['Branch']), (1279, C['Branch']), (1279, 88), (and_x, 88)], 'c')
    lab(916, C['Branch'], 'BranchE', 'c')
    wire([(xr, C['Jump']), (1340, C['Jump']), (1340, 134), (or_in_x(or_x, or_y0, or_h, 134) + 1, 134)], 'c')
    lab(916, C['Jump'], 'JumpE', 'c')
    wire([(ax_, ay_), (or_in_x(or_x, or_y0, or_h, ay_) + 1, ay_)], 'c')
    wire([(ox, oy), (1420, oy)], 'c')
    dot(1420, oy, 'c')
    wire([(1420, oy), (1420, TOP_PCSRC), (38 + 30 * 0.72, TOP_PCSRC)], 'c')
    text(1300, TOP_PCSRC - 5, 'PCSrcE', FS, 'start', BLUE)
    hz(1420, oy, 'PCSrcE')
    # forwarding (forwardaemux / forwardbemux): 00 RD, 01 ResultW, 10 ALUResultM
    xa_o, ya_o, xa_s, ya_s = mux(1025, (405, 475), 30, [(420, '00'), (440, '01'), (460, '10')],
                                 'bottom', slant=6)
    xb_o, yb_o, xb_s, yb_s = mux(1070, (475, 545), 30, [(490, '00'), (510, '01'), (530, '10')],
                                 'bottom', slant=6)
    ginst(1040, 398, 'forwardaemux')
    ginst(1060, 470, 'forwardbemux', 'start')
    wire([(xr, D['RD1']), (1025, D['RD1'])])
    lab(916, D['RD1'], 'RD1E')
    wire([(xr, D['RD2']), (1070, D['RD2'])])
    lab(916, D['RD2'], 'RD2E')
    hz(xa_s, ya_s, 'ForwardAE')
    hz(xb_s, yb_s, 'ForwardBE')
    # ResultW (x 990) y ALUResultM (x 1005) suben desde los lazos de abajo
    dot(990, 510)
    wire([(990, LP['ResultW']), (990, 440), (1025, 440)])
    wire([(990, 510), (1070, 510)])
    dot(1005, 530)
    wire([(1005, LP['ALUResultM']), (1005, 460), (1025, 460)])
    wire([(1005, 530), (1070, 530)])
    # SrcAE / WriteDataE / SrcBE
    wire([(xa_o, ya_o), (ax, 440)])
    lab(1062, 440, 'SrcAE')
    wire([(xb_o, yb_o), (1135, 510)])
    dot(1115, 510)
    wire([(1115, 510), (1115, 580), (X_EM, 580)])
    lab(1280, 580, 'WriteDataE')
    wire([(xso, yso), (ax, 530)])
    alu_shape(ax, ay0, 60, ah)
    text(ax + 5, 440 + 5, 'A', 13, 'start', halo=False, layer='block')
    text(ax + 5, 530 + 5, 'B', 13, 'start', halo=False, layer='block')
    ginst(ax + 30, ay0 + ah + 17, 'alu')
    yres = ay0 + ah / 2
    wire([(ax + 60, yres), (X_EM, yres)])
    lab(1280, yres, 'ALUResultE')
    # ZeroE -> AND
    yz = ay0 + 0.27 * ah
    wire([(ax + 60, yz), (1287, yz), (1287, 112), (and_x, 112)], 'c')
    text(1293, 380, 'ZeroE', FS, 'start', BLUE)
    # PCE + ImmExtE -> pcaddbranch -> PCTargetE
    wire([(xr, D['PC']), (1175, D['PC'])])
    lab(916, D['PC'], 'PCE')
    dot(1125, D['Imm'])
    wire([(xr, D['Imm']), (1155, D['Imm']), (1155, 670), (1175, 670)])
    wire([(1125, D['Imm']), (1125, 550), (1135, 550)])
    text(1161, 742, 'ImmExtE', FS)
    alu_shape(1175, 615.4, 60, 64, plus=True)      # a=625 b=670 out=647
    ginst(1205, 696, 'pcaddbranch')
    wire([(1235, 647), (1265, 647), (1265, LP['PCTarget']), (11, LP['PCTarget'])])
    # Rs1E / Rs2E / RdE -> Hazard Unit
    wire([(xr, D['Rs1']), (930, D['Rs1'])])
    hz(930, D['Rs1'], 'Rs1E')
    wire([(xr, D['Rs2']), (950, D['Rs2'])])
    hz(950, D['Rs2'], 'Rs2E')
    wire([(xr, D['Rd']), (X_EM, D['Rd'])])
    dot(970, D['Rd'])
    hz(970, D['Rd'], 'RdE')
    lab(1280, D['Rd'], 'RdE')
    wire([(xr, D['PCPlus4']), (X_EM, D['PCPlus4'])])
    lab(1280, D['PCPlus4'], 'PCPlus4E')


# =================================================================== MEMORY
def memory():
    xr = X_EM + BW            # 1495
    for k in ('RegWrite', 'ResultSrc'):
        wire([(xr, C[k]), (X_MW, C[k])], 'c')
        lab(1562, C[k], k + 'M', 'c')
    dot(1535, C['RegWrite'], 'c')
    hz(1535, C['RegWrite'], 'RegWriteM', 'r')
    # MemWriteM -> WE
    x0, y0, x1, y1 = 1660, 450, 1760, 610
    wire([(xr, C['MemWrite']), (1738, C['MemWrite']), (1738, y0)], 'c')
    lab(1562, C['MemWrite'], 'MemWriteM', 'c')
    # ALUResultM: A de dmem, M/W (por encima de la memoria) y forwarding (por abajo)
    yA = 485
    wire([(xr, yA), (x0, yA)])
    dot(1555, yA)
    wire([(1555, yA), (1555, 410), (X_MW, 410)])
    lab(1562, 410, 'ALUResultM')
    wire([(1555, yA), (1555, LP['ALUResultM']), (1005, LP['ALUResultM'])])
    # WriteDataM -> WD
    wire([(xr, 580), (x0, 580)])
    text(1562, 580 - 5, 'WriteDataM', FS)
    # Data Memory (dmem de top.v)
    rect(x0, y0, x1 - x0, y1 - y0)
    cx = x0 + 25
    poly([(cx - 10, y0), (cx + 10, y0), (cx, y0 + 12)], sw=2)
    L['block'].append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#000" stroke-width="2"/>'
                      % (cx, y0 - 12, cx, y0))
    text(cx, y0 - 15, 'CLK', 15, 'middle', halo=False, layer='block')
    text(1738, y0 + 22, 'WE', FP, 'middle', halo=False, layer='block')
    text(x0 + 6, yA + 6, 'A', FP, halo=False, layer='block')
    text(x0 + 6, 580 + 6, 'WD', FP, halo=False, layer='block')
    text(x1 - 6, yA + 6, 'RD', FP, 'end', halo=False, layer='block')
    text((x0 + x1) / 2 + 6, 530, 'Data', 17, 'middle', bold=True, halo=False, layer='block')
    text((x0 + x1) / 2 + 6, 551, 'Memory', 17, 'middle', bold=True, halo=False, layer='block')
    ginst((x0 + x1) / 2, y1 + 18, 'dmem (top)')
    wire([(x1, yA), (X_MW, yA)])
    lab(1765, yA, 'ReadDataM')
    # RdM
    wire([(xr, D['Rd']), (X_MW, D['Rd'])])
    dot(1515, D['Rd'])
    hz(1515, D['Rd'], 'RdM')
    lab(1562, D['Rd'], 'RdM')
    wire([(xr, D['PCPlus4']), (X_MW, D['PCPlus4'])])
    lab(1562, D['PCPlus4'], 'PCPlus4M')


# =================================================================== WRITEBACK
def writeback():
    xr = X_MW + BW            # 1860
    # RegWriteW -> WE3 (por arriba) y Hazard Unit
    wire([(xr, C['RegWrite']), (1908, C['RegWrite']), (1908, TOP_REGW), (620, TOP_REGW)], 'c')
    dot(860, TOP_REGW, 'c')
    hz(860, TOP_REGW, 'RegWriteW')
    text(1500, TOP_REGW - 5, 'RegWriteW', FS, 'start', BLUE)
    # resultmux: 00 ALUResultW, 01 ReadDataW, 10 PCPlus4W, s = ResultSrcW
    mx = 2055
    xo, yo, xs, ys = mux(mx, (425, 515), 36, [(440, '00'), (470, '01'), (500, '10')], 'top', slant=10)
    ginst(mx + 18, 534, 'resultmux')
    wire([(xr, C['ResultSrc']), (xs, C['ResultSrc']), (xs, ys)], 'c')
    lab(1913, C['ResultSrc'], 'ResultSrcW', 'c')
    wire([(xr, 410), (2010, 410), (2010, 440), (mx, 440)])
    wire([(xr, 485), (2025, 485), (2025, 470), (mx, 470)])
    wire([(xr, D['PCPlus4']), (2040, D['PCPlus4']), (2040, 500), (mx, 500)])
    # ResultW -> WD3 y forwarding (por abajo)
    wire([(xo, yo), (2115, yo), (2115, LP['ResultW']), (533, LP['ResultW'])])
    dot(990, LP['ResultW'])
    lab(1700, LP['ResultW'], 'ResultW')
    # RdW -> A3 (por abajo) y Hazard Unit
    wire([(xr, D['Rd']), (1901, D['Rd']), (1901, LP['RdW']), (518, LP['RdW'])])
    dot(1600, LP['RdW'])
    hz(1600, LP['RdW'], 'RdW')


def wb_labels():
    xr = X_MW + BW
    text(1913, 410 - 5, 'ALUResultW', FS, 'start')
    text(1913, 485 - 5, 'ReadDataW', FS, 'start')
    text(1913, D['PCPlus4'] - 5, 'PCPlus4W', FS, 'start')


def loops_labels():
    lab(170, LP['PCTarget'], 'PCTargetE')
    lab(1100, LP['ALUResultM'], 'ALUResultM')
    lab(1270, LP['RdW'], 'RdW')


# =================================================================== HAZARD UNIT
def hazard_unit():
    rect(10, HZ0, W - 20, HZ1 - HZ0, stroke=BLUE, sw=2.2, rx=16)
    text(700, HZ0 + 30, 'Hazard Unit', 18, 'middle', BLUE, bold=True, halo=False, layer='block')
    ginst(24, HZ0 + 28, 'hu', 'start')


def frame():
    for x, t in ((215, 'Fetch'), (648, 'Decode'), (1172, 'Execute'), (1648, 'Memory'),
                 (2010, 'Writeback')):
        text(x, 26, t, 20, 'middle', '#4a4a4a', bold=True, halo=False)


def build():
    frame()
    fetch()
    bars()
    decode()
    execute()
    memory()
    writeback()
    wb_labels()
    loops_labels()
    hazard_unit()
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" '
           'font-family="%s">' % (W, H, W, H, FONT.replace('"', "'")),
           '<rect x="0" y="0" width="%d" height="%d" fill="#ffffff"/>' % (W, H)]
    for k in ('tint', 'wire', 'block', 'dot', 'text'):
        out.append('<g id="%s">' % k)
        out.extend(L[k])
        out.append('</g>')
    out.append('</svg>')
    with open(OUT, 'w') as f:
        f.write('\n'.join(out))


if __name__ == '__main__':
    build()
