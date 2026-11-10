.8086
.model small
.stack 100h

.data
    msg_borrador    db "BORRADOR", 24h
    msg_borrarTodo  db "BORRAR TODO", 24h

.code

public dibujar_interfaz
public dibujar_rectangulo_color

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

     ; HERRAMIENTAS
        
    ; Borrador
    ; Posicionar cursor y escribir borrador
    mov ah, 02h
    mov bh, 0
    mov dh, 9
    mov dl, 3
    int 10h

    mov ah, 9
    mov dx, offset msg_borrador
    int 21h

    ; Borrar todo
    ; Posicionar cursor y escribir borrar todo
    mov ah, 02h
    mov bh, 0
    mov dh, 11
    mov dl, 2
    int 10h

    mov ah, 9
    mov dx, offset msg_borrarTodo
    int 21h
    
    ;DESAPILAMOS
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_interfaz endp


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

end