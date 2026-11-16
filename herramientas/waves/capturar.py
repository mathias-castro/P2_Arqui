#!/usr/bin/env python3
"""
capturar.py - Capturas PNG automaticas del visor de waveforms de Vivado (xsim).

Uso:  python3 capturar.py spec.json [--keep] [--verbose]

Flujo:
  1. Compila (xvlog/xvhdl + xelab, con cache) y simula en batch -> sim.wdb
  2. Levanta un Xephyr oculto (servidor X anidado, embebido en una ventana
     no mapeada de :0, asi no aparece nada en la pantalla del usuario).
  3. Abre `xsim sim.wdb -gui` dentro de ese display con un HOME aislado.
     Un "poller" Tcl (after 150 ...) permite mandar comandos Tcl a la GUI.
  4. Crea la lista de ondas con add_wave/add_wave_divider, la guarda como
     .wcfg, maximiza el panel de ondas (un click via XTEST), ajusta el ancho
     de la ventana, y calibra el zoom con markers nativos de Vivado hasta que
     la ventana visible sea exactamente [t0, t1].
  5. Captura, recorta al panel (Name/Value/regla/ondas) y dibuja markers y
     boxes con PIL usando el mapeo tiempo->pixel medido.
Ver README.md.
"""
import glob
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

# --- dependencias: PIL + python-xlib. Si falta Xlib, reejecutar con uv. ---
try:
    from Xlib import X, display as xdisplay
    from Xlib.ext import xtest
    from PIL import Image, ImageDraw, ImageFont, ImageGrab
except ImportError:
    if os.environ.get("_CAPTURAR_REEXEC"):
        raise
    os.environ["_CAPTURAR_REEXEC"] = "1"
    uv = shutil.which("uv") or os.path.expanduser("~/.local/bin/uv")
    os.execvp(uv, [uv, "run", "-q", "--no-project", "--with", "python-xlib",
                   "--with", "pillow", "python3", os.path.abspath(__file__)]
              + sys.argv[1:])

HERE = os.path.dirname(os.path.abspath(__file__))
VIVADO_SETTINGS = os.path.expanduser("~/Xilinx/2025.2/Vivado/settings64.sh")
DEFAULT_WORK = os.path.join(tempfile.gettempdir(), f"waves_work_{os.getuid()}")
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
MAX_ROWS = 120

# colores nativos de Vivado (wv.ini por defecto)
C_MARKER = (0, 128, 255)
C_CURSOR = (255, 255, 0)
C_DIVIDER = (128, 128, 255)

VERBOSE = False


_T0 = time.time()


def log(*a):
    if VERBOSE:
        print(f"[capturar {time.time() - _T0:5.1f}s]", *a, file=sys.stderr, flush=True)


class CapError(Exception):
    pass


# ---------------------------------------------------------------- utilidades
def vivado_env():
    """Entorno de Vivado (settings64.sh) como dict, cacheado."""
    out = subprocess.run(["bash", "-c", f"source '{VIVADO_SETTINGS}' >/dev/null 2>&1; env -0"],
                         capture_output=True, check=True).stdout
    env = {}
    for item in out.split(b"\0"):
        if b"=" in item:
            k, v = item.split(b"=", 1)
            env[k.decode()] = v.decode(errors="replace")
    if not shutil.which("xsim", path=env.get("PATH", "")):
        raise CapError(f"No encuentro xsim tras source {VIVADO_SETTINGS}")
    return env


def run_cmd(cmd, cwd, env, logname, timeout=600):
    with open(os.path.join(cwd, logname), "w") as f:
        p = subprocess.run(cmd, cwd=cwd, env=env, stdout=f, stderr=subprocess.STDOUT,
                           timeout=timeout)
    txt = open(os.path.join(cwd, logname), errors="replace").read()
    if p.returncode != 0:
        raise CapError(f"Fallo {' '.join(cmd[:2])} (ver {os.path.join(cwd, logname)}):\n"
                       + "\n".join(txt.splitlines()[-25:]))
    return txt


def ps(t_ns):
    return int(round(t_ns * 1000))


def fmt_ps(v):
    return f"{int(v):,} ps"


def tcl_q(s):
    return "{" + str(s).replace("}", "\\}").replace("{", "\\{") + "}"


# ---------------------------------------------------------------- spec
def load_spec(path):
    with open(path) as f:
        spec = json.load(f)
    base = os.path.dirname(os.path.abspath(path))

    def absp(p):
        p = os.path.expanduser(p)
        return p if os.path.isabs(p) else os.path.join(base, p)

    for k in ("top", "t0_ns", "t1_ns", "signals", "out"):
        if k not in spec:
            raise CapError(f"Falta el campo obligatorio '{k}' en el spec")
    srcs = []
    for pat in spec.get("sources", []):
        m = sorted(glob.glob(absp(pat)))
        if not m:
            raise CapError(f"El patron de fuentes no encontro archivos: {pat}")
        srcs += m
    if not srcs:
        raise CapError("'sources' esta vacio")
    spec["sources"] = srcs
    spec["memdir"] = absp(spec["memdir"]) if spec.get("memdir") else None
    spec["out"] = absp(spec["out"])
    t0, t1 = float(spec["t0_ns"]), float(spec["t1_ns"])
    if not t1 > t0 >= 0:
        raise CapError("Se requiere 0 <= t0_ns < t1_ns")
    spec["t0_ns"], spec["t1_ns"] = t0, t1
    spec.setdefault("run", f"{t1 + 10:g}ns")
    spec.setdefault("width", 1600)
    spec.setdefault("scale", 100)
    if int(spec["scale"]) not in (100, 125, 150, 175, 200):
        raise CapError("scale debe ser 100, 125, 150, 175 o 200 (porcentaje de Vivado)")
    spec.setdefault("cursor_ns", t0)
    spec.setdefault("markers", [])
    spec.setdefault("boxes", [])
    spec.setdefault("show_range", True)
    rows = []
    for i, s in enumerate(spec["signals"]):
        if "divider" in s:
            rows.append({"kind": "divider", "label": str(s["divider"])})
        elif "path" in s:
            r = {"kind": "signal", "path": s["path"], "radix": s.get("radix"),
                 "name": s.get("name")}
            rows.append(r)
        else:
            raise CapError(f"signals[{i}] necesita 'path' o 'divider'")
    if not rows:
        raise CapError("'signals' esta vacio")
    if len(rows) > MAX_ROWS:
        raise CapError(f"Demasiadas filas ({len(rows)}); maximo {MAX_ROWS}. "
                       "Divide la captura en varias.")
    spec["rows"] = rows
    for b in spec["boxes"]:
        row_index(rows, b.get("row", b.get("signal")))
        if not float(b["t1_ns"]) > float(b["t0_ns"]):
            raise CapError(f"box {b}: t1_ns debe ser > t0_ns")
    for m in spec["markers"]:
        float(m["t_ns"])
    return spec


# ---------------------------------------------------------------- simulacion
def compile_and_sim(spec, work, env):
    h = hashlib.sha1()
    for s in spec["sources"]:
        h.update(s.encode())
        h.update(open(s, "rb").read())
    h.update(spec["top"].encode())
    h.update(json.dumps(spec.get("xelab_opts", [])).encode())
    key = h.hexdigest()[:12]
    cdir = os.path.join(work, f"build_{spec['top']}_{key}")
    os.makedirs(cdir, exist_ok=True)
    snap = "snap"
    if not os.path.exists(os.path.join(cdir, "OK")):
        log("compilando en", cdir)
        v = [s for s in spec["sources"] if s.endswith((".v", ".vh"))]
        sv = [s for s in spec["sources"] if s.endswith((".sv", ".svh"))]
        vhd = [s for s in spec["sources"] if s.endswith((".vhd", ".vhdl"))]
        if v:
            run_cmd(["xvlog"] + v, cdir, env, "xvlog.out")
        if sv:
            run_cmd(["xvlog", "--sv"] + sv, cdir, env, "xvlog_sv.out")
        if vhd:
            run_cmd(["xvhdl"] + vhd, cdir, env, "xvhdl.out")
        run_cmd(["xelab", "-debug", "typical"] + list(spec.get("xelab_opts", []))
                + [spec["top"], "-s", snap], cdir, env, "xelab.out")
        open(os.path.join(cdir, "OK"), "w").close()
    else:
        log("usando compilacion cacheada", cdir)

    # directorio de corrida: snapshot + archivos de memoria
    rdir = tempfile.mkdtemp(prefix="run_", dir=work)
    try:
        os.symlink(os.path.join(cdir, "xsim.dir"), os.path.join(rdir, "xsim.dir"))
        if spec["memdir"]:
            for f in os.listdir(spec["memdir"]):
                src = os.path.join(spec["memdir"], f)
                # se copian (no symlink) para que la simulacion nunca escriba en memdir
                if (os.path.isfile(src) and not os.path.exists(os.path.join(rdir, f))
                        and os.path.getsize(src) < 50 * 2**20):
                    shutil.copy2(src, os.path.join(rdir, f))

        paths = [r["path"] for r in spec["rows"] if r["kind"] == "signal"]
        tcl = ["foreach p {" + " ".join(tcl_q(p) for p in paths) + "} {",
               "  if {[llength [get_objects -quiet $p]] == 0} { puts \"CAP_MISSING $p\" }",
               "}",
               "log_wave -r /",
               f"run {spec['run']}",
               # si el testbench paro con $stop, "run_extra" sigue simulando un poco mas
               *([f"run {spec['run_extra']}"] if spec.get("run_extra") else []),
               "puts \"CAP_END [current_time]\"",
               "quit"]
        with open(os.path.join(rdir, "batch.tcl"), "w") as f:
            f.write("\n".join(tcl) + "\n")
        log("simulando (batch)")
        out = run_cmd(["xsim", snap, "-tclbatch", "batch.tcl", "-wdb", "sim.wdb"], rdir, env,
                      "batch.out")
        missing = re.findall(r"^CAP_MISSING (.*)$", out, re.M)
        if missing:
            raise CapError("Senales inexistentes en el diseno:\n  " + "\n  ".join(missing))
        m = re.search(r"Time resolution is (\d+) (fs|ps|ns|us)", out)
        res_ps = 1.0
        if m:
            res_ps = int(m.group(1)) * {"fs": 1e-3, "ps": 1, "ns": 1e3, "us": 1e6}[m.group(2)]
        m = re.search(r"\$finish called at time : ([\d.]+) (fs|ps|ns|us)", out)
        end_ns = None
        if m:
            end_ns = float(m.group(1)) * {"fs": 1e-6, "ps": 1e-3, "ns": 1, "us": 1e3}[m.group(2)]
        else:
            m = re.search(r"CAP_END ([\d.]+) ?(fs|ps|ns|us)", out)
            if m:
                end_ns = float(m.group(1)) * {"fs": 1e-6, "ps": 1e-3, "ns": 1, "us": 1e3}[m.group(2)]
        if end_ns is not None and end_ns < spec["t1_ns"]:
            print(f"AVISO: la simulacion termina en {end_ns:g} ns (< t1_ns={spec['t1_ns']:g}); "
                  "la parte final de la captura saldra vacia.", file=sys.stderr)
        return rdir, res_ps
    except BaseException:
        if not spec.get("_keep"):
            shutil.rmtree(rdir, ignore_errors=True)
        raise


# ---------------------------------------------------------------- X / GUI
class Session:
    def __init__(self, rdir, env, scr_w, scr_h, scale, hidden=True):
        self.rdir, self.env = rdir, env
        self.scr_w, self.scr_h = scr_w, scr_h
        self.scale = scale
        self.win_w, self.win_h = scr_w, scr_h
        self.procs = []
        self.host = None
        self.d = None
        self.disp = None
        self.hidden = hidden

    # -- arranque
    def start(self):
        parent = []
        if self.hidden:
            try:
                self.host = xdisplay.Display(os.environ.get("DISPLAY", ":0"))
                s = self.host.screen()
                w = s.root.create_window(0, 0, self.scr_w, self.scr_h, 0, s.root_depth,
                                         X.InputOutput, X.CopyFromParent)
                self.host.sync()
                parent = ["-parent", hex(w.id)]
            except Exception as e:  # sin :0 -> Xephyr visible (o fallo)
                log("no pude crear ventana padre oculta:", e)
        rfd, wfd = os.pipe()
        xe = subprocess.Popen(["Xephyr", "-displayfd", str(wfd), *parent,
                               "-screen", f"{self.scr_w}x{self.scr_h}", "-no-host-grab",
                               "-nolisten", "tcp", "-dpi", "96"],
                              pass_fds=(wfd,), stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, start_new_session=True)
        self.procs.append(xe)
        os.close(wfd)
        num = b""
        t_end = time.time() + 20
        while time.time() < t_end:
            ch = os.read(rfd, 1)
            if not ch or ch == b"\n":
                break
            num += ch
        os.close(rfd)
        if not num.strip().isdigit():
            raise CapError("Xephyr no arranco (no devolvio numero de display)")
        self.disp = f":{int(num)}"
        log("Xephyr en", self.disp, f"{self.scr_w}x{self.scr_h}")
        for _ in range(50):
            try:
                self.d = xdisplay.Display(self.disp)
                break
            except Exception:
                time.sleep(0.1)
        if self.d is None:
            raise CapError("No pude conectar al display anidado")

        # HOME aislado (preferencias de Vivado frescas; no toca ~/.Xilinx del usuario)
        home = os.path.join(self.rdir, "home")
        os.makedirs(os.path.join(home, ".Xilinx", "xsim", "2025.2"), exist_ok=True)
        if self.scale != 100:
            with open(os.path.join(home, ".Xilinx", "xsim", "2025.2", "vivado.xml"), "w") as f:
                f.write('<?xml version="1.0" encoding="UTF-8"?><preferences VERSION="10">\n'
                        f'    <general>\n        <SCALE_BY value="{self.scale}"/>\n'
                        '        <SCALING_TYPE value="3"/>\n    </general>\n</preferences>\n')
        poll = os.path.join(self.rdir, "poll.tcl")
        r = self.rdir
        with open(poll, "w") as f:
            f.write(f"""
proc __cap_poll {{}} {{
  if {{[file exists {{{r}/cmd.tcl}}]}} {{
    file rename -force {{{r}/cmd.tcl}} {{{r}/cmd_run.tcl}}
    set rc [catch {{uplevel #0 {{source {{{r}/cmd_run.tcl}}}}}} msg]
    set f [open {{{r}/resp.tmp}} w]; puts $f "$rc $msg"; close $f
    file rename -force {{{r}/resp.tmp}} {{{r}/resp.txt}}
  }}
  after 150 __cap_poll
}}
after 150 __cap_poll
set f [open {{{r}/ready.flag}} w]; puts $f ok; close $f
""")
        env = dict(self.env, DISPLAY=self.disp, HOME=home)
        env.pop("XAUTHORITY", None)
        self.guilog = open(os.path.join(self.rdir, "gui.out"), "w")
        gui = subprocess.Popen(["xsim", "sim.wdb", "-gui", "-tclbatch", poll], cwd=self.rdir,
                               env=env, stdout=self.guilog, stderr=subprocess.STDOUT,
                               start_new_session=True)
        self.procs.append(gui)
        t_end = time.time() + 180
        while not os.path.exists(os.path.join(r, "ready.flag")):
            if gui.poll() is not None:
                raise CapError("xsim -gui termino inesperadamente:\n" + self.tail_log())
            if time.time() > t_end:
                raise CapError("Timeout esperando la GUI de xsim:\n" + self.tail_log())
            time.sleep(0.3)
        # esperar la ventana principal
        t_end = time.time() + 60
        while self.main_window() is None:
            if time.time() > t_end:
                raise CapError("No aparecio la ventana de Vivado")
            time.sleep(0.3)
        log("GUI lista")

    def tail_log(self):
        try:
            return "\n".join(open(os.path.join(self.rdir, "gui.out"),
                                  errors="replace").read().splitlines()[-20:])
        except Exception:
            return ""

    def stop(self):
        for p in reversed(self.procs):
            try:
                os.killpg(p.pid, signal.SIGTERM)
            except Exception:
                pass
        t_end = time.time() + 5
        for p in reversed(self.procs):
            try:
                p.wait(timeout=max(0.1, t_end - time.time()))
            except Exception:
                try:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.wait(timeout=3)
                except Exception:
                    pass
        for c in (self.d, self.host):
            try:
                c and c.close()
            except Exception:
                pass
        self.procs = []

    # -- ventanas / input
    def main_window(self):
        try:
            for w in self.d.screen().root.query_tree().children:
                try:
                    nm = w.get_wm_name()
                except Exception:
                    continue
                if nm and nm.startswith("Vivado"):
                    g = w.get_geometry()
                    if g.width > 50:
                        return w
        except Exception:
            pass
        return None

    def resize(self, w, h):
        win = self.main_window()
        win.configure(x=0, y=0, width=int(w), height=int(h))
        self.d.sync()
        self.win_w, self.win_h = int(w), int(h)

    def click(self, x, y, n=1):
        xtest.fake_input(self.d, X.MotionNotify, x=int(x), y=int(y))
        self.d.sync()
        time.sleep(0.15)
        for _ in range(n):
            xtest.fake_input(self.d, X.ButtonPress, 1)
            self.d.sync()
            xtest.fake_input(self.d, X.ButtonRelease, 1)
            self.d.sync()
            time.sleep(0.06)
        # alejar el puntero para que no haya tooltips/hover en la captura
        xtest.fake_input(self.d, X.MotionNotify, x=self.scr_w - 2, y=self.scr_h - 2)
        self.d.sync()

    # -- Tcl
    def tcl(self, script, timeout=60):
        r = self.rdir
        for f in ("resp.txt",):
            if os.path.exists(os.path.join(r, f)):
                os.remove(os.path.join(r, f))
        with open(os.path.join(r, "cmd.tmp"), "w") as f:
            f.write(script + "\n")
        os.rename(os.path.join(r, "cmd.tmp"), os.path.join(r, "cmd.tcl"))
        t_end = time.time() + timeout
        while not os.path.exists(os.path.join(r, "resp.txt")):
            if time.time() > t_end:
                raise CapError("Timeout ejecutando Tcl en la GUI:\n" + script[:300])
            if self.procs[-1].poll() is not None:
                raise CapError("La GUI murio:\n" + self.tail_log())
            time.sleep(0.1)
        resp = open(os.path.join(r, "resp.txt")).read()
        rc, _, msg = resp.partition(" ")
        if rc.strip() != "0":
            raise CapError(f"Error Tcl en la GUI: {msg.strip()}\nScript:\n{script[:500]}")
        return msg.strip()

    def grab(self):
        im = ImageGrab.grab(xdisplay=self.disp).convert("RGB")
        # solo la ventana de Vivado (el fondo del root tambien es negro)
        return im.crop((0, 0, min(im.width, self.win_w), min(im.height, self.win_h)))

    def settle(self, min_wait=0.6, timeout=15):
        time.sleep(min_wait)
        prev = self.grab()
        t_end = time.time() + timeout
        while time.time() < t_end:
            time.sleep(0.35)
            cur = self.grab()
            if cur.tobytes() == prev.tobytes():
                return cur
            prev = cur
        return prev


# ---------------------------------------------------------------- geometria
def is_ui(p):
    """Pixel de la UI clara (fuera del panel negro) o bordes azules de foco."""
    return (p[0] >= 225 and p[1] >= 225 and p[2] >= 225) or p == (74, 124, 206)


def analyze(img, nrows_expected=None):
    """Detecta la geometria del panel de ondas maximizado."""
    W, H = img.size
    px = img.load()
    # 1) borde izquierdo de la columna Name: primer negro con corrida larga a media altura
    name_x0 = None
    for y in (H // 2, H // 2 + 37, H // 3):
        run = 0
        for x in range(W // 2):
            if px[x, y] == (0, 0, 0):
                run += 1
                if run >= 12:
                    name_x0 = x - run + 1
                    break
            else:
                run = 0
        if name_x0 is not None:
            break
    if name_x0 is None:
        raise CapError("No encuentro el panel de ondas en la captura")
    xc = name_x0 + 2
    # 2) perfil vertical en el margen izquierdo de Name, partiendo del area de filas
    blk = lambda yy: px[xc, yy] == (0, 0, 0)
    ym = H // 2
    if not blk(ym):
        raise CapError("Geometria inesperada (centro no negro)")
    y = ym
    while y > 0 and blk(y - 1):
        y -= 1
    y_rows0 = y
    while y > 0 and not blk(y - 1):
        y -= 1
    y_hdr0 = y
    while y > 0 and blk(y - 1):
        y -= 1
    y_top = y
    y = ym
    while y < H and blk(y):
        y += 1
    y_line = y  # linea blanca al final del area de filas
    if not (y_top < y_hdr0 < y_rows0 < y_line < H):
        raise CapError(f"Geometria inesperada: {y_top},{y_hdr0},{y_rows0},{y_line}")
    # 3) columnas: corridas de pixeles "de panel" justo encima de la linea final
    yp = y_line - 4
    segs, s = [], None
    for x in range(name_x0, W):
        inside = not is_ui(px[x, yp]) and px[x, yp] != (255, 255, 255)
        if inside and s is None:
            s = x
        elif not inside and s is not None:
            segs.append((s, x - 1))
            s = None
    if s is not None:
        segs.append((s, W - 1))
    # fusionar huecos de 1-2 px (lineas blancas finas dentro del area de ondas)
    merged = []
    for a, b in segs:
        if merged and a - merged[-1][1] <= 2 and len(merged) >= 3:
            merged[-1] = (merged[-1][0], b)
        else:
            merged.append((a, b))
    segs = [g for g in merged if g[1] - g[0] > 10]
    if len(segs) < 3:
        raise CapError(f"No distingo columnas Name/Value/ondas: {segs}")
    (n0, n1), (v0, v1), (w0, w1) = segs[0], segs[1], segs[2]
    for g in segs[3:]:
        w1 = g[1]
    geo = dict(name_x0=n0, name_x1=n1, val_x0=v0, val_x1=v1, wave_x0=w0, wave_x1=w1,
               y_top=y_top, y_hdr0=y_hdr0, y_rows0=y_rows0, y_line=y_line)
    # 4) filas divisoras (morado) en la columna Value
    xv = v0 + max(8, (v1 - v0) // 3)
    divs, s = [], None
    for yy in range(y_rows0, y_line):
        on = px[xv, yy] == C_DIVIDER
        if on and s is None:
            s = yy
        elif not on and s is not None:
            divs.append((s, yy - 1))
            s = None
    geo["dividers"] = divs
    return geo


def find_vlines(img, geo, color, y0=None, y1=None):
    """Centros (float) de lineas verticales de un color en el area de ondas."""
    px = img.load()
    y0 = geo["y_rows0"] if y0 is None else y0
    y1 = geo["y_line"] - 1 if y1 is None else y1
    ys = range(y0, y1, max(1, (y1 - y0) // 40))
    n = len(ys)
    cols = []
    for x in range(geo["wave_x0"], geo["wave_x1"] + 1):
        c = sum(1 for y in ys if px[x, y] == color)
        cols.append(c >= 0.6 * n)
    out, s = [], None
    for i, on in enumerate(cols + [False]):
        if on and s is None:
            s = i
        elif not on and s is not None:
            out.append((geo["wave_x0"] + (s + i - 1) / 2.0, i - s))
            s = None
    return out  # [(centro, ancho)]


# ---------------------------------------------------------------- wcfg
def build_wcfg(base_path, out_path, spec, zs_ps, ze_ps, cursor_ps, name_w, value_w,
               cal_divider=False, markers_t=None, res_ps=1.0):
    tree = ET.parse(base_path)
    root = tree.getroot()
    zs = root.find("zoom_setting")
    zs.find("ZoomStartTime").set("time", fmt_ps(zs_ps))
    zs.find("ZoomEndTime").set("time", fmt_ps(ze_ps))
    c = zs.find("Cursor1Time")
    if c is None:
        c = ET.SubElement(zs, "Cursor1Time")
    c.set("time", fmt_ps(cursor_ps))
    cw = root.find("column_width_setting")
    cw.find("NameColumnWidth").set("column_width", str(int(name_w)))
    cw.find("ValueColumnWidth").set("column_width", str(int(value_w)))
    for wm in root.findall("wave_markers"):
        root.remove(wm)
    objs = root.findall("wvobject")
    # nombres visibles
    sig_rows = [r for r in spec["rows"]]
    if len(objs) != len(sig_rows):
        raise CapError(f"El wcfg base tiene {len(objs)} objetos, se esperaban {len(sig_rows)}")
    for o, r in zip(objs, sig_rows):
        if r["kind"] != "signal":
            continue
        shown = r.get("name")
        if not shown:
            el = o.find("obj_property[@name='ObjectShortName']")
            shown = el.text if el is not None else r["path"].rsplit("/", 1)[-1]
            if not spec["show_range"]:
                shown = re.sub(r"\[[^\]]*\]$", "", shown)
        el = o.find("obj_property[@name='ObjectShortName']")
        if el is None or el.text != shown:
            # nombre personalizado (equivale a "Rename" en la GUI)
            for prop in ("label", "DisplayName"):
                for old in o.findall(f"obj_property[@name='{prop}']"):
                    o.remove(old)
            ET.SubElement(o, "obj_property", {"name": "label"}).text = shown
            ET.SubElement(o, "obj_property", {"name": "DisplayName"}).text = "label"
        r["shown"] = shown
    if markers_t:
        wm = ET.Element("wave_markers")
        for t in markers_t:
            ET.SubElement(wm, "marker", {"label": "", "time": str(int(round(t / res_ps)))})
        root.insert(list(root).index(objs[0]), wm)
    if cal_divider:
        o = ET.SubElement(root, "wvobject", {"fp_name": "divider_cal", "type": "divider"})
        ET.SubElement(o, "obj_property", {"name": "label"}).text = "CAL"
        ET.SubElement(o, "obj_property", {"name": "DisplayName"}).text = "label"
    osz = root.find("WVObjectSize")
    if osz is not None:
        osz.set("size", str(len(objs) + (1 if cal_divider else 0)))
    tree.write(out_path, encoding="UTF-8", xml_declaration=True)


def value_chars(radix, width):
    radix = (radix or "hex").lower()
    if width <= 1:
        return 1
    if radix in ("bin", "binary"):
        return width
    if radix in ("oct", "octal"):
        return (width + 2) // 3
    if radix in ("unsigned", "udec"):
        return len(str(2 ** width - 1))
    if radix in ("dec", "signed", "sdec"):
        return len(str(2 ** (width - 1))) + 1
    if radix == "ascii":
        return (width + 7) // 8
    return (width + 3) // 4


# ---------------------------------------------------------------- dibujo
def text_size(draw, txt, font):
    b = draw.textbbox((0, 0), txt, font=font)
    return b[2] - b[0], b[3] - b[1], b


def draw_label(draw, cx, cy, txt, font, fill, fg=(0, 0, 0)):
    tw, th, b = text_size(draw, txt, font)
    padx, pady = max(4, th * 0.45), max(2, th * 0.3)
    if len(txt) <= 2:
        r = max(tw / 2 + padx * 0.8, th / 2 + pady + 1)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=(0, 0, 0))
    else:
        w2, h2 = tw / 2 + padx, th / 2 + pady
        draw.rounded_rectangle([cx - w2, cy - h2, cx + w2, cy + h2], radius=int(h2 * 0.6),
                               fill=fill, outline=(0, 0, 0))
    draw.text((cx - tw / 2 - b[0], cy - th / 2 - b[1]), txt, font=font, fill=fg)


def row_index(rows, sel):
    """Fila (0-based) de una senal para un box: indice, ruta, nombre corto o 'name'."""
    if isinstance(sel, int):
        if not 0 <= sel < len(rows):
            raise CapError(f"box: fila {sel} fuera de rango")
        return sel
    if sel is None:
        raise CapError("box: falta 'signal' o 'row'")
    sel_base = re.sub(r"\[[^\]]*\]$", "", sel)
    cand = []
    for i, r in enumerate(rows):
        if r["kind"] != "signal":
            continue
        short = r["path"].rsplit("/", 1)[-1]
        if sel in (r["path"], r.get("name"), r.get("shown")) or sel_base == short:
            cand.append(i)
    if not cand:
        raise CapError(f"box: no encuentro la senal '{sel}'")
    if len(cand) > 1:
        raise CapError(f"box: '{sel}' es ambigua (filas {cand}); usa la ruta completa "
                       "o \"row\": <indice>")
    return cand[0]


# ---------------------------------------------------------------- principal
def capture(spec):
    work = spec.get("workdir") or os.environ.get("WAVES_WORKDIR") or DEFAULT_WORK
    os.makedirs(work, exist_ok=True)
    # una captura a la vez: dos GUIs de xsim simultaneas se interfieren entre si
    import fcntl
    lockf = open(os.path.join(work, ".capturar.lock"), "w")
    try:
        fcntl.flock(lockf, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("Otra captura en curso; esperando...", file=sys.stderr)
        fcntl.flock(lockf, fcntl.LOCK_EX)
    spec["_lock"] = lockf
    env = vivado_env()
    # HOME aislado tambien para xvlog/xelab/xsim batch (no escribir en ~/.Xilinx)
    bhome = os.path.join(work, "home_batch")
    os.makedirs(bhome, exist_ok=True)
    env["HOME"] = bhome
    t_start = time.time()
    rdir, res_ps = compile_and_sim(spec, work, env)  # (borra su rdir si falla)
    log(f"sim lista en {time.time() - t_start:.1f}s, rdir={rdir}")

    s = int(spec["scale"]) / 100.0
    rows = spec["rows"]
    N = len(rows)
    width = int(spec["width"])
    # tamano del display anidado (estimado; luego se verifica)
    scr_w = int(width + 260 * s)
    scr_h = int((260 + 24 * (N + 2) + 150) * s)
    scr_h = max(scr_h, int(700 * s))
    sess = Session(rdir, env, scr_w, scr_h, int(spec["scale"]), hidden=not spec.get("show"))
    try:
        sess.start()
        sess.resize(int(width + 61 * s), scr_h)
        sess.settle()

        # 1) crear la configuracion de ondas en la GUI y guardarla
        lines = ["create_wave_config cap_base"]
        for r in rows:
            if r["kind"] == "divider":
                lines.append(f"add_wave_divider {tcl_q(r['label'])}")
            else:
                rad = f"-radix {r['radix']} " if r.get("radix") else ""
                lines.append(f"add_wave {rad}{tcl_q(r['path'])}")
        base = os.path.join(rdir, "base.wcfg")
        lines.append(f"save_wave_config {tcl_q(base)}")
        sess.tcl("\n".join(lines))
        img = sess.settle()

        # 2) maximizar el panel de ondas (boton "maximize" del header del panel)
        def maximized(im):
            try:
                g = analyze(im)
                return g["name_x0"] < 80 * s, g
            except CapError:
                return False, None
        ok, geo = maximized(img)
        # borde izquierdo del panel de ondas (sin maximizar) -> pestana del titulo
        pnl_x = 603 * s
        try:
            pnl_x = analyze(img)["name_x0"]
        except CapError:
            pass
        attempts = [("click", sess.win_w - 67 * s, 113 * s),
                    ("dbl", pnl_x + 30 * s, 113 * s),
                    ("click", sess.win_w - 62 * s, 113 * s),
                    ("dbl", pnl_x + 30 * s, 113 * s)]
        for kind, x, y in attempts:
            if ok:
                break
            sess.click(x, y, 2 if kind == "dbl" else 1)
            img = sess.settle()
            ok, geo = maximized(img)
            if spec.get("_keep"):
                img.save(os.path.join(rdir, f"max_{kind}_{int(x)}.png"))
            log(f"maximizar: {kind} en ({x:.0f},{y:.0f}) -> {'ok' if ok else 'no'}")
        if not ok:
            img.save(os.path.join(rdir, "fail_maximize.png"))
            raise CapError("No pude maximizar el panel de ondas (ver fail_maximize.png en "
                           + rdir + ")")

        # 3) anchos de columnas (en px logicos de Vivado)
        btree = ET.parse(base).getroot()
        fnt = ImageFont.truetype(FONT_REG, 13)
        tmp = ImageDraw.Draw(Image.new("RGB", (10, 10)))
        objs = btree.findall("wvobject")
        name_w, val_chars = 60, 1
        for o, r in zip(objs, rows):
            if r["kind"] == "divider":
                txt = r["label"]
                name_w = max(name_w, text_size(tmp, txt, fnt)[0] + 30)
                continue
            el = o.find("obj_property[@name='ObjectShortName']")
            nm = r.get("name") or (el.text if el is not None else r["path"])
            if not spec["show_range"] and not r.get("name"):
                nm = re.sub(r"\[[^\]]*\]$", "", nm)
            name_w = max(name_w, text_size(tmp, nm, fnt)[0] + 64)
            m = re.search(r"\[(\d+):(\d+)\]$", el.text if el is not None else "")
            wbits = abs(int(m.group(1)) - int(m.group(2))) + 1 if m else 1
            val_chars = max(val_chars, value_chars(r.get("radix"), wbits))
        # los anchos del .wcfg son px fisicos: escalar por la escala de la UI
        name_w = int(round(float(spec.get("name_width", name_w)) * s))
        value_w = int(round(float(spec.get("value_width", max(60, 8 * val_chars + 24))) * s))

        t0p, t1p = ps(spec["t0_ns"]), ps(spec["t1_ns"])
        D = t1p - t0p
        curp = ps(spec["cursor_ns"])
        cfgs = {"n": 0}

        def open_cfg(path):
            cfgs["n"] += 1
            sess.tcl("set __old [current_wave_config]\n"
                     f"open_wave_config {tcl_q(path)}\n"
                     "if {$__old ne \"\"} { close_wave_config -force $__old }")
            return sess.settle(min_wait=0.8)

        def cal_markers(frac):
            a, b = frac
            ta, tb = t0p + a * D, t0p + b * D
            # evitar que coincidan con el cursor
            if abs(ta - curp) < 0.03 * D:
                ta += 0.05 * D
            if abs(tb - curp) < 0.03 * D:
                tb -= 0.05 * D
            return [ta, tb]

        # 4) bucle: ajustar ancho de ventana + calibrar zoom
        ze = t1p
        fit = None
        final_geo = None
        for it in range(6):
            mk = cal_markers((0.1, 0.3) if fit is None else (0.08, 0.92))
            calp = os.path.join(rdir, f"cal{it}.wcfg")
            build_wcfg(base, calp, spec, t0p, ze, curp, name_w, value_w, cal_divider=True,
                       markers_t=mk, res_ps=res_ps)
            img = open_cfg(calp)
            img.save(os.path.join(rdir, f"cal{it}.png"))
            geo = analyze(img)
            # ancho exacto de la imagen final
            crop_w = geo["wave_x1"] + 1 - geo["name_x0"]
            # con escala 150 la ventana cambia de 2 en 2 px: se acepta 1 px de diferencia
            if abs(crop_w - width) > 1:
                sess.resize(sess.win_w + (width - crop_w), sess.win_h)
                sess.settle()
                log(f"ajuste ancho: {crop_w} -> {width}")
                continue
            # filas: el divisor CAL debe ser el ultimo morado
            divs = geo["dividers"]
            if not divs:
                raise CapError("No veo el divisor de calibracion")
            row_h = (divs[-1][0] - geo["y_rows0"]) / float(N)
            if row_h < 10 * s or divs[-1][1] >= geo["y_line"] - 2:
                raise CapError("Las filas no caben en el display (o no se detectaron bien)")
            exp_div = [i for i, r in enumerate(rows) if r["kind"] == "divider"]
            got = [round((d0 - geo["y_rows0"]) / row_h) for d0, _ in divs[:-1]]
            if got != exp_div:
                log("AVISO: divisores detectados en filas", got, "esperados", exp_div)
            geo["row_h"] = row_h
            lines_ = find_vlines(img, geo, C_MARKER)
            if len(lines_) != 2:
                raise CapError(f"Calibracion: esperaba 2 markers, detecte {len(lines_)} "
                               f"(ver {rdir}/cal{it}.png)")
            (xa, wa), (xb, _) = lines_
            ta, tb = mk
            k = (xb - xa) / (tb - ta)            # px por ps
            x_t0 = xa + (t0p - ta) * k           # centro de pixel de t0
            x_t1 = xa + (t1p - ta) * k
            fit = dict(xa=xa, ta=ta, k=k, line_w=wa)
            target_right = geo["wave_x1"] - (wa - 1) / 2.0 - 0.5
            err = x_t1 - target_right
            log(f"it{it}: x(t0)={x_t0:.2f} wave_x0={geo['wave_x0']} x(t1)={x_t1:.2f} "
                f"objetivo={target_right:.2f} err={err:.2f}px")
            if abs(err) <= 1.0:
                final_geo = geo
                break
            # c = k * (ze - zs) es constante en Vivado al abrir un wcfg
            c = k * (ze - t0p)
            k_target = (target_right - x_t0) / D
            ze = t0p + c / k_target
        if final_geo is None:
            raise CapError("No converge la calibracion del zoom (ver cal*.png en " + rdir + ")")
        geo = final_geo

        # 5) captura final (mismo zoom, sin markers ni divisor de calibracion)
        finp = os.path.join(rdir, "final.wcfg")
        build_wcfg(base, finp, spec, t0p, ze, curp, name_w, value_w, res_ps=res_ps)
        img = open_cfg(finp)
        # verificar con el cursor (amarillo) que el mapeo coincide
        cur_lines = find_vlines(img, dict(geo, y_rows0=geo["y_rows0"],
                                          y_line=geo["y_rows0"] + int(N * geo["row_h"])),
                                C_CURSOR)
        xc_pred = fit["xa"] + (curp - fit["ta"]) * fit["k"]
        if cur_lines:
            dx = min(abs(c - xc_pred) for c, _ in cur_lines)
            log(f"cursor: predicho {xc_pred:.2f}, detectado {[c for c, _ in cur_lines]}")
            if dx > 1.5:
                print(f"AVISO: el cursor esta a {dx:.1f}px de lo predicho por la calibracion",
                      file=sys.stderr)
        g2 = analyze(img)
        for kk in ("name_x0", "wave_x1", "y_rows0", "y_top"):
            if g2[kk] != geo[kk]:
                raise CapError(f"La geometria cambio entre calibracion y captura final ({kk})")

        out = spec["out"]
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        full_path = re.sub(r"\.png$", "", out, flags=re.I) + "_full.png"
        img.save(full_path)

        # 6) recorte + anotaciones
        row_h = geo["row_h"]
        y_bottom = int(round(geo["y_rows0"] + N * row_h)) + int(round(4 * s))
        box = (geo["name_x0"], geo["y_top"], geo["wave_x1"] + 1, y_bottom)
        crop = img.crop(box)
        ox, oy = box[0], box[1]

        def X_(t_ns):
            return fit["xa"] + (ps(t_ns) - fit["ta"]) * fit["k"] - ox

        dr = ImageDraw.Draw(crop)
        lw = int(spec.get("marker_width", max(1, int(round(s)))))
        f_mk = ImageFont.truetype(FONT_BOLD, max(9, int(round(12 * s))))
        f_bx = ImageFont.truetype(FONT_BOLD, max(8, int(round(11 * s))))
        wave_l = geo["wave_x0"] - ox
        wave_r = geo["wave_x1"] - ox
        y_rows_c = geo["y_rows0"] - oy
        y_end_c = y_bottom - oy - 1
        for b in spec["boxes"]:
            i = row_index(rows, b.get("row", b.get("signal")))
            col = tuple(b.get("color", (255, 64, 200)))
            x0 = max(wave_l, X_(float(b["t0_ns"])))
            x1 = min(wave_r, X_(float(b["t1_ns"])))
            ytop = y_rows_c + i * row_h + 1
            ybot = y_rows_c + (i + 1) * row_h
            bw = max(2, int(round(2 * s)))
            dr.rectangle([round(x0) - 1, round(ytop), round(x1) + 1, round(ybot)],
                         outline=col, width=bw)
            if b.get("label"):
                txt = str(b["label"])
                tw, th, bb = text_size(dr, txt, f_bx)
                pad = max(2, int(round(2 * s)))
                pos = b.get("label_pos", "left")
                if pos == "left":
                    lx1 = round(x0) - 2
                    lx0 = lx1 - tw - 2 * pad
                    if lx0 < wave_l:      # no cabe a la izquierda -> a la derecha
                        lx0 = round(x1) + 2
                        lx1 = lx0 + tw + 2 * pad
                    ly0 = (ytop + ybot) / 2 - th / 2 - pad
                elif pos == "right":
                    lx0 = round(x1) + 2
                    lx1 = lx0 + tw + 2 * pad
                    ly0 = (ytop + ybot) / 2 - th / 2 - pad
                else:  # top
                    lx0 = round(x0) - 1
                    lx1 = lx0 + tw + 2 * pad
                    ly0 = ytop - th - 2 * pad + bw
                dr.rectangle([lx0, ly0, lx1, ly0 + th + 2 * pad], fill=col)
                dr.text((lx0 + pad - bb[0], ly0 + pad - bb[1]), txt, font=f_bx, fill=(0, 0, 0))
        for m in spec["markers"]:
            col = tuple(m.get("color", (0, 230, 255)))
            xm = X_(float(m["t_ns"]))
            if not (wave_l - 1 <= xm <= wave_r + 1):
                print(f"AVISO: marker t={m['t_ns']} fuera de la ventana", file=sys.stderr)
                continue
            r_lab = 9 * s
            # fila de etiquetas de markers de Vivado (debajo de la del cursor)
            cy = 27 * s
            xl = int(round(xm - (lw - 1) / 2.0))
            dr.rectangle([xl, cy + r_lab, xl + lw - 1, y_end_c], fill=col)
            if m.get("label") not in (None, ""):
                draw_label(dr, xl + (lw - 1) / 2.0, cy, str(m["label"]), f_mk, col)
        crop.save(out)
        if spec.get("_keep"):
            dbg = dict(geo=geo, fit=fit, ze_ps=ze, box=box, rdir=rdir)
            with open(re.sub(r"\.png$", "", out, flags=re.I) + "_debug.json", "w") as f:
                json.dump(dbg, f, indent=1, default=str)
        log(f"total {time.time() - t_start:.1f}s")
        ok_run = True
        return out, full_path, rdir
    finally:
        sess.stop()
        if not spec.get("_keep"):
            shutil.rmtree(rdir, ignore_errors=True)
        elif not locals().get("ok_run"):
            print(f"(archivos de trabajo conservados en {rdir})", file=sys.stderr)


def main():
    global VERBOSE
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    VERBOSE = "--verbose" in sys.argv or "-v" in sys.argv
    if len(args) != 1:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        sys.exit(2)

    def on_sig(sig, frm):
        raise SystemExit(f"interrumpido (senal {sig})")
    signal.signal(signal.SIGTERM, on_sig)
    signal.signal(signal.SIGHUP, on_sig)
    try:
        spec = load_spec(args[0])
        spec["_keep"] = "--keep" in sys.argv
        out, full, rdir = capture(spec)
    except CapError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    print(out)


if __name__ == "__main__":
    main()
