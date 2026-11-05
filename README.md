# P2_Arqui

Proyecto 2 de Arquitectura de Computadoras: procesador RISC-V Dual-Issue.

## Estructura

- `RISCV_Pipeline/src/`: pipeline Single-Issue de cinco etapas con Hazard Unit.
- `RISCV_Pipeline/sim/`: testbenches, programas y scripts de waveforms.
- `Superscalar_Dual_Issue/src/`: Dual Fetch, Dual Decode, Register File 4R/2W y dos vias hasta EX. Incluye copias de `alu`, `aludec`, `controller`, `extend`, `flopenrc`, `maindec` y `mux2` para que la carpeta se pueda simular sin `RISCV_Pipeline/`.
- `Superscalar_Dual_Issue/sim/`: testbenches, programa y scripts de waveforms del prototipo dual.
- `Superscalar_Dual_Issue/docs/`: diagrama del datapath Dual-Issue preliminar.
- `Dual_Issue + Optimization/`: procesador Dual-Issue con optimizacion.

## Programas de prueba

| Programa | Prueba | Ciclos |
| --- | --- | --- |
| `programa1` | ISA sin dependencias | 27 |
| `programa2` | Forwarding | 16 |
| `programa3` | Stalling | 14 |
| `programa4` | Flushing | 20 |

## Simulacion con Icarus Verilog

Desde `RISCV_Pipeline/sim`:

```bash
iverilog -g2005 -o /tmp/p1 -s tb_programa1 ../src/*.v tb_programa1.v
vvp -n /tmp/p1
```

Para otro programa, cambia el numero en ambos comandos.

## Prototipo Dual-Issue

El prototipo todavia no es un procesador Dual-Issue completo: no tiene Issue Unit, forwarding entre vias, MEM ni WB. Los puertos de escritura del Register File quedan deshabilitados, y el testbench precarga x1 a x4 y activa `Stall`.

Desde `Superscalar_Dual_Issue/sim`:

```bash
iverilog -g2005 -o /tmp/dual -s tb_dual ../src/*.v tb_dual.v
vvp -n /tmp/dual
iverilog -g2005 -o /tmp/dual_regfile -s tb_dual_regfile ../src/dual_regfile.v tb_dual_regfile.v
vvp -n /tmp/dual_regfile
```

Ambas pruebas deben terminar en `PASS`.

En Vivado, usa `tb_dual` o `tb_dual_regfile` como top de simulacion y ejecuta `waves_dual_fetch.tcl`, `waves_dual_decode.tcl`, `waves_dual_control.tcl` o `waves_dual_regfile.tcl` desde la consola Tcl.
