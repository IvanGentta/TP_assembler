.8086
.model small
.stack 100h

.data
    mouse_x         dw 0
    mouse_y         dw 0
    mouse_status    dw 0
    color_actual    db 0fh ; Blanco por defecto
    char_actual     db '*'  ; Asterisco por defecto
    tamanio_pincel  db 1

    ; Variables de interrupcion propia para limpiar pantalla
    vector_num      db 60h
    vector_offset   dw 0
    vector_segment  dw 0

.code
EXTRN dibujarInterfaz:PROC ;asi lo manejaba el profe?
EXTRN dibujarRectanguloColor:PROC

main proc
    mov ax, @data
    mov ds, ax

    ; CONFIG VECTOR INTERRUPCION PROPIA
    ;guardar vector en int 60h
    mov ah, 35h
    mov al, vector_num
    int 21h
    mov vector_segment, es
    mov vector_offset, bx

    ;inicializar interrupcion propia
    mov al, vector_num
    mov dx, offset limpiarLienzoISR

    push ds
    push cs
    pop ds              ; DS = CS, ahora apunta al segmento de código
    
    mov ah, 25h
    int 21h
    pop ds   

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
    mov char_actual, '*'
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
    mov char_actual, '*' ;provisorio hardcodeado para que el borrador no rompa
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
    mov char_actual, '*' ;provisorio hardcodeado para que el borrador no rompa
jmp fin_menu

comprobar_amarillo:
    ; ¿Click en Botón Amarillo? (X: 65 a 100)
    cmp mouse_x, 65
    jb salto_fin_menu
    cmp mouse_x, 100
    ja salto_fin_menu
    mov color_actual, 0eh ; Cambiar a Amarillo (Color 14)
    mov char_actual, '*' ;provisorio hardcodeado para que el borrador no rompa
jmp fin_menu

comprobar_fila3:
    ; FILA 3: Y entre 100 y 125 (Blanco / Cian)
    cmp mouse_y, 100
    jb salto_fin_menu
    cmp mouse_y, 125
    ja comprobar_borrador

    ; ¿Click en Botón Blanco? (X: 15 a 50)
    cmp mouse_x, 15
    jb salto_fin_menu
    cmp mouse_x, 50
    ja comprobar_cian
    mov color_actual, 0fh ; Cambiar a Blanco (Color 15)
    mov char_actual, '*' ;provisorio hardcodeado para que el borrador no rompa
jmp fin_menu

comprobar_cian:
    ; ¿Click en Botón Cian? (X: 65 a 100)
    cmp mouse_x, 65
    jb salto_fin_menu2
    cmp mouse_x, 100
    ja salto_fin_menu2
    mov color_actual, 03h ; Cambiar a Cian (Color 3)
    mov char_actual, '*' ;provisorio hardcodeado para que el borrador no rompa
jmp fin_menu

salto_fin_menu2:
    jmp fin_menu

comprobar_borrador:
; click en borrador? (Y: 140 a 165)
    cmp mouse_y, 140 
    jb comprobar_borrar_todo 
    cmp mouse_y, 165 
    ja comprobar_borrar_todo

    cmp mouse_x, 15 
    jb salto_fin_menu2 
    cmp mouse_x, 100 
    ja salto_fin_menu2

    mov char_actual, ' '
jmp fin_menu

comprobar_borrar_todo:
; click en borrador todo? (Y: 175 a 200)
    cmp mouse_y, 175
    jb salto_fin_menu2
    cmp mouse_y, 200
    ja salto_fin_menu2

    cmp mouse_x, 15
    jb salto_fin_menu2
    cmp mouse_x, 100
    ja salto_fin_menu2

    ;ejecuta interrupcion propia
    int 60h
jmp fin_menu

fin_menu:
esperar_soltar: ;Evita que manteniendo el click se pueda seleccionar otros botones
    mov ax, 0003h
    int 33h
    cmp bx, 0
    jne esperar_soltar

    jmp proceso

fin:
    ; RESTAURAR VECTOR ORIGINAL DE INT 60H
    mov al, vector_num
    mov dx, vector_offset
    mov bx, vector_segment
    push ds
    
    mov ds, bx          
    mov ah, 25h
    int 21h
    
    pop ds

    ; RESTAURAR MODO TEXTO DE DOSBOX
    mov ah, 00h
    mov al, 03h
    int 10h

    mov ax, 4c00h
    int 21h
main endp

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

    ; Ocultar cursor 
    mov ax, 0002h 
    int 33h 

    ; Pinta de negro todo el lienzo (X: 121 a 639, Y: 0 a 479) 
    mov cx, 121 
    mov dx, 0 
    mov si, 519 
    mov di, 480 
    mov al, 00h 
    call dibujarRectanguloColor 

    ; Mostrar cursor 
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
    iret ; IRET para finalizar la ISR
limpiarLienzoISR endp

end
