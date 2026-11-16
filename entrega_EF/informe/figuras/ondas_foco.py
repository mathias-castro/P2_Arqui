# Recortes de las capturas de Vivado de la seccion 8: solo las filas que importan,
# con las direcciones que hay en cada etapa escritas arriba y los valores clave encerrados.
from PIL import Image, ImageDraw, ImageFont
FM = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 15)
FS = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 15)
FV = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 17)
COL = {'o': (255, 150, 0), 'y': (255, 235, 40), 'r': (255, 70, 70), 'p': (190, 150, 255)}
NOMBRES = ['clk', 'Fetch', 'PCF', 'InstrF0', 'InstrF1', 'PredF0', 'PredF1', 'PredTargetF0', 'PredTargetF1', 'PCNextF',
           'Decode', 'InstrD0', 'InstrD1', 'PredD0', 'PredD1', 'Issue0', 'Issue1',
           'Execute', 'InstrE0', 'InstrE1', 'BranchSelE', 'PredE', 'TakenE', 'MispredE', 'PCCorrectE', 'CntE',
           'FlushD', 'FlushE0', 'FlushE1', 'FlushM1', 'Memory y Writeback', 'InstrM0', 'InstrM1', 'InstrW0', 'InstrW1']
Y = {n: 102 + 37 * i for i, n in enumerate(NOMBRES)}
NAMEW = 246

def hacer(src, t_ini, x_ini, pxns, salida, t0, t1, filas, tiras, cajas):
    img = Image.open(src).convert('RGB')
    x_of = lambda ns: x_ini + (ns - t_ini) * pxns
    cw = 10 * pxns
    xa, xb = int(x_of(t0)) - 2, int(x_of(t1)) + 2
    partes = [(0, 88)] + [(Y[r] - 18, Y[r] + 19) for r in filas]
    top = 10 + 25 * len(tiras)
    out = Image.new('RGB', (NAMEW + xb - xa, top + sum(b - a for a, b in partes)), 'white')
    d = ImageDraw.Draw(out)
    for j, (tit, labs) in enumerate(tiras):
        yy = 6 + 25 * j
        d.text((8, yy), tit, font=FS, fill=(40, 40, 40))
        for i, t in enumerate(labs):
            cx = NAMEW + (x_of(t0 + 10 * i) + x_of(t0 + 10 * i + 10)) / 2 - xa
            d.text((cx - d.textlength(t, font=FM) / 2, yy), t, font=FM,
                   fill=(205, 30, 30) if t.startswith('(') and t.endswith(')') else (21, 101, 192))
    y = top; pos = {}
    for (a, b), r in zip(partes, ['_'] + filas):
        out.paste(img.crop((0, a, NAMEW, b)), (0, y)); out.paste(img.crop((xa, a, xb, b)), (NAMEW, y))
        pos[r] = y; y += b - a
    for r, c, col, val in cajas:
        x0 = NAMEW + x_of(t0 + 10 * c) - xa; yy = pos[r]
        d.rectangle((x0 + 3, yy + 1, x0 + cw - 3, yy + 36), fill=(0, 0, 0), outline=COL[col], width=4)
        d.text((x0 + cw / 2 - d.textlength(val, font=FV) / 2, yy + 9), val, font=FV, fill=(255, 255, 255))
    out.save(salida)

MW = ['Memory y Writeback', 'InstrM0', 'InstrM1', 'InstrW0', 'InstrW1']
# Prueba 1, primeras vueltas
hacer('wave_o1a.png', 50, 412, 17.6, 'wave_o1a_foco.png', 60, 130,
      ['PCF', 'InstrF0', 'InstrF1', 'PredF0', 'PredTargetF0', 'PCNextF', 'Decode', 'InstrD0', 'InstrD1', 'PredD0',
       'Execute', 'InstrE0', 'InstrE1', 'PredE', 'TakenE', 'MispredE', 'FlushD'] + MW,
      [('Fetch:', ['32|36', '40|44', '12|16', '20|24', '24|28', '12|16', '20|24']),
       ('Decode:', ['24|28', '32|36', '(—)|(—)', '12|16', '16|20', '24|(—)', '12|16']),
       ('Execute:', ['16|20', '24|28', '(—)|(—)', '(—)|(—)', '12|(—)', '16|20', '24|(—)'])],
      [('TakenE', 1, 'p', '1'), ('MispredE', 1, 'r', '1'), ('PCNextF', 1, 'y', '12'), ('FlushD', 1, 'r', '1'),
       ('PredF0', 4, 'p', '1'), ('PredTargetF0', 4, 'y', '12'), ('PCNextF', 4, 'y', '12'),
       ('InstrD1', 5, 'r', '00000000'), ('PredD0', 5, 'p', '1'),
       ('PredE', 6, 'p', '1'), ('TakenE', 6, 'p', '1'), ('MispredE', 6, 'o', '0'), ('FlushD', 6, 'o', '0')])
# Prueba 1, ultima vuelta
hacer('wave_o1b.png', 320, 412, 22.6, 'wave_o1b_foco.png', 330, 390,
      ['PCF', 'InstrF0', 'InstrF1', 'PredF0', 'PCNextF', 'Decode', 'InstrD0', 'InstrD1',
       'Execute', 'InstrE0', 'InstrE1', 'PredE', 'TakenE', 'MispredE', 'PCCorrectE', 'CntE', 'FlushD'] + MW,
      [('Fetch:', ['20|24', '24|28', '12|16', '20|24', '28|32', '36|40']),
       ('Decode:', ['12|16', '16|20', '24|(—)', '12|16', '(—)|(—)', '28|32']),
       ('Execute:', ['24|(—)', '12|(—)', '16|20', '24|(—)', '(—)|(—)', '(—)|(—)'])],
      [('PredF0', 1, 'p', '1'), ('PCNextF', 1, 'y', '12'),
       ('PredE', 3, 'p', '1'), ('TakenE', 3, 'p', '0'), ('MispredE', 3, 'r', '1'), ('PCCorrectE', 3, 'y', '28'),
       ('CntE', 3, 'y', '11'), ('PCNextF', 3, 'y', '28'), ('FlushD', 3, 'r', '1'), ('PCF', 4, 'y', '28')])
# Prueba 2, jal en la via 1
hacer('wave_o2.png', 230, 412, 22.6, 'wave_o2_foco.png', 240, 290,
      ['PCF', 'InstrF0', 'InstrF1', 'PredF1', 'PredTargetF1', 'PCNextF', 'Decode', 'InstrD0', 'InstrD1', 'PredD1', 'Issue1',
       'Execute', 'InstrE0', 'InstrE1', 'BranchSelE', 'PredE', 'TakenE', 'MispredE'] + MW,
      [('Fetch:', ['44|48', '52|56', '44|48', '52|56', '44|48']),
       ('Decode:', ['(—)|(—)', '44|48', '52|56', '44|48', '52|56']),
       ('Execute:', ['(—)|(—)', '(—)|(—)', '44|48', '52|56', '44|48'])],
      [('PredF1', 1, 'p', '1'), ('PredTargetF1', 1, 'y', '44'), ('PCNextF', 1, 'y', '44'), ('Issue1', 1, 'p', '1'),
       ('PredD1', 2, 'p', '1'),
       ('BranchSelE', 3, 'p', '1'), ('PredE', 3, 'p', '1'), ('TakenE', 3, 'p', '1'), ('MispredE', 3, 'o', '0')])
