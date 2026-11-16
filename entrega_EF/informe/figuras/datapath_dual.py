#!/usr/bin/env python3
"""Genera datapath_dual.svg: datapath del procesador RISC-V Dual-Issue
(entrega_E2/dual_issue/src/datapath_dual.v) en el estilo de Harris & Harris.

Coordenadas a mano. La via 1 es el espejo vertical de la via 0 respecto de YC.
Convencion de etiquetas de red: una etiqueta con borde (tag) conecta su cable
con el cable que lleva ese mismo nombre escrito encima.
"""
import sys
from PIL import ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else 'datapath_dual.svg'

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
W = 3215
R = dict(RegWrite=250, ResultSrc=274, MemWrite=298, ALUControl=322, ALUSrc=346, Jump=370,
         Branch=394, ImmSrc=418, Rd=455, Rs1=480, Rs2=505, RD1=545, RD2=705, Imm=865, PC=892,
         PCPlus4=920)
BT, BB = 235, 935          # barras de pipeline (via 0); la via 1 es el espejo
X_FD, X_DE, X_EM, X_MW = 840, 1500, 2250, 2900
BW = 30
HZ0, HZ1 = M(90), M(45)    # Hazard Unit (espejo de la Issue Unit)


def ginst(x, y, s, anchor='middle'):
    text(x, y, s, FI, anchor, GRAY, italic=True, halo=False)


# =================================================================== FETCH
def fetch():
    # pcmux: s = {PCSrcE, Issue1}; 00 PCPlus4F, 01 PCPlus8F, 1x PCTargetE
    xo, yo, xs, ys = mux(70, (1040, 1150), 36, [(1065, '00'), (1095, '01'), (1125, '1x')], 'top')
    ginst(100, 1172, 'pcmux')
    wire([(xs, ys), (xs, 1012)], 'c')
    rect(70, 1008, 36, 5, stroke=BLUE, sw=0.5, fill=BLUE)
    wire([(76, 1008), (76, 990)], 'c')
    wire([(100, 1008), (100, 990)], 'c')
    tag(76, 990, 'PCSrcE', 'u', 'c')
    tag(100, 990, 'Issue1', 'u', 'c')
    text(67, 1004, '1', 12, 'end', BLUE, halo=False)
    text(110, 1004, '0', 12, 'start', BLUE, halo=False)
    wire([(70, 1125), (54, 1125), (54, 1146)])
    tag(54, 1146, 'PCTargetE', 'd')
    # PCNextF -> pcreg (EN = ~StallF)
    wire([(xo, yo), (190, 1095)])
    lab(116, 1095, 'PCNextF')
    p = regbar(190, 1055, 1135, en=True)
    ginst(186, 1128, 'pcreg', 'end')
    wire([p['en'], (205, 1166)], 'c')
    tag(205, 1166, 'StallF', 'd', 'c')
    # PCF
    wire([(220, 1095), (290, 1095)])
    lab(250, 1095, 'PCF')
    dot(245, 1095)
    wire([(245, 1095), (245, 877), (320, 877)])
    wire([(245, 1095), (245, 1313), (320, 1313)])
    dot(245, 980)
    wire([(245, 980), (570, 980)])
    lab(462, 980, 'PCF')
    # Instruction memory (imem_dual: rd0 = RAM[a], rd1 = RAM[a+4])
    rect(290, 1010, 160, 170)
    text(298, 1095 + 6, 'A', FP, halo=False, layer='block')
    text(444, 1040 + 6, 'RD0', FP, 'end', halo=False, layer='block')
    text(444, 1150 + 6, 'RD1', FP, 'end', halo=False, layer='block')
    text(370, 1092, 'Instruction', 18, 'middle', bold=True, halo=False, layer='block')
    text(370, 1114, 'Memory', 18, 'middle', bold=True, halo=False, layer='block')
    ginst(370, 1198, 'imem (top_dual)')
    # sumadores
    alu_shape(320, 865, 60, 80, plus=True)
    ginst(350, 858, 'pcadd4')
    wire([(300, 933), (320, 933)])
    text(294, 933 + 6, '4', FP, 'end', halo=False)
    alu_shape(320, 1245, 60, 80, plus=True)
    ginst(350, 1342, 'pcadd8')
    wire([(300, 1257), (320, 1257)])
    text(294, 1257 + 6, '8', FP, 'end', halo=False)
    # PCPlus4F
    wire([(380, 905), (640, 905), (640, 1310), (670, 1310)])
    dot(400, 905)
    wire([(400, 905), (400, 825), (40, 825), (40, 1065), (70, 1065)])
    dot(490, 905)
    wire([(490, 905), (490, 950), (570, 950)])
    lab(404, 905, 'PCPlus4F')
    # PCPlus8F
    wire([(380, 1285), (590, 1285), (590, 1360), (670, 1360)])
    dot(400, 1285)
    wire([(400, 1285), (400, 1395), (20, 1395), (20, 1095), (70, 1095)])
    lab(404, 1285, 'PCPlus8F')
    # InstrF0 / InstrF1
    wire([(450, 1040), (570, 1040)])
    lab(476, 1040, 'InstrF0')
    wire([(450, 1150), (610, 1150), (610, 1335), (670, 1335)])
    lab(476, 1150, 'InstrF1')
    # concatenaciones A = {InstrF0, PCF, PCPlus4F}, B = {InstrF1, PCPlus4F, PCPlus8F}
    busbar(570, 940, 1050)
    busbar(670, 1300, 1370)
    wire([(576, 995), (700, 995)], 'b')
    dot(700, 995, 'b')
    wire([(750, 850), (700, 850), (700, 1280), (750, 1280)], 'b')
    wire([(676, 1340), (750, 1340)], 'b')
    for i, t in enumerate(['{InstrF0,', ' PCF,', ' PCPlus4F}']):
        text(708, 1124 + i * 19, t, FS - 1, 'start')
    for i, t in enumerate(['{InstrF1,', ' PCPlus4F,', ' PCPlus8F}']):
        text(612, 1398 + i * 19, t, FS - 1, 'start')
    # fdmux0 / fdmux1 (s = Issue1)
    xo0, yo0, xs0, ys0 = mux(750, (825, 935), 36, [(850, '1'), (910, '0')], 'top')
    wire([(xs0, ys0), (xs0, 812)], 'c')
    tag(xs0, 812, 'Issue1', 'u', 'c')
    xo1, yo1, xs1, ys1 = mux(750, (1255, 1365), 36, [(1280, '0'), (1340, '1')], 'bottom')
    wire([(xs1, ys1), (xs1, 1378)], 'c')
    tag(xs1, 1378, 'Issue1', 'd', 'c')
    ginst(745, 815, 'fdmux0', 'end')
    ginst(745, 1394, 'fdmux1', 'end')
    wire([(xo0, yo0), (840, 880)], 'b')
    lab(794, 877, 'FD0')
    wire([(xo1, yo1), (840, 1310)], 'b')
    lab(794, 1307, 'FD1')
    # C = {InstrD1, PCD1, PCPlus4D1} (salida de fdreg1) -> fdmux0.d0
    dot(893, 1310, 'b')
    wire([(893, 1310), (893, 1040), (725, 1040), (725, 910), (750, 910)], 'b')
    text(735, 1063, '{InstrD1, PCD1,', FS - 1, 'start')
    text(735, 1082, ' PCPlus4D1}', FS - 1, 'start')


# =================================================================== REGISTROS
def bars():
    for v in (0, 1):
        y0, y1 = (BT, BB) if v == 0 else (M(BB), M(BT))
        # F/D: EN = ~StallD, CLR = FlushD
        p = regbar(X_FD, y0, y1, en=True, clr=True, names=[((y0 + y1) / 2, 'fdreg%d' % v)])
        ex, ey = p['en']
        cx, cy = p['clr']
        if v == 0:
            wire([(ex, ey), (ex, 960), (836, 960)], 'c')
            tag(836, 960, 'StallD', 'l', 'c')
            wire([(cx, cy), (cx, 990), (874, 990)], 'c')
            tag(874, 990, 'FlushD', 'r', 'c')
        else:
            wire([(ex, ey), (ex, HZ0)], 'c')
            vtag_text(ex - 5, HZ0 - 8, 'StallD')
            wire([(cx, cy), (cx, HZ0)], 'c')
            vtag_text(cx + 17, HZ0 - 8, 'FlushD')
        dv = Y(v, 436)
        # D/E: CLR = FlushE0 / FlushE1
        p = regbar(X_DE, y0, y1, clr=True, dividers=[dv],
                   names=[(Y(v, 336), 'controlereg%d' % v), (Y(v, 690), 'dereg%d' % v)])
        cx, cy = p['clr']
        if v == 0:
            wire([(cx, cy), (cx, 950)], 'c')
            tag(cx, 950, 'FlushE0', 'd', 'c')
        else:
            wire([(cx, cy), (cx, HZ0)], 'c')
            vtag_text(cx + 17, HZ0 - 8, 'FlushE1')
        # E/M: via 0 flopr, via 1 CLR = FlushM1
        p = regbar(X_EM, y0, y1, clr=(v == 1), dividers=[dv],
                   names=[(Y(v, 336), 'controlmreg%d' % v), (Y(v, 690), 'emreg%d' % v)])
        if v == 1:
            cx, cy = p['clr']
            wire([(cx, cy), (cx, HZ0)], 'c')
            vtag_text(cx + 17, HZ0 - 8, 'FlushM1')
        # M/W: flopr
        regbar(X_MW, y0, y1, dividers=[dv],
               names=[(Y(v, 336), 'controlwreg%d' % v), (Y(v, 690), 'mwreg%d' % v)])


# =================================================================== DECODE
def decode(v):
    y = lambda q: Y(v, q)
    s = str(v)
    wire([(X_FD + BW, y(880)), (915, y(880))], 'b')
    busbar(915, min(y(838), y(928)), max(y(838), y(928)))
    # InstrD
    wire([(921, y(845)), (950, y(845)), (950, y(370))])
    text(956, y(780) + 6, 'InstrD' + s, FS)
    # PCD / PCPlus4D
    wire([(921, y(R['PC'])), (X_DE, y(R['PC']))])
    wire([(921, y(R['PCPlus4'])), (X_DE, y(R['PCPlus4']))])
    lab(1255, y(R['PC']), 'PCD' + s, v=v)
    lab(1255, y(R['PCPlus4']), 'PCPlus4D' + s, v=v)
    # Control Unit (controller c0/c1 de riscvdual.v)
    cu0, cu1 = y(238), y(440)
    top = min(cu0, cu1)
    rect(1030, top, 100, abs(cu1 - cu0), stroke=BLUE, sw=2.2, rx=14)
    ty = top + 30 if v == 0 else top + 140
    text(1080, ty, 'Control', 18, 'middle', BLUE, bold=True, halo=False, layer='block')
    text(1080, ty + 21, 'Unit', 18, 'middle', BLUE, bold=True, halo=False, layer='block')
    text(1080, ty + 44, 'c%d' % v, FI, 'middle', GRAY, italic=True, halo=False, layer='block')
    for q, pn, bits in ((370, 'op', '6:0'), (395, 'funct3', '14:12'), (420, 'funct7b5', '30')):
        wire([(950, y(q)), (1030, y(q))])
        text(1036, y(q) + 6, pn, 15, 'start', BLACK, halo=False, layer='block')
        text(956, y(q) + (-4 if v == 0 else 15), bits, FB)
        if q != 370:
            dot(950, y(q))
    for k in ('RegWrite', 'ResultSrc', 'MemWrite', 'ALUControl', 'ALUSrc', 'Jump', 'Branch'):
        wire([(1130, y(R[k])), (X_DE, y(R[k]))], 'c')
        lab(1136, y(R[k]), k + 'D' + s, 'c', v=v)
    ext_edge = lambda xx: y(815) + (y(800) - y(815)) * ((xx - 1030) / 140.0)
    wire([(1130, y(R['ImmSrc'])), (1155, y(R['ImmSrc'])), (1155, ext_edge(1155))], 'c')
    lab(1136, y(R['ImmSrc']), 'ImmSrcD' + s, 'c', v=v)
    # Rd
    dot(950, y(R['Rd']))
    wire([(950, y(R['Rd'])), (X_DE, y(R['Rd']))])
    text(956, y(R['Rd']) + (-4 if v == 0 else 15), '11:7', FB)
    lab(1166, y(R['Rd']), 'RdD' + s, v=v)
    # Rs Sel: Rs1D = (op==jal) ? 0 : Instr[19:15]; Rs2D = (R|sw|beq) ? Instr[24:20] : 0
    rs0, rs1 = y(466), y(546)
    rect(1010, min(rs0, rs1), 80, abs(rs1 - rs0), sw=2.2)
    text(1050, (rs0 + rs1) / 2 - 3, 'Rs', 16, 'middle', bold=True, halo=False, layer='block')
    text(1050, (rs0 + rs1) / 2 + 15, 'Sel', 16, 'middle', bold=True, halo=False, layer='block')
    for q, bits in ((480, '19:15'), (505, '24:20'), (530, '6:0')):
        dot(950, y(q))
        wire([(950, y(q)), (1010, y(q))])
        text(956, y(q) + (-4 if v == 0 else 15), bits, FB)
    wire([(1090, y(R['Rs1'])), (X_DE, y(R['Rs1']))])
    wire([(1090, y(R['Rs2'])), (X_DE, y(R['Rs2']))])
    lab(1100, y(R['Rs1']), 'Rs1D' + s, v=v)
    lab(1100, y(R['Rs2']), 'Rs2D' + s, v=v)
    a_hi, a_lo = y(975), y(1000)
    dot(1205, y(R['Rs1']))
    wire([(1205, y(R['Rs1'])), (1205, a_hi), (1230, a_hi)])
    dot(1190, y(R['Rs2']))
    wire([(1190, y(R['Rs2'])), (1190, a_lo), (1230, a_lo)])
    # Extend
    poly([(1030, y(815)), (1170, y(800)), (1170, y(855)), (1030, y(855))])
    text(1102, y(835) + 7, 'Extend', 17, 'middle', bold=True, halo=False, layer='block')
    ginst(1100, y(855) + (20 if v == 0 else -9), 'ext%d' % v)
    dot(950, y(835))
    wire([(950, y(835)), (1030, y(835))])
    text(956, y(835) + (-4 if v == 0 else 15), '31:7', FB)
    wire([(1170, y(835)), (1480, y(835)), (1480, y(R['Imm'])), (X_DE, y(R['Imm']))])
    lab(1262, y(835), 'ImmExtD' + s, v=v)
    # lecturas del Register File -> D/E
    rdn = ('RD1D', 'RD2D') if v == 0 else ('RD4D', 'RD5D')
    wire([(1410, a_hi), (1420, a_hi), (1420, y(R['RD1'])), (X_DE, y(R['RD1']))])
    wire([(1410, a_lo), (1442, a_lo), (1442, y(R['RD2'])), (X_DE, y(R['RD2']))])
    lab(1447, y(R['RD1']), rdn[0], v=v)
    lab(1450, y(R['RD2']), rdn[1], v=v)


def regfile():
    x0, y0, x1, y1 = 1230, 955, 1410, 1235
    rect(x0, y0, x1 - x0, y1 - y0)
    cx = 1262            # reloj invertido: escribe en el flanco de bajada
    poly([(cx - 10, y0), (cx + 10, y0), (cx, y0 + 12)], sw=2)
    L['block'].append('<circle cx="%s" cy="%s" r="5" fill="#fff" stroke="#000" stroke-width="2"/>'
                      % (cx, y0 - 5))
    text(cx + 10, y0 - 6, 'CLK', 15, 'start', halo=False, layer='block')
    left = [(975, 'A1'), (1000, 'A2'), (1025, 'WE3'), (1050, 'A3'), (1075, 'WD3'),
            (M(1075), 'WD6'), (M(1050), 'A6'), (M(1025), 'WE6'), (M(1000), 'A5'), (M(975), 'A4')]
    for yy, pn in left:
        text(x0 + 6, yy + 6, pn, FP, halo=False, layer='block')
    for yy, pn in ((975, 'RD1'), (1000, 'RD2'), (M(1000), 'RD5'), (M(975), 'RD4')):
        text(x1 - 6, yy + 6, pn, FP, 'end', halo=False, layer='block')
    text(1334, 1090, 'Register', 18, 'middle', bold=True, halo=False, layer='block')
    text(1334, 1112, 'File', 18, 'middle', bold=True, halo=False, layer='block')
    text(1334, 1138, 'rf', FI, 'middle', GRAY, italic=True, halo=False, layer='block')
    for yy, nm, kd in ((1025, 'RegWriteW0', 'c'), (1050, 'RdW0', 'd'), (1075, 'ResultW0', 'd'),
                       (M(1075), 'ResultW1', 'd'), (M(1050), 'RdW1', 'd'), (M(1025), 'RegWriteW1', 'c')):
        wire([(x0, yy), (x0 - 14, yy)], kd)
        tag(x0 - 14, yy, nm, 'l', kd)


def issue_unit():
    x0, x1, y0, y1 = 890, 1500, 45, 90
    rect(x0, y0, x1 - x0, y1 - y0, stroke=BLUE, sw=2.2, rx=16)
    text((x0 + x1) / 2, y0 + 29, 'Issue Unit', 18, 'middle', BLUE, bold=True, halo=False,
         layer='block')
    ginst(x0 - 8, y0 + 28, 'iu', 'end')
    ins = ['Rs1D0', 'Rs2D0', 'RdD0', 'RegWriteD0', 'MemWriteD0', 'ResultSrcD0[0]', 'BranchD0',
           'JumpD0', 'Rs1D1', 'Rs2D1', 'MemWriteD1', 'ResultSrcD1[0]', 'BranchD1', 'JumpD1',
           'RdE0', 'RdE1', 'ResultSrcE0[0]', 'ResultSrcE1[0]']
    outs = ['Issue0', 'Issue1']
    for i, nm in enumerate(ins + outs):
        x = 905 + i * 29.5 + (20 if i >= len(ins) else 0)
        wire([(x, y1), (x, y1 + 10)], 'c')
        tag(x, y1 + 10, nm, 'd', 'c')
    text(905, y1 - 6, 'entradas', 12.5, 'start', GRAY, halo=False, layer='block')
    text(1471, y1 - 6, 'salidas', 12.5, 'middle', GRAY, halo=False, layer='block')


# =================================================================== EXECUTE
AX, AY0, AH, AW = 2040, 556, 257, 60     # ALU (via 0)


def execute(v):
    y = lambda q: Y(v, q)
    s = str(v)
    xr = X_DE + BW
    for k in ('RegWrite', 'ResultSrc', 'MemWrite'):
        wire([(xr, y(R[k])), (X_EM, y(R[k]))], 'c')
        lab(1612, y(R[k]), k + 'E' + s, 'c', v=v)
    top_at = lambda xx: AY0 + 0.2 * AH * (xx - AX) / AW
    xac = AX + 30
    wire([(xr, y(R['ALUControl'])), (xac, y(R['ALUControl'])), (xac, y(top_at(xac)))], 'c')
    lab(1612, y(R['ALUControl']), 'ALUControlE' + s, 'c', v=v)
    # srcbmux (x 1935..1965), select en x 1950
    wire([(xr, y(R['ALUSrc'])), (1950, y(R['ALUSrc'])), (1950, y(740))], 'c')
    lab(1612, y(R['ALUSrc']), 'ALUSrcE' + s, 'c', v=v)
    # Branch / Jump / PC / ImmExt bajan al recurso de saltos
    wire([(xr, y(R['Branch'])), (1548, y(R['Branch'])), (1548, y(1056)), (1720, y(1056))], 'c')
    wire([(xr, y(R['Jump'])), (1563, y(R['Jump'])), (1563, y(1032)), (1720, y(1032))], 'c')
    wire([(xr, y(R['PC'])), (1578, y(R['PC'])), (1578, y(1008)), (1720, y(1008))])
    dot(1593, y(R['Imm']))
    wire([(1593, y(R['Imm'])), (1593, y(984)), (1720, y(984))])
    lab(1612, y(1056), 'BranchE' + s, 'c', v=v)
    lab(1612, y(1032), 'JumpE' + s, 'c', v=v)
    lab(1612, y(1008), 'PCE' + s, v=v)
    lab(1612, y(984), 'ImmExtE' + s, v=v)
    # Rd
    wire([(xr, y(R['Rd'])), (X_EM, y(R['Rd']))])
    lab(1700, y(R['Rd']), 'RdE' + s, v=v)
    # Rs1E / Rs2E -> Hazard Unit
    for k in ('Rs1', 'Rs2'):
        wire([(xr, y(R[k])), (1612, y(R[k]))])
        tag(1612, y(R[k]), k + 'E' + s, 'r')
    fw = ('ResultW0', 'ResultW1', 'ALUResultM0', 'ALUResultM1')
    rdn = ('RD1E', 'RD2E') if v == 0 else ('RD4E', 'RD5E')
    sel = 'top' if v == 0 else 'bottom'
    # forwardaemux
    ins = [(545, '000'), (570, '001'), (595, '010'), (620, '011'), (645, '100')]
    ya = tuple(sorted((y(522), y(664))))
    xo, yo, xs, ysl = mux(1720, ya, 38, [(y(q), l) for q, l in ins], sel, slant=6)
    wire([(xr, y(545)), (1720, y(545))])
    lab(1640, y(545), rdn[0], v=v)
    for (q, _), nm in zip(ins[1:], fw):
        wire([(1720, y(q)), (1708, y(q))])
        tag(1708, y(q), nm, 'l')
    yt = y(516)
    wire([(xs, ysl), (xs, yt), (1752, yt)], 'c')
    tag(1752, yt, 'ForwardAE' + s, 'r', 'c')
    ginst(1764, y(642) + (0 if v == 0 else 10), 'forwardaemux' + s, 'start')
    # forwardbemux
    insb = [(705, '000'), (730, '001'), (755, '010'), (780, '011'), (805, '100')]
    yb = tuple(sorted((y(692), y(826))))
    xob, yob, xsb, yslb = mux(1820, yb, 38, [(y(q), l) for q, l in insb], sel, slant=6)
    wire([(xr, y(705)), (1820, y(705))])
    lab(1640, y(705), rdn[1], v=v)
    for (q, _), nm in zip(insb[1:], fw):
        wire([(1820, y(q)), (1808, y(q))])
        tag(1808, y(q), nm, 'l')
    ytb = y(678)
    wire([(xsb, yslb), (xsb, ytb), (1826, ytb)], 'c')
    tag(1826, ytb, 'ForwardBE' + s, 'l', 'c')
    ginst(1765, y(838) + (0 if v == 0 else 10), 'forwardbemux' + s)
    # srcbmux
    ysb = tuple(sorted((y(735), y(815))))
    xos, yos, xss, ysls = mux(1935, ysb, 30, [(y(755), '0'), (y(795), '1')], sel, slant=10)
    ginst(1940, y(724) + (0 if v == 0 else 10), 'srcbmux' + s, 'end')
    # WriteDataE
    wire([(xob, y(755)), (1935, y(755))])
    dot(1885, y(755))
    wire([(1885, y(755)), (1885, y(840)), (X_EM, y(840))])
    lab(2130, y(840), 'WriteDataE' + s, v=v)
    # ImmExtE -> srcbmux.1
    wire([(1593, y(R['Imm'])), (1918, y(R['Imm'])), (1918, y(795)), (1935, y(795))])
    lab(1720, y(R['Imm']), 'ImmExtE' + s, v=v)
    # PCPlus4E
    wire([(xr, y(R['PCPlus4'])), (X_EM, y(R['PCPlus4']))])
    lab(2130, y(R['PCPlus4']), 'PCPlus4E' + s, v=v)
    # ALU
    wire([(xo, y(595)), (AX, y(595))])
    lab(1800, y(595), 'SrcAE' + s, v=v)
    wire([(xos, y(775)), (AX, y(775))])
    lab(1968, y(775), 'SrcBE' + s, v=v)
    ay0 = y(AY0) if v == 0 else M(AY0 + AH)
    alu_shape(AX, ay0, AW, AH)
    text(AX + 5, y(595) + 5, 'A', 13, 'start', halo=False, layer='block')
    text(AX + 5, y(775) + 5, 'B', 13, 'start', halo=False, layer='block')
    ycen = y(AY0 + AH / 2)
    wire([(AX + AW, ycen), (X_EM, ycen)])
    lab(2130, ycen, 'ALUResultE' + s, v=v)
    yz = y(AY0 + 0.74 * AH)
    wire([(AX + AW, yz), (2120, yz), (2120, y(940)), (1705, y(940)), (1705, y(960)), (1720, y(960))])
    lab(1770, y(940), 'ZeroE' + s, v=1 - v)
    ginst(AX + 30, y(AY0 + AH) + (18 if v == 0 else -8), 'alu' + s)


def branch_unit():
    # fusiones {BranchEv, JumpEv, ZeroEv, PCEv, ImmExtEv}
    busbar(1720, 950, 1066)
    busbar(1720, M(1066), M(950))
    xo, yo, xs, ys = mux(1780, (1026, 1164), 36, [(1056, '0'), (1134, '1')], 'bottom')
    wire([(1726, 1056), (1780, 1056)], 'b')
    wire([(1726, 1134), (1780, 1134)], 'b')
    ginst(1798, 1018, 'branchmux')
    wire([(xs, ys), (xs, 1202), (1812, 1202)], 'c')
    tag(1812, 1202, 'BranchSelE', 'r', 'c')
    # separador {BranchE, JumpE, ZeroE, BranchPCE, BranchImmE}
    wire([(xo, yo), (1850, 1095)], 'b')
    busbar(1850, 1030, 1182)
    # PCSrcE = (BranchE & ZeroE) | JumpE
    ax, ay = and_gate(1960, 1030, 48)
    wire([(1856, 1040), (1960, 1040)], 'c')
    wire([(1856, 1068), (1960, 1068)], 'c')
    lab(1862, 1040, 'BranchE', 'c')
    lab(1862, 1068, 'ZeroE', 'c')
    oy0, oh = 1044, 60
    ox2, oy2 = or_gate(2025, oy0, oh)
    wire([(ax, ay), (or_in_x(2025, oy0, oh, ay) + 1, ay)], 'c')
    wire([(1856, 1092), (or_in_x(2025, oy0, oh, 1092) + 1, 1092)], 'c')
    lab(1862, 1092, 'JumpE', 'c')
    wire([(ox2, oy2), (2108, oy2)], 'c')
    tag(2108, oy2, 'PCSrcE', 'r', 'c')
    # pcaddbranch: PCTargetE = BranchPCE + BranchImmE
    alu_shape(1972, 1109, 60, 74, plus=True)        # a=1120 b=1172 out=1146
    wire([(1856, 1120), (1972, 1120)])
    lab(1862, 1120, 'BranchPCE')
    wire([(1856, 1172), (1972, 1172)])
    lab(1862, 1172, 'BranchImmE')
    wire([(2032, 1146), (2050, 1146)])
    tag(2050, 1146, 'PCTargetE', 'r')
    ginst(2005, 1202, 'pcaddbranch')


def branchsel():
    """BranchSelE = BranchE1 | JumpE1, en la franja de control de la via 1."""
    yb, yj = M(R['Branch']), M(R['Jump'])     # 1796? (espejo)
    oy0, oh = yb - 12, (yj + 12) - (yb - 12)
    # BranchE1 sigue a la derecha despues de subir (bifurcacion en 1548)
    dot(1548, yb, 'c')
    wire([(1548, yb), (1625, yb)], 'c')
    dot(1563, yj, 'c')
    wire([(1563, yj), (1625, yj)], 'c')
    ox, oy = or_gate(1625, oy0, oh)
    wire([(ox, oy), (ox + 12, oy)], 'c')
    tag(ox + 12, oy, 'BranchSelE', 'r', 'c')


# =================================================================== MEMORY
MX = dict(wd=2300, alu=2315, merge=2420, mux=2470, split=2535, dm0=2640, dm1=2780, rdj=2884,
          or0=2555, mwdesc=2525)


def memory(v):
    y = lambda q: Y(v, q)
    s = str(v)
    xr = X_EM + BW
    for k in ('RegWrite', 'ResultSrc'):
        wire([(xr, y(R[k])), (X_MW, y(R[k]))], 'c')
        lab(2287, y(R[k]), k + 'M' + s, 'c', v=v)
    lab(2287, y(R['MemWrite']), 'MemWriteM' + s, 'c', v=v)
    wire([(xr, y(R['Rd'])), (X_MW, y(R['Rd']))])
    lab(2287, y(R['Rd']), 'RdM' + s, v=v)
    ya = y(684)
    wire([(xr, ya), (X_MW, ya)])
    lab(2330, ya, 'ALUResultM' + s, v=v)
    wire([(xr, y(840)), (MX['wd'], y(840)), (MX['wd'], y(1025)), (MX['merge'], y(1025))])
    lab(2310, y(1025), 'WriteDataM' + s, v=v)
    dot(MX['alu'], ya)
    wire([(MX['alu'], ya), (MX['alu'], y(985)), (MX['merge'], y(985))])
    lab(2319, y(985), 'ALUResultM' + s, v=v)
    wire([(xr, y(R['PCPlus4'])), (X_MW, y(R['PCPlus4']))])
    lab(2545, y(R['PCPlus4']), 'PCPlus4M' + s, v=v)
    busbar(MX['merge'], min(y(975), y(1050)), max(y(975), y(1050)))
    wire([(MX['merge'] + 6, y(1040)), (MX['mux'], y(1040))], 'b')


def memory_shared():
    xr = X_EM + BW
    # MemWriteM = MemWriteM0 | MemWriteM1
    oy0, oh = 950, 44
    wire([(xr, R['MemWrite']), (MX['mwdesc'], R['MemWrite']), (MX['mwdesc'], 960),
          (or_in_x(MX['or0'], oy0, oh, 960) + 1, 960)], 'c')
    ox, oy = or_gate(MX['or0'], oy0, oh)
    text(MX['mwdesc'] - 6, 948, 'MemWriteM0', FS, 'end', BLUE)
    wire([(or_in_x(MX['or0'], oy0, oh, 984) + 1, 984), (MX['or0'] - 12, 984)], 'c')
    tag(MX['or0'] - 12, 984, 'MemWriteM1', 'l', 'c')
    xwe = MX['dm1'] - 32
    wire([(ox, oy), (xwe, oy), (xwe, 1020)], 'c')
    lab(ox + 8, oy, 'MemWriteM', 'c')
    # memmux (s = MemSelM)
    xo, yo, xs, ys = mux(MX['mux'], (1010, 1180), 36, [(1040, '0'), (1150, '1')], 'bottom')
    ginst(MX['mux'] + 42, 1196, 'memmux', 'start')
    wire([(xo, yo), (MX['split'], 1095)], 'b')
    busbar(MX['split'], 1063, 1127)
    wire([(MX['split'] + 6, 1075), (MX['dm0'], 1075)])
    lab(MX['split'] + 10, 1075, 'DataAdrM')
    wire([(MX['split'] + 6, 1115), (MX['dm0'], 1115)])
    lab(MX['split'] + 9, 1115, 'WriteDataM')
    # MemSelM = MemWriteM1 | ResultSrcM1[0]
    ym, yr = M(R['MemWrite']), M(R['ResultSrc'])
    oy0, oh = 1798, 48
    xor_ = 2420
    wire([(xr, ym), (2385, ym), (2385, 1810), (or_in_x(xor_, oy0, oh, 1810) + 1, 1810)], 'c')
    dot(2402, yr, 'c')
    wire([(2402, yr), (2402, 1834), (or_in_x(xor_, oy0, oh, 1834) + 1, 1834)], 'c')
    text(2408, 1872, 'ResultSrcM1[0]', FS, 'start', BLUE)
    ox, oy = or_gate(xor_, oy0, oh)
    wire([(ox, oy), (xs, oy), (xs, ys)], 'c')
    text(xs + 6, 1560, 'MemSelM', FS, 'start', BLUE)
    text(xs + 6, 1242, 'MemSelM', FS, 'start', BLUE)
    # Data Memory (dmem de top_dual)
    x0, y0, x1, y1 = MX['dm0'], 1020, MX['dm1'], 1170
    rect(x0, y0, x1 - x0, y1 - y0)
    cx = x0 + 26
    poly([(cx - 10, y0), (cx + 10, y0), (cx, y0 + 12)], sw=2)
    L['block'].append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#000" stroke-width="2"/>'
                      % (cx, y0 - 14, cx, y0))
    text(cx, y0 - 18, 'CLK', 15, 'middle', halo=False, layer='block')
    text(xwe, y0 + 22, 'WE', FP, 'middle', halo=False, layer='block')
    text(x0 + 6, 1075 + 6, 'A', FP, halo=False, layer='block')
    text(x0 + 6, 1115 + 6, 'WD', FP, halo=False, layer='block')
    text(x1 - 6, 1075 + 6, 'RD', FP, 'end', halo=False, layer='block')
    text((x0 + x1) / 2 + 8, 1118, 'Data', 18, 'middle', bold=True, halo=False, layer='block')
    text((x0 + x1) / 2 + 8, 1140, 'Memory', 18, 'middle', bold=True, halo=False, layer='block')
    ginst((x0 + x1) / 2, 1192, 'dmem (top_dual)')
    # ReadDataM -> mwreg0 y mwreg1
    j = MX['rdj']
    wire([(x1, 1075), (j, 1075)])
    lab(x1 + 4, 1075, 'ReadDataM')
    dot(j, 1075)
    wire([(j, 1075), (j, 800), (X_MW, 800)])
    wire([(j, 1075), (j, M(800)), (X_MW, M(800))])


# =================================================================== WRITEBACK
def writeback(v):
    y = lambda q: Y(v, q)
    s = str(v)
    xr = X_MW + BW
    wire([(xr, y(R['RegWrite'])), (xr + 12, y(R['RegWrite']))], 'c')
    tag(xr + 12, y(R['RegWrite']), 'RegWriteW' + s, 'r', 'c')
    wire([(xr, y(R['Rd'])), (xr + 12, y(R['Rd']))])
    tag(xr + 12, y(R['Rd']), 'RdW' + s, 'r')
    mx = xr + 132
    ins = [(710, '00'), (740, '01'), (770, '10')]
    ym = tuple(sorted((y(690), y(790))))
    xo, yo, xs, ys = mux(mx, ym, 36, [(y(q), l) for q, l in ins], 'top' if v == 0 else 'bottom')
    wire([(xr, y(R['ResultSrc'])), (xs, y(R['ResultSrc'])), (xs, ys)], 'c')
    text(xs + 6, y(560) + 6, 'ResultSrcW' + s, FS, 'start', BLUE)
    wire([(xr, y(684)), (xr + 92, y(684)), (xr + 92, y(710)), (mx, y(710))])
    lab(xr + 6, y(684), 'ALUResultW' + s, v=v)
    wire([(xr, y(800)), (xr + 110, y(800)), (xr + 110, y(740)), (mx, y(740))])
    lab(xr + 4, y(800), 'ReadDataW' + s, v=v)
    wire([(xr, y(R['PCPlus4'])), (xr + 121, y(R['PCPlus4'])), (xr + 121, y(770)), (mx, y(770))])
    lab(xr + 6, y(R['PCPlus4']), 'PCPlus4W' + s, v=v)
    wire([(xo, yo), (xo + 14, yo)])
    tag(xo + 14, yo, 'ResultW' + s, 'r')
    ginst(mx + 40, y(790) + (24 if v == 0 else -16), 'resultmux' + s, 'start')


# =================================================================== HAZARD UNIT
def hazard_unit():
    x0, x1 = 40, W - 30
    rect(x0, HZ0, x1 - x0, HZ1 - HZ0, stroke=BLUE, sw=2.2, rx=16)
    text(1240, HZ0 + 30, 'Hazard Unit', 18, 'middle', BLUE, bold=True, halo=False, layer='block')
    ginst(x0 + 14, HZ0 + 28, 'hu', 'start')
    groups = [
        (205, ['StallF']),
        (965, ['Issue0', 'Issue1']),
        (1440, ['FlushE0']),
        (1640, ['Rs1E0', 'Rs2E0', 'Rs1E1', 'Rs2E1']),
        (1790, ['ForwardAE0', 'ForwardBE0', 'ForwardAE1', 'ForwardBE1']),
        (1940, ['PCSrcE', 'BranchSelE']),
        (2560, ['RdM0', 'RdM1', 'RegWriteM0', 'RegWriteM1']),
        (3000, ['RdW0', 'RdW1', 'RegWriteW0', 'RegWriteW1']),
    ]
    for x, names in groups:
        for i, nm in enumerate(names):
            xx = x + i * 30
            wire([(xx, HZ0), (xx, HZ0 - 10)], 'c')
            tag(xx, HZ0 - 10, nm, 'u', 'c')
        out = names[0].startswith(('Stall', 'Flush', 'Forward'))
        xm = x + (len(names) - 1) * 15
        text(xm, HZ0 + 15, ('salida' if out else 'entrada') + ('s' if len(names) > 1 else ''),
             12.5, 'middle', GRAY, halo=False, layer='block')
    for xm, t in ((859, 'salidas'), (X_DE + 15, 'salida'), (X_EM + 15, 'salida')):
        text(xm, HZ0 + 15, t, 12.5, 'middle', GRAY, halo=False, layer='block')


# =================================================================== MARCO
def frame():
    for x, t in ((420, 'Fetch'), (1180, 'Decode'), (1890, 'Execute'), (2570, 'Memory'),
                 (3040, 'Writeback')):
        text(x, 28, t, 20, 'middle', '#4a4a4a', bold=True, halo=False)
    text(16, 590, 'Vía 0', 19, 'middle', '#4a4a4a', bold=True, rot=-90, halo=False)
    text(16, M(590), 'Vía 1', 19, 'middle', '#4a4a4a', bold=True, rot=-90, halo=False)


def legend():
    x, y = 40, 70
    rect(x, y, 680, 240, stroke='#9a9a9a', sw=1, rx=6, fill='none', layer='tint')
    text(x + 12, y + 24, 'Convenciones', 16, 'start', '#4a4a4a', bold=True, halo=False)
    tag(x + 14, y + 52, 'Nombre', 'r')
    text(x + 108, y + 58, 'etiqueta de red: une el cable con el que lleva ese nombre', 15, halo=False)
    wire([(x + 14, y + 86), (x + 92, y + 86)], 'b')
    text(x + 108, y + 92, 'bus agrupado {a, b, c} (concatenación del Verilog)', 15, halo=False)
    busbar(x + 50, y + 104, y + 140)
    text(x + 108, y + 128, 'barra de concatenación / separación de un bus', 15, halo=False)
    text(x + 12, y + 172, 'Vía 0 = 1.ª instrucción del par (más antigua); vía 1 = 2.ª. Azul: control y Hazard/Issue Unit.',
         14, 'start', '#4a4a4a', halo=False)
    text(x + 12, y + 196, 'X[0] es el bit 0 de la señal X.', 14, 'start', '#4a4a4a', halo=False)
    text(x + 12, y + 220, 'En la vía 1 el dibujo está espejado: el nombre va debajo de su cable.', 14,
         'start', '#4a4a4a', halo=False)


def build():
    frame()
    legend()
    fetch()
    bars()
    for v in (0, 1):
        decode(v)
        execute(v)
        memory(v)
        writeback(v)
    regfile()
    issue_unit()
    branch_unit()
    branchsel()
    memory_shared()
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
