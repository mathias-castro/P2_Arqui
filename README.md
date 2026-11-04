# Proyecto 2 — E1

Pipeline RISC-V de cinco etapas basado en Harris y Harris, más un prototipo de Dual Fetch, Dual Decode y dos vías hasta EX. La parte dual **todavía no es un procesador Dual-Issue completo**: no tiene Issue Unit, forwarding entre vías, MEM/WB ni retiro. Sus puertos de escritura al Register File están deshabilitados.

## Ejecutar

Requisitos: Icarus Verilog (`iverilog`, `vvp`) y `make`. GTKWave es opcional para ver las trazas. En Ubuntu se pueden instalar con `sudo apt install iverilog gtkwave make`. En el equipo de esta revisión ya están disponibles Icarus y GTKWave en `~/.local/bin`, sin modificar los paquetes del sistema.

Desde esta carpeta:

```sh
make test
make harris
```

`make test` ejecuta los cuatro programas, la prueba del prototipo dual y la prueba del Register File 4R/2W. Cualquier comprobación fallida termina con un error. Los VCD y logs nuevos quedan en `build/`.

```sh
# Un programa individual, después de make test:
vvp build/pipeline.vvp +P=3 +VCD=build/p3.vcd

# Vista usada en el informe, con el mismo intervalo y señales:
gtkwave evidence/p3.vcd evidence/p3.gtkw -r evidence/waves.rc

# Otra vista de la misma simulación dual:
gtkwave evidence/dual.vcd evidence/dual_decode.gtkw -r evidence/waves.rc
```

Las seis ejecuciones de `make test` deben terminar en `PASS`. `make harris` conserva la prueba de la figura 7.64 del libro y exige `Mem[100]=25` después de la escritura.

## Archivos

- `RISCV_Pipeline/`: RTL Single-Issue. `riscvsingle` conserva su nombre histórico, pero instancia el pipeline.
- `Superscalar_Dual_Issue/`: Fetch y Decode duales, Register File 4R/2W y dos instancias de `dual_execute_lane`. Comparten `controller`, `maindec`, `aludec`, `extend`, `alu`, `mux2` y `flopenrc` con el Single-Issue; no hay copias divergentes.
- `programs/`: los cinco programas Assembly y sus `.mem` (cuatro Single-Issue y uno para las conexiones duales).
- `tests/tb_pipeline.v`: testbench parametrizado por `+P=1..4`. Valida todos los stores, registros finales, selectores y efectos de stalls/flushes.
- `Superscalar_Dual_Issue/tb_dual.v`: verifica seis pares consecutivos, control e inmediatos, cuatro lecturas, dos ALU y hold de dos ciclos.
- `tests/tb_dual_regfile.v`: prueba dos escrituras, prioridad al mismo destino, x0 y escritura independiente del puerto 1.
- `evidence/`: VCD, logs, capturas reales de GTKWave, vistas `.gtkw` y diagramas del informe. Son resultados conservados de la entrega, no archivos temporales.
- `scripts/assemble.sh`: regenera los `.mem` con GNU binutils para RISC-V.

## Instrucciones y memoria

Se soporta el subconjunto del diseño base: `add`, `sub`, `and`, `or`, `slt`, `addi`, `andi`, `ori`, `slti`, `lw`, `sw`, `beq` y `jal`. `nop` se codifica como `addi x0,x0,0`. No se implementa la ISA RV32I completa: por ejemplo, no hay `jalr`, accesos byte/halfword, otros branches, CSR ni excepciones. Los casos de ALU para shifts heredados del módulo base no están habilitados por el decoder.

La ROM contiene 256 palabras y la RAM de datos 64. Las direcciones son de bytes; `lw` y `sw` deben estar alineados a cuatro bytes y dentro de memoria. El testbench inicializa la RAM en cero. Los programas Single-Issue inicializan sus propios registros; no se presupone que reset borre el Register File. x0 siempre se lee como cero.

El RTL conserva los `don't care` del diseño del libro para campos no utilizados. Al leer una waveform, un resultado solo escribe el Register File si `RegWriteW=1`; el dato de una instrucción sin escritura no es un resultado arquitectónico.

## Pruebas de E1

| Programa | Qué comprueba | Resultado | Stalls | Redirecciones |
|---|---|---|---:|---:|
| P1 | 13 instrucciones; sin dependencias RAW que necesiten la Hazard Unit | x4=17, x13=12, x14=72 | 0 | 1 por `jal` |
| P2 | MEM→EX, WB→EX, prioridad MEM, dato de `sw`, x0 | x5=19, Mem[4]=18 | 0 | 0 |
| P3 | Load-Use hacia una suma y hacia el dato de un store | x3=42, Mem[8]=42 | 2 | 0 |
| P4 | `beq` tomado/no tomado, `jal`, salto hacia atrás y escrituras anuladas | x5=36, x10=0, Mem[12]=40 | 0 | 4 |

Los cuatro programas terminan con un store a 252 de su número de prueba. El período simulado es de 10 ns y reset se desactiva a los 12 ns. Se cuentan 27, 16, 14 y 28 ciclos respectivamente, desde el primer flanco activo después de reset hasta el store final. Una redirección es un salto tomado; el incremento normal del PC no se incluye en ese conteo. Los ciclos permiten reproducir cada prueba, pero no comparar el IPC de programas distintos.

P1 no tiene dependencias de datos que necesiten forwarding o stalls. Su `jal` sí requiere flushing por control, pues es una de las instrucciones que se está verificando.

En el prototipo dual se precargan x1=12, x2=5, x3=4 y x4=9 desde el testbench, porque no hay WB integrado. El `lw` de su programa solo calcula la dirección; no carga memoria. Se verifica la continuidad de **pares completos** al detener Fetch/Decode. La emisión parcial y el reagrupamiento corresponden a E2.

## Cambios respecto al avance recibido

1. Se conserva la Hazard Unit sencilla del libro: forwarding con prioridad MEM, una burbuja ante Load-Use y flushing cuando se toma un salto.
2. Se impiden escrituras físicas a x0 en el Register File Single-Issue.
3. Dual Decode genera control e inmediatos, además de extraer campos. Se agregan IF/ID, ID/EX y dos ALU conectadas.
4. El Register File dual escribe en el flanco de bajada. Si las dos vías escriben el mismo destino, gana la vía 1, definida como la más joven. Esta convención deberá conservarse al asignar recursos en E2.
5. Se agregan programas, comprobaciones automáticas y evidencia reproducible. El test del libro ahora tiene timeout, falla con código de error y comprueba que el store final efectivamente se escribió.

El ajuste de la prioridad del Register File dual evita que una escritura antigua sobrescriba el valor de la instrucción más joven. El programa original del libro también se conserva como prueba de regresión.

La condición de stall es la de Harris: `ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE))`. La nota de la página 450 explica que puede producir una pausa innecesaria por coincidencias con un inmediato o un load dirigido a x0. Estos casos no alteran el resultado y quedan con el comportamiento del libro. P3 se centra en dos dependencias reales, sin añadir filtros ni pruebas especiales para esos casos poco frecuentes.

## Cobertura de la rúbrica E1

| Criterio | Puntos | Evidencia preparada |
|---|---:|---|
| Pipeline y Hazard Unit | 1.25 | RTL Single-Issue; P1-P4; secciones 3, 4 y 7 del informe. |
| Dual Fetch y Dual Decode | 0.75 | Dos instrucciones, control e inmediatos; `tb_dual`; figuras 7 y 8. |
| Datapath Dual-Issue preliminar | 0.50 | IF/ID, Register File, dos ID/EX y dos ALU; figura 2. |
| Programas, waveforms y resultados | 0.50 | Cuatro `.mem`, sus fuentes `.s`, testbench, VCD, capturas e interpretación. |
| Pregunta individual | 1.00 | Cada integrante debe explicar el funcionamiento; preguntas de repaso más abajo. |

La rúbrica indica que E1 no exige todavía la ejecución simultánea completa de dos instrucciones. El informe se centra en esta entrega y distingue las partes pendientes de E2.

## Regenerar los programas

Los `.mem` ya se incluyen. Para reconstruirlos se requiere GNU binutils RISC-V, Python 3 y las herramientas `riscv64-unknown-elf-{as,ld,objcopy,objdump}`. El prefijo `riscv64` del ejecutable también permite ensamblar RV32I con las opciones del script.

```sh
make assemble
make test
```

Se usa `-march=rv32i -mabi=ilp32`, sin relajación y con `.text` en la dirección cero. `build/*.dis` permite contrastar las instrucciones con sus códigos. Cada `.mem` se completa con NOP hasta 256 palabras.

## Qué falta para E2

La Issue Unit, dependencias entre candidatas, emisión parcial y reagrupamiento, forwarding entre vías, MEM/WB, control de saltos en ambas posiciones y asignación dinámica del único puerto de datos y del recurso de branches. La duplicación de ALU no resuelve estas tareas por sí sola. La optimización adicional de EF aún debe proponerse y aprobarse.

## Para la pregunta individual

Conviene poder explicar con las figuras del informe:

- Por qué MEM tiene prioridad sobre WB cuando ambos escriben el mismo registro.
- Por qué un Load-Use necesita una burbuja aunque exista forwarding.
- Por qué durante un stall se conservan PC e IF/ID, mientras el load avanza.
- Por qué `ForwardBE` también debe alimentar el dato de `sw`.
- Qué dos instrucciones se anulan cuando el branch está en EX, y por qué `jal` conserva su link.
- Qué selecciona ResultSrc y por qué el control debe avanzar junto con los datos.
- Qué demuestra el prototipo dual y qué le falta para emitir y completar dos instrucciones.

## Fuentes del diseño

Harris y Harris, *Digital Design and Computer Architecture, RISC-V Edition* (2021), secciones 7.5, 7.6 y 7.7.4; las clases `Sema11_11-ArchT-Microarchitecture Pipelined`, `Sem11_12-ArchT-Microarchitecture Pipelined` y `Sema12_12-ArchT-Microarchitecture Optimization`; el enunciado y la rúbrica de Proyecto 2. La figura superscalar del libro tiene dos puertos de datos, pero este proyecto exige compartir **uno**.

`make clean` elimina únicamente los archivos regenerables de `build/`; conserva programas y evidencia.
