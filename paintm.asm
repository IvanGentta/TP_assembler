.8086
.model small
.stack 100h

.data
    mouse_x dw 0
    mouse_y dw 0
    mouse_status dw 0
    color_actual db 0fh ; Blanco por defecto
    char_actual db '*'  ; Asterisco por defecto
    tamanio_pincel db 1

.code
EXTRN dibujarInterfaz:PROC ;asi lo manejaba el profe?

main proc
    mov ax, @data
    mov ds, ax

    ; CONFIG MODO GRAFICO (640x480 16 colores VGA)
    mov ah, 00h
    mov al, 12h
    int 10h

    ; INICIALIZAR Y MOSTRAR CURSOR DEL MOUSE
    mov ax, 0000h ; AX=0: Inicializar mouse
    int 33h

    mov ax, 0001h ; AX=1: Mostrar cursor
    int 33h

    ; DIBUJAR INTERFAZ (Desde interfaz.asm)
    call dibujarInterfaz

proceso:
    mov ax, 0003h ; Leer estado del mouse (CX=X, DX=Y, BX=Botones)
    int 33h
    mov mouse_x, cx
    mov mouse_y, dx
    mov mouse_status, bx

    ; VERIFICAR CLICK
    cmp bx, 1
    je procesar_click

    ; TECLA ESC PARA SALIR
    mov ah, 01h
    int 16h
    jz proceso ; No hay tecla presionada

    mov ah, 00h
    int 16h
    cmp al, 27 ; ¿Es la tecla ESC?
    je salto_esc_fin
    jmp proceso

procesar_click:
    ; ¿CLICK EN LIENZO O MENU?
    cmp mouse_x, 130
    ja dibujar_lienzo ; Si X > 130, está en el lienzo
    jmp verificar_menu ; Si X <= 130, está en la barra lateral

dibujar_lienzo:
    ; 1. Ocultar cursor del mouse temporalmente rompe caracteres si no, no se porque xd
    mov ax, 0002h
    int 33h

    ; 2. Convertir coordenadas de píxel a coordenadas de texto
    mov ax, mouse_x
    mov cl, 3
    shr ax, cl ; Divide X por 8 -> Columna (DL)
    mov dl, al

    mov ax, mouse_y
    mov cl, 4
    shr ax, cl ; Divide Y por 16 -> Fila (DH)
    mov dh, al

    ; 3. Posicionar el cursor de texto
    mov ah, 02h
    mov bh, 0
    int 10h

    ; 4. Imprimir el carácter con el color seleccionado
    mov ah, 09h
    mov al, char_actual
    mov bh, 0
    mov bl, color_actual
    mov cx, 1
    int 10h

    ; 5. Volver a mostrar el cursor del mouse
    mov ax, 0001h
    int 33h
    jmp proceso

verificar_menu:
    ; FILA 1: Y entre 20 y 45 (Rojo / Verde)
    cmp mouse_y, 20
    jb salto_fin_menu
    cmp mouse_y, 45
    ja comprobar_fila2

    ; ¿Click en Botón Rojo? (X: 15 a 50)
    cmp mouse_x, 15
    jb salto_fin_menu
    cmp mouse_x, 50
    ja comprobar_verde
    mov color_actual, 04h ; Cambiar a Rojo (Color 4)
    jmp fin_menu


; SALTOS INTERMEDIOS 
; evita out of range de salton condicionales

salto_esc_fin:
    jmp fin

salto_fin_menu:
    jmp fin_menu

comprobar_verde:
    ; ¿Click en Botón Verde? (X: 65 a 100)
    cmp mouse_x, 65
    jb salto_fin_menu
    cmp mouse_x, 100
    ja salto_fin_menu
    mov color_actual, 02h ; Cambiar a Verde (Color 2)
    jmp fin_menu

comprobar_fila2:
    ; FILA 2: Y entre 60 y 85 (Azul / Amarillo)
    cmp mouse_y, 60
    jb salto_fin_menu
    cmp mouse_y, 85
    ja comprobar_fila3

    ; ¿Click en Botón Azul? (X: 15 a 50)
    cmp mouse_x, 15
    jb salto_fin_menu
    cmp mouse_x, 50
    ja comprobar_amarillo
    mov color_actual, 01h ; Cambiar a Azul (Color 1)
    jmp fin_menu

comprobar_amarillo:
    ; ¿Click en Botón Amarillo? (X: 65 a 100)
    cmp mouse_x, 65
    jb salto_fin_menu
    cmp mouse_x, 100
    ja salto_fin_menu
    mov color_actual, 0eh ; Cambiar a Amarillo (Color 14)
    jmp fin_menu

comprobar_fila3:
    ; FILA 3: Y entre 100 y 125 (Blanco / Cian)
    cmp mouse_y, 100
    jb fin_menu
    cmp mouse_y, 125
    ja fin_menu

    ; ¿Click en Botón Blanco? (X: 15 a 50)
    cmp mouse_x, 15
    jb fin_menu
    cmp mouse_x, 50
    ja comprobar_cian
    mov color_actual, 0fh ; Cambiar a Blanco (Color 15)
    jmp fin_menu

comprobar_cian:
    ; ¿Click en Botón Cian? (X: 65 a 100)
    cmp mouse_x, 65
    jb fin_menu
    cmp mouse_x, 100
    ja fin_menu
    mov color_actual, 03h ; Cambiar a Cian (Color 3)
    jmp fin_menu

fin_menu:
    jmp proceso

fin:
    ; RESTAURAR MODO TEXTO DE DOSBOX
    mov ah, 00h
    mov al, 03h
    int 10h

    mov ax, 4c00h
    int 21h
main endp

end main
