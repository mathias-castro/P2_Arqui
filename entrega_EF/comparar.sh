#!/usr/bin/env bash
# Corre un programa en las tres arquitecturas con Icarus Verilog y muestra las metricas.
# Uso: ./comparar.sh programa   (sin extension; el .mem debe estar en programas/)
# En Vivado se obtiene lo mismo con los testbenches tb_comparacion, tb_comparacion_dual
# y tb_comparacion_opt, cambiando el parametro MEMFILE.
set -e
cd "$(dirname "$0")"
p=$1
tmp=$(mktemp -d)
iverilog -g2012 -P tb_comparacion.MEMFILE=\"$p.mem\"      -o $tmp/a single_issue/src/*.v  single_issue/tb/tb_comparacion.v
iverilog -g2012 -P tb_comparacion_dual.MEMFILE=\"$p.mem\" -o $tmp/b dual_issue/src/*.v    dual_issue/tb/tb_comparacion_dual.v
iverilog -g2012 -P tb_comparacion_opt.MEMFILE=\"$p.mem\"  -o $tmp/c dual_issue_opt/src/*.v dual_issue_opt/tb/tb_comparacion_opt.v
cd programas
for x in a b c; do vvp -n $tmp/$x | grep -v -e "finish called" -e WARNING; done
rm -rf $tmp
