# capturar.py: capturas de waveforms de Vivado (xsim)

Genera un PNG del visor de ondas de Vivado 2025.2 (fondo negro, ondas verdes,
columnas Name/Value, regla de tiempo) sin intervención humana y sin abrir nada
en tu pantalla.

```
python3 capturar.py spec.json            # imprime la ruta del PNG
python3 capturar.py spec.json -v         # con progreso
python3 capturar.py spec.json --keep     # conserva los archivos de trabajo (depuración)
```

Salida: `out` (recortado al panel de ondas) y `<out>_full.png` (captura completa
de la ventana de Vivado, sin anotaciones). Con `--keep` también se escribe
`<out>_debug.json` (geometría y mapeo tiempo→pixel).
Tarda unos 30–45 s por captura. La compilación se cachea.

## Cómo funciona

1. `xvlog`/`xvhdl` + `xelab -debug typical` (con caché por hash de fuentes) y una
   simulación batch que genera `sim.wdb` (`log_wave -r /; run <run>`). Los `.mem` de
   `memdir` se **copian** al directorio de corrida, así `$readmemh("x.mem")` funciona y
   la simulación nunca escribe en tu carpeta. Un `$finish` del testbench no molesta.
2. Levanta `Xephyr` embebido en una ventana **no mapeada** de `:0`, así que no se ve
   nada en pantalla. El número de display lo elige `-displayfd`.
3. Abre `xsim sim.wdb -gui` dentro de ese display con un `HOME` aislado (no toca
   `~/.Xilinx`). Un poller Tcl (`after 150 …`) ejecuta los comandos que el script
   deja en un archivo.
4. Crea las ondas con `add_wave -radix …` / `add_wave_divider` y las guarda en `.wcfg`.
   Maximiza el panel con un click XTEST y ajusta el ancho de la ventana para que el
   recorte mida exactamente `width` px.
5. Calibra el zoom: abre el `.wcfg` con 2 markers nativos y un divisor extra, mide su
   posición en pixeles y corrige `ZoomEndTime` hasta que la ventana visible sea
   exactamente `[t0_ns, t1_ns]` (error ≤ 1 px; converge en unas 3 iteraciones).
6. Reabre el `.wcfg` final, sin markers ni divisor, con el mismo zoom y el cursor
   en `cursor_ns`. Captura, recorta y dibuja `markers`/`boxes` con PIL usando el
   mapeo medido.
7. Al terminar mata Xephyr y xsim (grupo de procesos completo), también si hay error
   o Ctrl-C. Corre una captura a la vez (lock); si lanzas otra, espera.

## Spec (JSON)

```json
{
  "sources": ["/ruta/src/*.v", "/ruta/sim/tb_x.v"],
  "memdir": "/ruta/sim",
  "top": "tb_x",
  "run": "400ns",
  "t0_ns": 0, "t1_ns": 140,
  "width": 1700,
  "cursor_ns": 0,
  "signals": [
    {"divider": "Fetch"},
    {"path": "/tb_x/clk"},
    {"path": "/tb_x/dut/rvdual/dp/PCF", "radix": "hex"},
    {"path": "/tb_x/dut/rvdual/dp/RdW0", "radix": "unsigned", "name": "rd lane0"}
  ],
  "markers": [ {"t_ns": 65, "label": "1"} ],
  "boxes":   [ {"signal": "PCF", "t0_ns": 30, "t1_ns": 40, "label": "A"} ],
  "out": "/ruta/salida.png"
}
```

Obligatorios: `sources`, `top`, `t0_ns`, `t1_ns`, `signals`, `out`.
Las rutas relativas se resuelven respecto al directorio del spec.

| campo | default | descripción |
|---|---|---|
| `sources` | – | globs; `.v` → xvlog, `.sv` → `xvlog --sv`, `.vhd` → xvhdl |
| `memdir` | – | carpeta cuyos archivos se copian al directorio de simulación |
| `run` | `t1+10 ns` | argumento de `run` en la simulación batch (`"400ns"`, `"all"`) |
| `width` | 1600 | ancho exacto del PNG en px |
| `cursor_ns` | `t0_ns` | posición del cursor principal; la columna Value muestra ese instante |
| `scale` | 100 | escala de la UI de Vivado (100/125/150/175/200). 150 da texto más grande y nítido; 200 corta las etiquetas de la regla (bug de Vivado) |
| `show_range` | true | `false` muestra `PCF` en vez de `PCF[31:0]` |
| `name_width`, `value_width` | auto | ancho de las columnas en px lógicos (auto = según texto/radix) |
| `marker_width` | 1×scale | grosor de las líneas de marker |
| `xelab_opts` | [] | opciones extra para xelab |
| `workdir` | /tmp/waves_work_<uid> | dónde van xsim.dir, wdb y logs (también `$WAVES_WORKDIR`) |
| `show` | false | `true` muestra la ventana Xephyr (para depurar) |

`signals[]`: `{"path", "radix"?, "name"?}` o `{"divider": "texto"}`. `radix`:
`bin`, `hex`, `oct`, `dec` (con signo), `unsigned`, `ascii`. `name` renombra la fila
(igual que *Rename* en la GUI).

`markers[]`: `{"t_ns", "label"?, "color"? [r,g,b]}`. Línea vertical cian (por defecto)
con un círculo numerado (o una pastilla si la etiqueta tiene más de 2 caracteres) en
la franja de etiquetas de markers de Vivado, debajo de la del cursor.

`boxes[]`: `{"signal" | "row", "t0_ns", "t1_ns", "label"?, "label_pos"? ("left"|"right"|"top"), "color"?}`.
Rectángulo sin relleno (rosa por defecto) que encierra la fila. `signal` acepta la
ruta completa, el nombre corto (`InstrD1` o `InstrD1[31:0]`) o el `name`. Si es
ambiguo, da error; usa entonces la ruta o `"row": índice` (las filas cuentan desde 0
e incluyen los dividers).

## Limitaciones

- Filas: máximo 120 (24 px cada una a escala 100). Con más, error: divide la captura.
- Legibilidad de buses: Vivado escribe el valor dentro de la onda solo si cabe; si no,
  pone `0000...`. A escala 100, el texto de un hex de 8 dígitos mide 55 px y necesita
  unos 70 px de segmento (con 100 px se lee bien y con 62 px ya sale truncado).
  Con `width` 1700 (unos 1400 px de área de ondas) y clk de 10 ns caben como máximo
  unos 200 ns (20 ciclos) para valores que cambian cada ciclo. Regla:
  `ns_max ≈ 10 · (width − ancho_Name − ancho_Value) / 70`. Los valores decimales cortos
  se leen con zooms mucho mayores. Con `scale: 150` multiplica `width` por 1,5 para
  ver el mismo rango.
- Los markers internos de calibración asumen que la resolución
  de la simulación sale en el log ("Time resolution is 1 ps"); es el caso normal.
- Necesita la sesión X de `:0` para embeber Xephyr (sin `:0` el script falla).
- La GUI maximiza el panel con un click en una posición fija del layout por defecto de
  Vivado 2025.2 (el `HOME` aislado garantiza ese layout). Otra versión de Vivado
  podría necesitar ajustar `attempts` en `capture()`.
