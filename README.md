# ASCII PAINT

<img width="639" height="480" alt="image" src="https://github.com/user-attachments/assets/d524218a-b06b-4e9d-becf-58c2451cca47" />

**Docentes**
- Iriso Pedro
- Bruschetti Fabio

**Materia:** Sistemas de Procesamiento de Datos (SPD)
**Carrera:** Tecnicatura Universitaria en Programación Informática — ECyT, UNSAM
**Año:** 2026

**Integrantes:**
- Gentta Iván
- Giménez Agustín
- Zárate Alaciel

## Índice

- [Descripción general](#descripción-general)
- [Funcionalidades](#funcionalidades)
- [Requisitos](#requisitos)
- [Compilación y ejecución](#compilación-y-ejecución)
- [Instrucciones de uso](#instrucciones-de-uso)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Detalles técnicos](#detalles-técnicos)


## Descripción general

ASCII PAINT utiliza el modo gráfico VGA de 640x480 mediante el servicio 00h de int 10h y la divide en dos zonas:

- **Panel lateral (izquierda, X de 0 a 130 pixeles):** paleta de colores, herramientas, pinceles, tamaño del pincel y botones para guardar y cargar.
- **Lienzo (derecha, X de 131 a 639):** la zona donde se dibuja con el mouse.

Cada clic en el lienzo escribe el carácter ASCII elegido, con el color elegido, en una grilla de texto. Esa grilla también se guarda en memoria, en una matriz, y desde ahí se escribe y se lee el archivo `DIBUJO.DAT`.

```
+--------------+---------------------------------------------+
|  -COLORES-   |                                             |
|  [ROJO][VER] |                                             |
|  [AZUL][AMA] |                                             |
|  [BLAN][CIA] |                                             |
|              |                                             |
|-HERRAMIENTAS-|                  LIENZO                     |
|  BORRADOR    |              (30 x 64 celdas)               |
|  BORRAR TODO |                                             |
|              |          * * #  ███  ~~~  ...  ───          |
|  -PINCEL- + 1 -                                            |
|  [*] [#] [█] |                                             |
|  [.] [-] [~] |                                             |
|--------------|                                             |
|  GUARDAR     |                                             |
|  CARGAR      |                                             |
|ESC PARA SALIR|                                             |
+--------------+---------------------------------------------+
```

## Funcionalidades

- **Pantalla de introducción**
- **Dibujo con el mouse**
- **6 colores**
- **6 pinceles ASCII**
- **Tamaño de pincel**
- **Borrador**
- **Borrar todo** (interrupción propia, INT 60h)
- **Guardar y cargar**
- **Salida con ESC**

## Requisitos

- [DOSBox](https://www.dosbox.com/) (o cualquier entorno DOS)
- **TASM** (Turbo Assembler) y **TLINK** (Turbo Linker)

## Compilación y ejecución

1. Copiar `main.asm`, `interfaz.asm`, `libPaint.asm` y `cPaint.bat` en la carpeta de TASM.
2. Abrir DOSBox y ejecutar `cPaint.bat`:
   ```
   cPaint
   ```
   El script hace lo siguiente:
   ```bat
   tasm main.asm
   tasm interfaz.asm
   tasm libPaint.asm
   tlink main + libPaint + interfaz
   ```

## Instrucciones de uso

### Con el mouse

| Zona del panel | Acción |
|---|---|
| Cuadrados de color | Selecciona el color del pincel |
| `BORRADOR` | Cambia el pincel a espacio (borra) |
| `BORRAR TODO` | Limpia todo el lienzo (llama a `INT 60h`) |
| `+` / `-` | Aumenta o reduce el tamaño del pincel (1 a 3) |
| `[*]` `[#]` `[█]` `[.]` `[-]` `[~]` | Selecciona el carácter del pincel |
| `GUARDAR` | Guarda el lienzo en `DIBUJO.DAT` |
| `CARGAR` | Carga `DIBUJO.DAT` y lo redibuja |
| Lienzo | Clic izquierdo para pintar |

### Con el teclado

| Tecla | Acción |
|---|---|
| `1` a `6` | Pincel `*`, `#`, `█`, `.`, `─`, `~` |
| `+` / `-` | Aumentar / reducir tamaño del pincel |
| `g` | Guardar dibujo |
| `l` | Cargar dibujo |
| `ESC` | Salir del programa |

> El archivo `DIBUJO.DAT` se crea en la carpeta desde donde se ejecuta el programa. Si se guarda de nuevo, se sobrescribe.

## Estructura del proyecto

```
TP_assembler/
├── main.asm        Programa principal: bucle de eventos, mouse, teclado y menú
├── interfaz.asm    Pantalla de intro, panel lateral y dibujo de rectángulos
├── libPaint.asm    Librería: mouse, trazo, ISR de borrado, guardar y cargar
├── cPaint.bat      Script de compilación y linkeo
```

### Rutinas por módulo

**`main.asm`**
| Rutina | Descripción |
|---|---|
| `main` | Instala la INT 60h, muestra la intro y la interfaz, y corre el bucle principal |
| `actualizar_tamanio` | Muestra el tamaño actual del pincel en el panel |

**`interfaz.asm`**
| Rutina | Descripción |
|---|---|
| `dibujar_intro` | Dibuja la pantalla de presentación |
| `dibujar_interfaz` | Dibuja el panel lateral y las líneas divisorias |
| `dibujar_rectangulo_color` | Pinta un rectángulo píxel a píxel (CX=X, DX=Y, SI=ancho, DI=alto, AL=color) |

**`libPaint.asm`**
| Rutina | Descripción |
|---|---|
| `limpiar_pantalla` | Activa el modo VGA 640x480 de 16 colores (`INT 10h`, AX=0012h) |
| `init_mouse` | Inicializa y muestra el mouse (`INT 33h`, servicios 0 y 1) |
| `leer_mouse` | Devuelve botones en BX, X en CX, Y en DX (`INT 33h`, servicio 3) |
| `pintar_trazo` | Escribe el carácter en la matriz y en pantalla según el tamaño del pincel |
| `limpiarLienzoISR` | ISR de la INT 60h: limpia la matriz y pinta el lienzo de negro |
| `guardar_lienzo` | Crea `DIBUJO.DAT` y escribe la matriz (devuelve código de error en AX) |
| `cargar_lienzo` | Lee `DIBUJO.DAT` en la matriz y la redibuja (devuelve código de error en AX) |

## Detalles técnicos

### Modo de video y grilla de texto

Se usa el modo VGA `12h` (640x480, 16 colores). En este modo cada carácter ocupa 8x16 píxeles, así que la pantalla equivale a una grilla de **80 columnas x 30 filas**. La posición del mouse se pasa a la grilla así:

```
columna = X / 8    (shr 3)
fila    = Y / 16   (shr 4)
```

### Matriz del lienzo

El lienzo se guarda en memoria como una matriz de **30 filas x 64 columnas**. Cada celda ocupa 2 bytes: el carácter y el color.

```asm
lienzo db 1920 dup(' ', 00h)    ; 1920 celdas x 2 bytes = 3840 bytes
```

La posición de cada celda dentro de la matriz se calcula con:

```
offset = (fila * 128) + (columna * 2)
```

Se multiplica por 128 porque cada fila tiene 64 celdas de 2 bytes. Como 128 y 2 son potencias de 2, el cálculo se hace con desplazamientos (`shl`) en lugar de `mul`.

### Interrupción propia (INT 60h)

Al iniciar, el programa:
1. Guarda el vector original de la INT 60h (`INT 21h`, servicio `35h`).
2. Instala `limpiarLienzoISR` como nueva rutina (`INT 21h`, servicio `25h`).

El botón **BORRAR TODO** ejecuta `int 60h`. La ISR guarda todos los registros, rellena la matriz con espacios negros usando `rep stosw` y pinta de negro la zona del lienzo en forma de cascada fachera.

Al salir con ESC se restaura el vector original antes de volver a DOS.

### Archivo DIBUJO.DAT

El archivo es una copia directa de la matriz en memoria: **3840 bytes**, en pares `carácter, color`, fila por fila. Se maneja con los servicios de archivos de DOS (`INT 21h`):

| Servicio | Uso |
|---|---|
| `3Ch` | Crear archivo |
| `3Dh` | Abrir archivo (solo lectura) |
| `3Fh` | Leer |
| `40h` | Escribir |
| `3Eh` | Cerrar |

### Interrupciones utilizadas

| Interrupción | Servicios | Uso |
|---|---|---|
| `INT 10h` | `00h`, `02h`, `09h`, `0Ch` | Modo de video, posicionar cursor, escribir carácter con color, pintar píxel |
| `INT 16h` | `00h`, `01h` | Leer tecla / consultar si hay tecla |
| `INT 21h` | `02h`, `09h`, `25h`, `35h`, `3Ch`–`40h`, `4Ch` | Texto, vectores de interrupción, archivos, salida |
| `INT 33h` | `00h`–`03h` | Mouse: inicializar, mostrar, ocultar, leer |
| `INT 60h` | — | Interrupción propia: borrar el lienzo |
