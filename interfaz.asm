.8086
.model small
.stack 100h

extrn tamanio_pincel:byte ;importamos la variable

.data
    ;interfaz
    msg_borrador       db "BORRADOR", 24h
    msg_borrarTodo     db "BORRAR TODO", 24h
    msg_colores        db "-COLORES-", 24h
    msg_guardar        db "GUARDAR", 24h
    msg_cargar         db "CARGAR", 24h
    msg_esc_salir      db "ESC PARA SALIR", 24h
    msg_herramientas   db "-HERRAMIENTAS-", 24h
    msg_pinceles       db "-PINCEL-", 24h

    ;pinceles
    msg_1_asterisco    db "[*]", 24h
    msg_2_numeral      db "[#]", 24h
    msg_3_bloque       db "[", 219, "]", 24h
    msg_4_punto        db "[.]", 24h
    msg_5_guion        db "[-]", 24h
    msg_6_wave         db "[~]", 24h
    msg_menos          db "-", 24h
    msg_mas            db "+", 24h

    ;intro
    msg_titulo      db "ASCII PAINT", 24H
    msg_integrantes db "INTEGRANTES:", 24h
    msg_integ1      db "- Gentta Ivan", 24h
    msg_integ2      db "- Gimenez Agustin", 24h
    msg_integ3      db "- Zarate Alaciel", 24h
    msg_enter       db "Pulse ENTER para comenzar...", 24h

.code

;rutinas
public dibujar_intro
public dibujar_interfaz
public dibujar_rectangulo_color

dibujar_intro proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ;Marcos blancos exteriores
    ; Borde superior (fila 1) e inferior (fila 28)
    mov dh, 1
    mov dl, 2

;Superioir
borde_horiz_sup:
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 09h
    mov al, 219d        ; Bloque solido
    mov bl, 0Fh         ; Blanco
    mov cx, 1
    int 10h
    inc dl
    cmp dl, 78
    jb borde_horiz_sup

    mov dh, 28
    mov dl, 2

;Inferior
borde_horiz_inf:
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 09h
    mov al, 219d
    mov bl, 0Fh
    mov cx, 1
    int 10h
    inc dl
    cmp dl, 78
    jb borde_horiz_inf

    ; Titulo y subtitulo
    mov ah, 02h
    mov bh, 0
    mov dh, 4           ; Fila 4
    mov dl, 34          ; Columna 34
    int 10h

    mov ah, 09h
    mov dx, offset msg_titulo   ;"ASCII PAINT"
    int 21h

    mov ah, 02h
    mov bh, 0
    mov dh, 6           ; Fila 6
    mov dl, 24          ; Columna 24
    int 10h

    ;Muestreo colores + Simbolos ASCII
    mov cx, 195
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 04h         ; Rojo
    call dibujar_rectangulo_color

    mov cx, 238
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 02h         ; Verde
    call dibujar_rectangulo_color

    mov cx, 281
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 01h         ; Azul
    call dibujar_rectangulo_color

    mov cx, 324
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 0Eh         ; Amarillo
    call dibujar_rectangulo_color

    mov cx, 367
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 0Fh         ; Blanco
    call dibujar_rectangulo_color

    mov cx, 410
    mov dx, 135
    mov si, 30
    mov di, 20
    mov al, 03h         ; Cian
    call dibujar_rectangulo_color

    ; Debajo de los colores, mostramos los simbolos ASCII del pincel
    mov ah, 02h
    mov bh, 0
    mov dh, 11
    mov dl, 26
    int 10h
    mov ah, 09h
    mov al, '*'         ; Pincel 1
    mov bl, 04h         ; Rojo
    mov cx, 3
    int 10h

    mov ah, 02h
    mov dh, 11
    mov dl, 32
    int 10h
    mov ah, 09h
    mov al, '#'         ; Pincel 2
    mov bl, 02h         ; Verde
    mov cx, 3
    int 10h

    mov ah, 02h
    mov dh, 11
    mov dl, 38
    int 10h
    mov ah, 09h
    mov al, 219d        ; Pincel 3 (Bloque)
    mov bl, 0Eh         ; Amarillo
    mov cx, 3
    int 10h

    mov ah, 02h
    mov dh, 11
    mov dl, 44
    int 10h
    mov ah, 09h
    mov al, 196d        ; Pincel 5 (Linea)
    mov bl, 03h         ; Cian
    mov cx, 3
    int 10h

    mov ah, 02h
    mov dh, 11
    mov dl, 50
    int 10h
    mov ah, 09h
    mov al, '.'         ; Pincel 4 (Punto)
    mov bl, 0Fh         ; Blanco
    mov cx, 3
    int 10h

    ;integrantes
    mov ah, 02h
    mov bh, 0
    mov dh, 15
    mov dl, 33
    int 10h
    mov ah, 09h
    mov dx, offset msg_integrantes
    int 21h

    mov ah, 02h
    mov dh, 17
    mov dl, 31
    int 10h
    mov ah, 09h
    mov dx, offset msg_integ1
    int 21h

    mov ah, 02h
    mov dh, 18
    mov dl, 31
    int 10h
    mov ah, 09h
    mov dx, offset msg_integ2
    int 21h

    mov ah, 02h
    mov dh, 19
    mov dl, 31
    int 10h
    mov ah, 09h
    mov dx, offset msg_integ3
    int 21h

    ;Mensaje Inferior
    mov ah, 02h
    mov bh, 0
    mov dh, 24
    mov dl, 26
    int 10h
    mov ah, 09h
    mov dx, offset msg_enter    ; "Pulse Ennter para continuar"
    int 21h

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_intro endp


dibujar_interfaz proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; LINEA DIVISORIA VERTICAL
    mov cx, 130
    mov dx, 0

linea_divisora:
    mov ah, 0Ch
    mov al, 0Fh
    mov bh, 0
    int 10h

    inc dx
    cmp dx, 480
    jne linea_divisora

    ; TITULO COLORES
    mov ah, 02h
    mov bh, 0
    mov dh, 1
    mov dl, 3
    int 10h

    mov ah, 09h
    mov dx, offset msg_colores
    int 21h

    ; FILA 1: ROJO Y VERDE

    mov cx, 15
    mov dx, 40
    mov si, 35
    mov di, 25
    mov al, 04h
    call dibujar_rectangulo_color

    mov cx, 65
    mov dx, 40
    mov si, 35
    mov di, 25
    mov al, 02h
    call dibujar_rectangulo_color

    ; FILA 2: AZUL Y AMARILLO

    mov cx, 15
    mov dx, 80
    mov si, 35
    mov di, 25
    mov al, 01h
    call dibujar_rectangulo_color

    mov cx, 65
    mov dx, 80
    mov si, 35
    mov di, 25
    mov al, 0Eh
    call dibujar_rectangulo_color

    ; FILA 3: BLANCO Y CIAN

    mov cx, 15
    mov dx, 120
    mov si, 35
    mov di, 25
    mov al, 0Fh
    call dibujar_rectangulo_color

    mov cx, 65
    mov dx, 120
    mov si, 35
    mov di, 25
    mov al, 03h
    call dibujar_rectangulo_color

    ; TITULO HERRAMIENTAS
    mov ah, 02h
    mov bh, 0
    mov dh, 10
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_herramientas
    int 21h

    ; BORRADOR
    mov ah, 02h
    mov bh, 0
    mov dh, 12
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_borrador
    int 21h

    ; BORRAR TODO
    mov ah, 02h
    mov bh, 0
    mov dh, 14
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_borrarTodo
    int 21h

    ; TITULO PINCELES
    mov ah, 02h
    mov bh, 0
    mov dh, 17
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_pinceles
    int 21h

    ; CONTROLES DE TAMANIO
    ; Boton +
    mov ah, 02h
    mov bh, 0
    mov dh, 17
    mov dl, 10
    int 10h

    mov ah, 09h
    mov dx, offset msg_mas
    int 21h

    ; Boton -
    mov ah, 02h
    mov bh, 0
    mov dh, 17
    mov dl, 14
    int 10h

    mov ah, 09h
    mov dx, offset msg_menos
    int 21h

    ; LISTA DE PINCELES
    ; Fila 1: 1 *   2 #   3 bloque

    mov ah, 02h
    mov bh, 0
    mov dh, 19
    mov dl, 2
    int 10h

    mov ah, 09h
    mov dx, offset msg_1_asterisco
    int 21h

    mov ah, 02h
    mov bh, 0
    mov dh, 19
    mov dl, 7
    int 10h

    mov ah, 09h
    mov dx, offset msg_2_numeral
    int 21h

    mov ah, 02h
    mov bh, 0
    mov dh, 19
    mov dl, 12
    int 10h

    mov ah, 09h
    mov dx, offset msg_3_bloque
    int 21h

    ; Fila 2: 4 .  5 - 6 ~
    mov ah, 02h
    mov bh, 0
    mov dh, 21
    mov dl, 2
    int 10h

    mov ah, 09h
    mov dx, offset msg_4_punto
    int 21h

    mov ah, 02h
    mov bh, 0
    mov dh, 21
    mov dl, 7
    int 10h

    mov ah, 09h
    mov dx, offset msg_5_guion
    int 21h

    mov ah, 02h
    mov bh, 0
    mov dh, 21
    mov dl, 12
    int 10h

    mov ah, 09h
    mov dx, offset msg_6_wave
    int 21h

    ; LINEA DIVISORIA HORIZONTAL
    mov cx, 0
    mov dx, 360

segunda_linea_divisoria_horizontal:
    mov ah, 0Ch
    mov al, 0Fh
    mov bh, 0
    int 10h

    inc cx
    cmp cx, 130
    jne segunda_linea_divisoria_horizontal

    ; GUARDAR
    mov ah, 02h
    mov bh, 0
    mov dh, 24
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_guardar
    int 21h

    ; CARGAR
    mov ah, 02h
    mov bh, 0
    mov dh, 26
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_cargar
    int 21h

    ; SALIR
    mov ah, 02h
    mov bh, 0
    mov dh, 28
    mov dl, 1
    int 10h

    mov ah, 09h
    mov dx, offset msg_esc_salir
    int 21h

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

dibujar_interfaz endp

; DIBUJAR RECTANGULO DE COLOR
dibujar_rectangulo_color proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bl, al
    mov bp, cx

filas_loop:
    push di

    mov cx, bp
    mov di, si

columnas_loop:
    mov ah, 0Ch
    mov al, bl
    mov bh, 0
    int 10h

    inc cx
    dec di
    jnz columnas_loop

    pop di

    inc dx
    dec di
    jnz filas_loop

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
