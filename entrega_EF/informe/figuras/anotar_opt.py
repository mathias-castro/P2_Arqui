# Anota los detalles del datapath optimizado (numeros y recuadros de colores) para el informe.
from PIL import Image, ImageDraw, ImageFont
FB = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 40)
NAR = (230, 110, 0); ROJ = (200, 30, 30); VER = (30, 140, 60); AZ = (21, 101, 192)

def numero(d, x, y, n, col=NAR):
    r = 30
    d.ellipse((x - r, y - r, x + r, y + r), fill=col)
    w = d.textlength(str(n), font=FB)
    d.text((x - w / 2, y - 24), str(n), font=FB, fill=(255, 255, 255))

im = Image.open('detalle_fetch_opt.png').convert('RGB'); d = ImageDraw.Draw(im)
for n, (x, y) in enumerate([(1205, 412), (262, 1130), (520, 1196), (790, 1260), (1690, 1450), (2185, 1352)], 1):
    numero(d, x, y, n)
im.save('detalle_fetch_opt_anot.png')

im = Image.open('detalle_branch_opt.png').convert('RGB'); d = ImageDraw.Draw(im)
for n, (x, y) in enumerate([(1180, 160), (1655, 140), (1345, 372)], 1):
    numero(d, x, y, n)
im.save('detalle_branch_opt_anot.png')
