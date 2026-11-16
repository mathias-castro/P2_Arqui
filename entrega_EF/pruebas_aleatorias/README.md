# Pruebas con programas al azar

Generan programas al azar con las instrucciones soportadas (bucles anidados, saltos en las dos vías, `jal` con registro de retorno, `lw`/`sw` y dependencias), los corren en las tres arquitecturas (A, B y C) y comparan:

- los registros x1 a x31,
- las 64 palabras de la memoria de datos,
- la cantidad de instrucciones retiradas.

Además los comparan con un simulador simple escrito en Python (`gen.py`), que ejecuta el programa instrucción por instrucción.

```
./compilar.sh              # compila A, B y C con Icarus Verilog
python3 run.py 0 1000      # corre los programas con semilla 0 a 999
python3 run.py --mem ../programas/*.mem   # corre los programas del proyecto
```

`run.py` imprime cada programa que falla. En `logs/` deja el detalle de cada corrida.
