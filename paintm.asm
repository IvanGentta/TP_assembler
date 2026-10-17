.8086
.model small
.stack 100h

.data
    mouse_x dw 0
    mouse_y dw 0
    mouse_status dw 0
    color_actual db 0fh ;blanco por defecto
    char_actual db '*' 	;asterisco por defecto
    tamanio_pincel db 1

.code
main proc
    mov ax, @data
    mov ds, ax

    ;CONFIG MODO GRAFICO/VENTANA (640x480 16 colores vga)
    mov ah, 00h
    mov al, 12h
    int 10h

    ;CURSOR
    mov ax, 0000h ;ax=0 inicializar mouse
    int 33h

    mov ax, 0001h ; ax=1 mostrar cursor
    int 33h

    ;INTERFAZ
    call dibujarInterfaz

proceso:
    mov ax, 0003h ;ax=3 leer estado del mouse
    int 33h
    ;Retorna cx=posicion x, dx=posicion y, bx=estado click 1=click izquierdo

    mov mouse_x, cx
    mov mouse_y, dx
    mov mouse_status, bx

    ;VERIFICAR CLICK
    cmp bx, 1
    jne no_click
    call procesar_click

no_click:
    ;TECLA ESC PARA SALIR
    mov ah, 01h
    int 16h
    jz proceso ;no hay tecla presionada

    mov ah, 00h
    int 16h
    cmp al, 27 ;hay tecla presionada, es esc?
    je fin
    jmp proceso

fin:
    ;RESTAURA MODO TEXTO DOSBOX ??
    mov ah, 00h
    mov al, 03h
    int 10h

    mov ax, 4c00h
    int 21h
main endp

procesar_click proc
    ;CLICK EN LIENZO O MENU??
    cmp mouse_x, 120
    ja dibujar_lienzo ; Si X > 120, está en el lienzo
    				  ; Si X <= 120, está en el panel del menu
    call verificar_menu
    ret

dibujar_lienzo:
    ; Ocultar cursor del mouse temporalmente
    mov ax, 0002h
    int 33h

    ; Pintar píxel en (mouse_x, mouse_y)
    mov ah, 0ch 		 ; Servicio pintar píxel
    mov al, color_actual ; Color seleccionado
    mov bh, 0 			 ; Página 0 ??
    mov cx, mouse_x 	 ; Coordenada X
    mov dx, mouse_y 	 ; Coordenada Y
    int 10h

    ; Volver a mostrar el cursor del mouse
    mov ax, 0001h
    int 33h
    ret
procesar_click endp

;MENU COLORES
verificar_menu proc
    ; FILA 1: Y entre 20 y 45 (Rojo / Verde)
    cmp mouse_y, 20
    jae y_min_fila1
    ret

y_min_fila1:
    cmp mouse_y, 45
    ja comprobar_fila2

    ; Click en Botón Rojo? (X: 15 a 50)
    cmp mouse_x, 15
    jae x_min_rojo
    ret

x_min_rojo:
    cmp mouse_x, 50
    ja comprobar_verde
    mov color_actual, 04h ; Cambiar a Rojo (Color 4)
    ret

comprobar_verde:
    ; Click en Botón Verde? (X: 65 a 100)
    cmp mouse_x, 65
    jae x_min_verde
    ret

x_min_verde:
    cmp mouse_x, 100
    jbe es_verde
    ret

es_verde:
    mov color_actual, 02h ; Cambiar a Verde (Color 2)
    ret

comprobar_fila2:
    ; FILA 2: Y entre 60 y 85 (Azul / Amarillo)
    cmp mouse_y, 60
    jae y_min_fila2
    ret

y_min_fila2:
    cmp mouse_y, 85
    ja comprobar_fila3

    ; Click en Botón Azul? (X: 15 a 50)
    cmp mouse_x, 15
    jae x_min_azul
    ret

x_min_azul:
    cmp mouse_x, 50
    ja comprobar_amarillo
    mov color_actual, 01h ; Cambiar a Azul (Color 1)
    ret

comprobar_amarillo:
    ; Click en Botón Amarillo? (X: 65 a 100)
    cmp mouse_x, 65
    jae x_min_amarillo
    ret

x_min_amarillo:
    cmp mouse_x, 100
    jbe es_amarillo
    ret

es_amarillo:
    mov color_actual, 0eh ; Cambiar a Amarillo (Color 14)
    ret

comprobar_fila3:
    ; FILA 3: Y entre 100 y 125 (Blanco / Cian)
    cmp mouse_y, 100
    jae y_min_fila3
    ret

y_min_fila3:
    cmp mouse_y, 125
    jbe en_fila3
    ret

en_fila3:
    ; Click en Botón Blanco? (X: 15 a 50)
    cmp mouse_x, 15
    jae x_min_blanco
    ret

x_min_blanco:
    cmp mouse_x, 50
    ja comprobar_cian
    mov color_actual, 0fh ; Cambiar a Blanco (Color 15)
    ret

comprobar_cian:
    ; Click en Botón Cian? (X: 65 a 100)
    cmp mouse_x, 65
    jae x_min_cian
    ret

x_min_cian:
    cmp mouse_x, 100
    jbe es_cian
    ret

es_cian:
    mov color_actual, 03h ; Cambiar a Cian (Color 3)
    ret
verificar_menu endp

;INTERFAZ
dibujarInterfaz proc
    ;linea divisora
    mov cx, 120 ; x= 120
    mov dx, 0 ; y = 0

linea_divisora:
    mov ah, 0Ch ; servicio de pintar pixel
    mov al, 0Fh ; color blanco
    mov bh, 0
    int 10h
    inc dx
    cmp dx, 480 ; fin ventana
    jne linea_divisora

    ; paleta de colores
    mov cx, 15 ; ubicacion x
    mov dx, 20 ; ubicacion y
    mov si, 35 ; ancho
    mov di, 25 ; alto
    mov al, 04h ; color rojo
    call dibujarRectanguloColor

    mov cx, 65 ; ubicacion x
    mov dx, 20 ; ubicacion y
    mov si, 35 ; Ancho
    mov di, 25 ; Alto
    mov al, 02h ; Color Verde
    call dibujarRectanguloColor

    mov cx, 15 ; ubicacion x
    mov dx, 60 ; ubicacion y
    mov si, 35 ; Ancho
    mov di, 25 ; alto
    mov al, 01h ; Color Azul
    call dibujarRectanguloColor

    mov cx, 65 ; ubicacion x
    mov dx, 60 ; ubicacion y
    mov si, 35 ; Ancho
    mov di, 25 ; alto
    mov al, 0eh ; Color Amarillo
    call dibujarRectanguloColor

    mov cx, 15 ; ubicacion x
    mov dx, 100 ; ubicacion y
    mov si, 35 ; Ancho
    mov di, 25 ; alto
    mov al, 0fh ; Color Blanco
    call dibujarRectanguloColor

    mov cx, 65 ; ubicacion x
    mov dx, 100 ; ubicacion y
    mov si, 35 ; Ancho
    mov di, 25 ; alto
    mov al, 03h ; Color Cian
    call dibujarRectanguloColor

    ret
dibujarInterfaz endp


dibujarRectanguloColor proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bl, al ; se guarda el color en bl
    mov bp, cx ; se guarda donde arranca x en bp

filas_loop:
    push di    ; se guarda contador de filas
    mov cx, bp ; resetea x al inicio de la fila
    mov di, si ; contador de columnas

columnas_loop:
    mov ah, 0Ch ; servicio de pintar pixel
    mov al, bl 	; se pasa el color
    mov bh, 0
    int 10h
    inc cx 		; siguiente x
    dec di 		; baja el seguimiento del ancho, al llegar 0 termina
    jnz columnas_loop

    pop di ; restauramos contador de filas
    inc dx ; siguiente y
    dec di ; baja el seguimiento del alto, si llega a 0 termina
    jnz filas_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujarRectanguloColor endp

end main