.8086
.model small
.stack 100h

; =========================================================================
; DECLARACIÓN DE SUBRUTINAS PÚBLICAS
; =========================================================================
public init_mouse
public leer_mouse
public limpiar_pantalla
public dibujar_interfaz
public dibujar_rectangulo_color
public pintar_trazo
public limpiarLienzoISR

.data

.code

; =========================================================================
; SECCIÓN 1: CONTROL DEL MOUSE (INT 33h) Y PANTALLA GENERAL
; =========================================================================

; -------------------------------------------------------------------------
; Subrutina: limpiar_pantalla
; Pone la pantalla en modo gráfico 640x480 de 16 colores (limpia todo).
; -------------------------------------------------------------------------
limpiar_pantalla proc
    push ax
    mov ax, 0012h       ; Servicio 00h de INT 10h: Modo VGA 640x480
    int 10h
    pop ax
    ret
limpiar_pantalla endp

; -------------------------------------------------------------------------
; Subrutina: init_mouse
; Inicializa el driver del mouse y lo muestra en pantalla.
; -------------------------------------------------------------------------
init_mouse proc
    push bx
    mov ax, 0000h       ; Servicio 0000h: Reset / Inicializar ratón
    int 33h
    
    mov ax, 0001h       ; Servicio 0001h: Mostrar el puntero gráfico
    int 33h
    pop bx
    ret
init_mouse endp

; -------------------------------------------------------------------------
; Subrutina: leer_mouse
; Retorna: BX = Botones (Bit 0=Izq, Bit 1=Der), CX = X, DX = Y
; -------------------------------------------------------------------------
leer_mouse proc
    mov ax, 0003h       ; Servicio 0003h: Leer posición y estado de clics
    int 33h
    ret
leer_mouse endp

; =========================================================================
; SECCIÓN 2: RUTINAS DE DIBUJO E INTERFAZ
; =========================================================================

; -------------------------------------------------------------------------
; Subrutina: dibujar_interfaz
; Pinta la línea divisora vertical y los botones de colores a la izquierda.
; -------------------------------------------------------------------------
dibujar_interfaz proc

    ;APILAMOS
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; 1. Dibujar línea divisora vertical blanca en X = 120 (de Y=0 a Y=480)
    mov cx, 120         ; X = 120 inicial
    mov dx, 0           ; Y = 0 inicial

linea_divisora:
    mov ah, 0Ch         ; Servicio INT 10h: Escribir píxel en pantalla
    mov al, 0Fh         ; Color blanco
    mov bh, 0           ; Página 0
    int 10h
    inc dx              ; Avanzamos a la siguiente fila (Y)
    cmp dx, 480         ; Es el fin de la ventana?
    jne linea_divisora  ; Si no terminó, seguimos pintando la línea

; 2. Paleta de colores (Cuadros rectangulares de colores)
    
    ;       --- Fila 1 ---
    ; ---   Botón Rojo (Color 04h)
    mov cx, 15          ; Ubicación x
    mov dx, 20          ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 04h         ; Color Rojo
    call dibujar_rectangulo_color

    ; ---   Botón Verde (Color 02h)
    mov cx, 65          ; Ubicación x
    mov dx, 20          ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 02h         ; Color Verde
    call dibujar_rectangulo_color

    ;       --- Fila 2 ---
    ; ---   Botón Azul (Color 01h)
    mov cx, 15          ; Ubicación x
    mov dx, 60          ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 01h         ; Color Azul
    call dibujar_rectangulo_color

    ; ---   Botón Amarillo (Color 0Eh)
    mov cx, 65          ; Ubicación x
    mov dx, 60          ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 0Eh         ; Color Amarillo
    call dibujar_rectangulo_color

    ;       --- Fila 3 ---
    ; ---   Botón Blanco (Color 0Fh)
    mov cx, 15          ; Ubicación x
    mov dx, 100         ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 0Fh         ; Color Blanco
    call dibujar_rectangulo_color

    ; ---   Botón Cian (Color 03h)
    mov cx, 65          ; Ubicación x
    mov dx, 100         ; Ubicación y
    mov si, 35          ; Ancho (col)
    mov di, 25          ; Alto (fil)
    mov al, 03h         ; Color Cian
    call dibujar_rectangulo_color

    ;DESAPILAMOS
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_interfaz endp

; -------------------------------------------------------------------------
; Subrutina: dibujar_rectangulo_color
; Parámetros de entrada: 
;   CX = Inicio X | DX = Inicio Y | SI = Ancho | DI = Alto | AL = Color
; -------------------------------------------------------------------------
dibujar_rectangulo_color proc
    ;APILAMOS
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bl, al          ; Guardamos el color en BL
    mov bp, cx          ; Guardamos la coordenada X inicial en BP

filas_loop:
    push di             ; Guardamos el contador de filas (alto)
    mov cx, bp          ; Reseteamos X al inicio del ancho para la nueva fila
    mov di, si          ; Cargar contador de columnas (ancho)

columnas_loop:
    mov ah, 0Ch         ; Servicio INT 10h: Pintar píxel
    mov al, bl          ; Paso el Color
    mov bh, 0
    int 10h
    inc cx              ; Siguiente píxel horizontal (x)
    dec di              ; Baja el seguimiento del ancho
    jnz columnas_loop   ; Mientras no sea 0, seguir pintando fila

    pop di              ; Recuperar contador de filas
    inc dx              ; Avanzar a la siguiente fila vertical
    dec di              ; Decrementar contador de filas
    jnz filas_loop      ; Mientras no sea 0, seguir con la siguiente fila

    ;DESAPILAMOS
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rectangulo_color endp

; -------------------------------------------------------------------------
; Subrutina: pintar_trazo
; Entradas: DL = Columna Texto (X), DH = Fila Texto (Y), 
;           AL = Carácter ASCII, BL = Color, AH = Tamaño (1, 2 o 3)
; -------------------------------------------------------------------------
pintar_trazo proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ch, ah          ; CH guarda el tamaño (1, 2 o 3)
    mov si, dx          ; SI resguarda (DL = Columna base, DH = Fila base)

bucle_filas_trazo:
    push cx
    mov dx, si          ; Restaurar columna/fila base
    mov cl, ch          ; Resetear contador horizontal al tamaño

bucle_columnas_trazo:
    push cx
    ; 1. Posicionar el cursor en (DL, DH)
    mov ah, 02h
    mov bh, 00h
    int 10h

    ; 2. Imprimir carácter seleccionado con color
    mov ah, 09h
    mov bh, 00h
    mov cx, 1           ; Imprimir 1 carácter en este casillero
    int 10h

    inc dl              ; Siguiente columna horizontal
    pop cx
    dec cl
    jnz bucle_columnas_trazo

    inc dh              ; Avanzar a la siguiente fila vertical
    mov si, dx          ; Actualizar fila base en SI
    pop cx
    dec ch
    jnz bucle_filas_trazo

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
pintar_trazo endp

; =========================================================================
; SECCIÓN 3: ISR INTERRUPCIÓN PROPIA (INT 60h)
; =========================================================================

; -------------------------------------------------------------------------
; Subrutina ISR: limpiarLienzoISR
; Rutina atendida al ejecutar la interrupción INT 60h. Pinta de negro
; únicamente la zona de dibujo (lienzo).
; -------------------------------------------------------------------------
limpiarLienzoISR proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    mov ax, @data
    mov ds, ax

    ; 1. Ocultar el cursor del ratón temporalmente
    mov ax, 0002h
    int 33h

    ; 2. Pinta de negro todo el lienzo (X: 121 a 639, Y: 0 a 479)
    mov cx, 121         ; X inicial (después de la línea divisora)
    mov dx, 0           ; Y inicial
    mov si, 518         ; Ancho del lienzo (639 - 121)
    mov di, 480         ; Alto del lienzo
    mov al, 00h         ; Color negro
    call dibujar_rectangulo_color

    ; 3. Restaurar visibilidad del ratón
    mov ax, 0001h
    int 33h

    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret                ; IRET para finalizar la rutina de interrupción
limpiarLienzoISR endp

end