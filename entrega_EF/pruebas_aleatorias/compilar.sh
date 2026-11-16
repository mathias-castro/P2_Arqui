#!/usr/bin/env bash
# Compila las tres arquitecturas para las pruebas con programas al azar.
set -e
cd "$(dirname "$0")"
mkdir -p build logs
iverilog -g2012 -o build/a.vvp ../single_issue/src/*.v tb_a.v
iverilog -g2012 -o build/b.vvp ../dual_issue/src/*.v tb_dual.v
iverilog -g2012 -DOPT -o build/c.vvp ../dual_issue_opt/src/*.v tb_dual.v
echo "listo: build/a.vvp, build/b.vvp, build/c.vvp"
