#!/usr/bin/env python3
# Genera Presentacion_Final.pdf a partir de presentacion.html con Chrome.
import os, subprocess
os.chdir(os.path.dirname(os.path.abspath(__file__)))
subprocess.run(["google-chrome", "--headless", "--disable-gpu", "--no-pdf-header-footer",
                "--print-to-pdf=Presentacion_Final.pdf", "file://" + os.path.abspath("presentacion.html")],
               stderr=subprocess.DEVNULL, check=True)
print("Presentacion_Final.pdf generado")
