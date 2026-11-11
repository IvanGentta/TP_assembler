.8086
.model small
.stack 100h

public init_mouse
public leer_mouse
public limpiar_pantalla
public pintar_trazo
public limpiarLienzoISR
extrn dibujar_rectangulo_color:PROC

.data

.code
; Pone la pantalla en modo gráfico 640x480 de 16 colores (limpia todo).
limpiar_pantalla proc
    push ax
    mov ax, 0012h       ; Servicio 00h de INT 10h: Modo VGA 640x480
    int 10h
    pop ax
    ret
limpiar_pantalla endp

; Inicializa el driver del mouse y lo muestra en pantalla.
init_mouse proc
    push bx
    mov ax, 0000h       ; Servicio 0000h: Reset / Inicializar ratón
    int 33h
    
    mov ax, 0001h       ; Servicio 0001h: Mostrar el puntero gráfico
    int 33h
    pop bx
    ret
init_mouse endp

; Retorna: BX = Botones (Bit 0=Izq, Bit 1=Der), CX = X, DX = Y
leer_mouse proc
    mov ax, 0003h       ; Servicio 0003h: Leer posición y estado de clics
    int 33h
    ret
leer_mouse endp

; Entradas: DL = Columna Texto (X), DH = Fila Texto (Y), 
;           AL = Carácter ASCII, BL = Color, AH = Tamaño (1, 2 o 3)
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
    ; Posicionar el cursor en (DL, DH)
    mov ah, 02h
    mov bh, 00h
    int 10h

    ; Imprimir carácter seleccionado con color
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


;ISR INTERRUPCIÓN PROPIA (INT 60h)
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

    ; Ocultar el cursor del ratón temporalmente
    mov ax, 0002h
    int 33h

    ; Pinta de negro todo el lienzo (X: 121 a 639, Y: 0 a 479)
    mov cx, 121         ; X inicial (después de la línea divisora)
    mov dx, 0           ; Y inicial
    mov si, 518         ; Ancho del lienzo (639 - 121)
    mov di, 480         ; Alto del lienzo
    mov al, 00h         ; Color negro
    call dibujar_rectangulo_color

    ;Restaurar visibilidad del ratón
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
    iret        
limpiarLienzoISR endp

end
