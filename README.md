# P2_Arqui

Proyecto 2 de Arquitectura de Computadoras: procesador RISC-V Dual-Issue.

## Estructura

- `RISCV_Pipeline/src/`: pipeline Single-Issue de cinco etapas con Hazard Unit.
- `RISCV_Pipeline/sim/`: testbenches, programas y scripts de waveforms.
- `Superscalar_Dual_Issue/`: desarrollo del procesador Dual-Issue.
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
