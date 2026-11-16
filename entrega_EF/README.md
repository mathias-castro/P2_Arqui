# Proyecto 2 - Entrega final

Procesador RISC-V en tres versiones:

- (A) pipeline Single-Issue de cinco etapas,
- (B) superescalar Dual-Issue in-order,
- (C) Dual-Issue con predicción dinámica de saltos (contadores de 2 bits y BTB).

## Carpetas

- `single_issue/`: arquitectura A.
  - `src/`: código Verilog.
  - `tb/`: `tb_e1_p1` a `tb_e1_p4` (programas del pipeline), `tb_profesor` y `tb_comparacion`.
- `dual_issue/`: arquitectura B.
  - `src/`: código Verilog.
  - `tb/`: `tb_e2_p1` a `tb_e2_p6`, `tb_riscvtest`, `tb_profesor_dual` y `tb_comparacion_dual`.
- `dual_issue_opt/`: arquitectura C.
  - `src/`: código Verilog. Respecto a B cambian `datapath_dual.v` y `hazardunit_dual.v`, y se agrega `predictor.v`. Los demás archivos son iguales.
  - `tb/`:
    - `tb_ef_p1` y `tb_ef_p2`: pruebas de la optimización.
    - `tb_propio`: programa propio.
    - `tb_e2_p1` a `tb_e2_p6` y `tb_riscvtest`: los mismos programas de B.
    - `tb_profesor_opt` y `tb_comparacion_opt`.
- `programas/`: los programas en Assembly (`.s`) y en código máquina (`.mem`).
- `informe/`: `Informe_Final.pdf`. En `fuente/` y `figuras/` está lo que se usó para armarlo; `construir.py` lo regenera.
- `presentacion/`: `Presentacion_Final.pdf`.
- `comparar.sh`: corre un programa en las tres arquitecturas con Icarus Verilog y muestra las métricas.
- `pruebas_aleatorias/`: generador de programas al azar que compara las tres arquitecturas (ver su README).

## Cómo simular en Vivado

1. Crear un proyecto RTL por arquitectura. Agregar como Design Sources los `.v` de la carpeta `src` de esa arquitectura.
2. Agregar como Simulation Sources los testbenches de su carpeta `tb` y los `.mem` de `programas/`.
3. Elegir el testbench con Set as Top y darle Run Simulation.

## Cómo comparar las tres arquitecturas

Los testbenches de comparación usan el mismo criterio en las tres arquitecturas:

- `tb_comparacion` (A), `tb_comparacion_dual` (B) y `tb_comparacion_opt` (C).
- Es el criterio del enunciado del profesor: `fin` (el salto a sí mismo del final) no se cuenta.
- Los ciclos se cuentan desde que se suelta el reset hasta el ciclo en que la última instrucción antes de `fin` está en Writeback.
- Las instrucciones retiradas son las que llegan a Writeback sin ser burbujas ni `fin`.

Imprimen las instrucciones, los ciclos, el IPC, el CPI, los stalls y los saltos, y en C también los saltos mal predichos y la precisión del predictor. El programa se elige con el parámetro `MEMFILE`. En Vivado se cambia en Simulation Settings, en `-generic_top` o directamente en el testbench.

Con Icarus Verilog:

```
./comparar.sh propio
```

## Programa del profesor

`profesor.s` es el programa de prueba del enunciado, sin cambios. Para correrlo la memoria de datos tiene 512 palabras (usa la dirección 1536), la de instrucciones 128 y el Register File empieza en 0.

- `tb_profesor` (A), `tb_profesor_dual` (B) y `tb_profesor_opt` (C) comprueban el estado de los registros y la memoria al final de cada etapa (A, B, C y D), cuando el último `sw` de la etapa llega a Writeback. Imprimen el ciclo de cada comprobación y si fue correcta. En la waveform, `chk` marca ese ciclo y `etapa`, `ok` y `pasadas` dan el resultado.
- Sus métricas se obtienen con `./comparar.sh profesor`.

## Programas

| Programa | Archivo | Qué prueba | Mem[100] |
|---|---|---|---|
| Pipeline 1 a 4 | `e1_p1_isa` a `e1_p4_flushing` | ISA, forwarding, stalling, flushing | 17, 4, 42, 7 |
| Dual-Issue 1 a 6 | `e2_p1_alu` a `e2_p6_reagrupamiento` | Emisión doble, RAW, memoria, saltos, Register File, reagrupamiento | 32, 26, 13, 0, 42, 37 |
| General | `riscvtest` | Programa de prueba del libro | 25 |
| Optimización 1 | `ef_p1_bucle` | El predictor aprende un bucle | 55 |
| Optimización 2 | `ef_p2_vias` | Saltos predichos en las dos vías | 18 |
| Propio | `propio` | Programa de comparación (bucles sobre un arreglo) | 120 |
| Profesor | `profesor` | Programa de comparación del enunciado (etapas A a D) | ver `tb_profesor` |

Nuestros programas terminan con `fin: beq x0, x0, fin` y el del profesor con `fin: jal x0, fin`; los testbenches reconocen los dos.
