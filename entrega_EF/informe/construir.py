#!/usr/bin/env python3
# Junta los fragmentos de fuente/ en informe.html, numera figuras, tablas y codigos,
# y genera el PDF con Chrome.
#   [[FIG:nombre]] [[TAB:nombre]] [[COD:nombre]]  -> definen el numero (en orden de aparicion)
#   [[fig:nombre]] [[tab:nombre]] [[cod:nombre]]  -> referencia a ese numero
import glob, os, re, subprocess, sys

os.chdir(os.path.dirname(os.path.abspath(__file__)))
PDF = "Informe_Final.pdf"

html = "".join(open(f, encoding="utf8").read() for f in sorted(glob.glob("fuente/*.html")))
nums = {}
for tipo in ("FIG", "TAB", "COD"):
    for n, nombre in enumerate(re.findall(r"\[\[%s:(\w+)\]\]" % tipo, html), 1):
        if (tipo, nombre) in nums:
            sys.exit("etiqueta repetida: %s:%s" % (tipo, nombre))
        nums[(tipo, nombre)] = n

def numero(m):
    clave = (m.group(1).upper(), m.group(2))
    if clave not in nums:
        sys.exit("referencia sin definir: %s:%s" % clave)
    return str(nums[clave])

html = re.sub(r"\[\[(FIG|TAB|COD|fig|tab|cod):(\w+)\]\]", numero, html)
open("informe.html", "w", encoding="utf8").write(html)
subprocess.run(["google-chrome", "--headless", "--disable-gpu", "--no-pdf-header-footer",
                "--print-to-pdf=" + PDF, "file://" + os.path.abspath("informe.html")],
               stderr=subprocess.DEVNULL, check=True)
print(PDF, "generado:", len([k for k in nums if k[0] == "FIG"]), "figuras,",
      len([k for k in nums if k[0] == "TAB"]), "tablas,", len([k for k in nums if k[0] == "COD"]), "codigos")
