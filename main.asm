.8086
.model small
.stack 100h

; =========================================================================
; DECLARACIÓN DE SUBRUTINAS EXTERNAS (Definidas en lib.asm)
; =========================================================================
extrn init_mouse:proc
extrn leer_mouse:proc
extrn limpiar_pantalla:proc
extrn dibujar_interfaz:proc
extrn pintar_trazo:proc
extrn limpiarLienzoISR:proc

.data
    ; Coordenadas y estado del mouse
    mouse_x         dw 0
    mouse_y         dw 0
    mouse_status    dw 0

    ; Estado del pincel
    color_actual    db 0Fh     ; Blanco por defecto (Color 15)
    char_actual     db '*'     ; Carácter '*' por defecto
    tamanio_pincel  db 1       ; Tamaño 1x1 por defecto

    ; Resguardo del vector de la interrupción propia INT 60h
    vector_num      db 60h
    vector_offset   dw 0
    vector_segment  dw 0

.code
main proc
    ; 1. Inicializar el Segmento de Datos (DS)
    mov ax, @data
    mov ds, ax

    ; 2. Configurar e instalar la interrupción propia (INT 60h)
    mov ah, 35h
    mov al, vector_num
    int 21h
    mov vector_segment, es
    mov vector_offset, bx

    mov al, vector_num
    mov dx, offset limpiarLienzoISR
    push ds
    push cs
    pop ds              ; DS = CS para apuntar a la rutina de código
    mov ah, 25h
    int 21h
    pop ds   

    ; 3. Activar Modo Gráfico VGA (640x480, 16 colores) y limpiar lienzo
    call limpiar_pantalla

    ; 4. Dibujar la interfaz (barra divisora y paleta de colores)
    call dibujar_interfaz

    ; 5. Inicializar y mostrar el cursor del ratón
    call init_mouse

; =========================================================================
; BUCLE PRINCIPAL (Escucha de Teclado y Mouse)
; =========================================================================
proceso:
    ; A. Leer estado del mouse
    call leer_mouse     ; Retorna: BX = Botones, CX = X, DX = Y
    mov mouse_x, cx
    mov mouse_y, dx
    mov mouse_status, bx

    ; Verificar si se hizo clic izquierdo (BX = 1)
    cmp bx, 1
    je salto_procesar_click

    ; B. Verificar lectura de teclado (INT 16h / AH=01h sin bloquear)
    mov ah, 01h
    int 16h
    jz continuar_loop   ; Si no hay tecla presionada, continuar en el bucle

    ; Consumir la tecla presionada (INT 16h / AH=00h)
    mov ah, 00h
    int 16h

    ; --- SELECCIÓN DE CARÁCTER ASCII (Teclas 1 a 5) ---
    cmp al, '1'
    jne check_2
    mov char_actual, '*'
    jmp continuar_loop

check_2:
    cmp al, '2'
    jne check_3
    mov char_actual, '#'
    jmp continuar_loop

check_3:
    cmp al, '3'
    jne check_4
    mov char_actual, 219d     ; Bloque sólido ASCII (DBh)
    jmp continuar_loop

check_4:
    cmp al, '4'
    jne check_5
    mov char_actual, '.'
    jmp continuar_loop

check_5:
    cmp al, '5'
    jne check_mas
    mov char_actual, 196d     ; Línea horizontal ASCII (C4h)
    jmp continuar_loop

    ; --- TAMAÑO DE PINCEL (Teclas + y -) ---
check_mas:
    cmp al, '+'
    jne check_menos
    cmp tamanio_pincel, 3     ; Límite máximo: 3x3
    jae continuar_loop
    inc tamanio_pincel
    jmp continuar_loop

check_menos:
    cmp al, '-'
    jne check_esc
    cmp tamanio_pincel, 1     ; Límite mínimo: 1x1
    jbe continuar_loop
    dec tamanio_pincel
    jmp continuar_loop

    ; --- SALIR CON LA TECLA ESC (ASCII 1Bh / 27) ---
check_esc:
    cmp al, 1Bh
    je salto_salir_paint

continuar_loop:
    jmp proceso

; =========================================================================
; TRAMPOLINES DE SALTO (Para evitar "Relative jump out of range")
; =========================================================================
salto_procesar_click:
    jmp procesar_click

salto_salir_paint:
    jmp salir_paint

salto_fin_menu:
    jmp fin_menu

salto_proceso:
    jmp proceso

; =========================================================================
; MANEJO DE CLIC DEL MOUSE (Lienzo vs. Menú Lateral)
; =========================================================================
procesar_click:
    cmp mouse_x, 120
    ja dibujar_lienzo         ; Si X > 120, pintar en la zona de lienzo
    jmp verificar_menu        ; Si X <= 120, procesar botón de la interfaz

dibujar_lienzo:
    ; 1. Ocultar cursor temporalmente para no corromper la pantalla
    mov ax, 0002h
    int 33h

    ; 2. Convertir píxeles a grilla de texto 80x25 (X / 8, Y / 16)
    mov ax, mouse_x
    mov cl, 3
    shr ax, cl                ; DL = Columna (X / 8)
    mov dl, al

    mov ax, mouse_y
    mov cl, 4
    shr ax, cl                ; DH = Fila (Y / 16)
    mov dh, al

    ; 3. Cargar parámetros y llamar a la rutina de dibujo de trazo
    mov al, char_actual
    mov bl, color_actual
    mov ah, tamanio_pincel
    call pintar_trazo

    ; 4. Mostrar nuevamente el cursor del mouse
    mov ax, 0001h
    int 33h
    jmp salto_proceso


; =========================================================================
; VERIFICACIÓN DE CLIC EN LA PALETA DE COLORES (X: 0 a 120)
; =========================================================================
verificar_menu:
    ; FILA 1: Y entre 20 y 45 (Rojo / Verde)
    cmp mouse_y, 20
    jae menu_y20_ok
    jmp fin_menu

menu_y20_ok:
    cmp mouse_y, 45
    jbe menu_fila1_ok
    jmp comprobar_fila2

menu_fila1_ok:
    cmp mouse_x, 15
    jae menu_f1_x15_ok
    jmp fin_menu

menu_f1_x15_ok:
    cmp mouse_x, 50
    ja comprobar_verde
    mov color_actual, 04h     ; Rojo (Color 4)
    mov char_actual, '*'
    jmp fin_menu

comprobar_verde:
    cmp mouse_x, 65
    jae menu_verde_x65_ok
    jmp fin_menu

menu_verde_x65_ok:
    cmp mouse_x, 100
    jbe menu_verde_ok
    jmp fin_menu

menu_verde_ok:
    mov color_actual, 02h     ; Verde (Color 2)
    mov char_actual, '*'
    jmp fin_menu

comprobar_fila2:
    ; FILA 2: Y entre 60 y 85 (Azul / Amarillo)
    cmp mouse_y, 60
    jae menu_y60_ok
    jmp fin_menu

menu_y60_ok:
    cmp mouse_y, 85
    jbe menu_fila2_ok
    jmp comprobar_fila3

menu_fila2_ok:
    cmp mouse_x, 15
    jae menu_f2_x15_ok
    jmp fin_menu

menu_f2_x15_ok:
    cmp mouse_x, 50
    ja comprobar_amarillo
    mov color_actual, 01h     ; Azul (Color 1)
    mov char_actual, '*'
    jmp fin_menu

comprobar_amarillo:
    cmp mouse_x, 65
    jae menu_amarillo_x65_ok
    jmp fin_menu

menu_amarillo_x65_ok:
    cmp mouse_x, 100
    jbe menu_amarillo_ok
    jmp fin_menu

menu_amarillo_ok:
    mov color_actual, 0Eh     ; Amarillo (Color 14)
    mov char_actual, '*'
    jmp fin_menu

comprobar_fila3:
    ; FILA 3: Y entre 100 y 125 (Blanco / Cian)
    cmp mouse_y, 100
    jae menu_y100_ok
    jmp fin_menu

menu_y100_ok:
    cmp mouse_y, 125
    jbe menu_fila3_ok
    jmp comprobar_borrador

menu_fila3_ok:
    cmp mouse_x, 15
    jae menu_f3_x15_ok
    jmp fin_menu

menu_f3_x15_ok:
    cmp mouse_x, 50
    ja comprobar_cian
    mov color_actual, 0Fh     ; Blanco (Color 15)
    mov char_actual, '*'
    jmp fin_menu

comprobar_cian:
    cmp mouse_x, 65
    jae menu_cian_x65_ok
    jmp fin_menu

menu_cian_x65_ok:
    cmp mouse_x, 100
    jbe menu_cian_ok
    jmp fin_menu

menu_cian_ok:
    mov color_actual, 03h     ; Cian (Color 3)
    mov char_actual, '*'
    jmp fin_menu

comprobar_borrador:
    ; Botón Borrador (Y: 140 a 165)
    cmp mouse_y, 140
    jb comprobar_borrar_todo
    cmp mouse_y, 165
    jbe menu_borrador_ok
    jmp comprobar_borrar_todo

menu_borrador_ok:
    cmp mouse_x, 15
    jae menu_borrador_x15_ok
    jmp fin_menu

menu_borrador_x15_ok:
    cmp mouse_x, 100
    jbe menu_borrador_ok2
    jmp fin_menu

menu_borrador_ok2:
    mov char_actual, ' '      ; Cambiar carácter a Espacio para borrar
    jmp fin_menu

comprobar_borrar_todo:
    ; Botón Limpiar Todo (Y: 175 a 200) -> Invoca la INT 60h
    cmp mouse_y, 175
    jae menu_borrar_y175_ok
    jmp fin_menu

menu_borrar_y175_ok:
    cmp mouse_y, 200
    jbe menu_borrar_y200_ok
    jmp fin_menu

menu_borrar_y200_ok:
    cmp mouse_x, 15
    jae menu_borrar_x15_ok
    jmp fin_menu

menu_borrar_x15_ok:
    cmp mouse_x, 100
    jbe menu_borrar_x100_ok
    jmp fin_menu

menu_borrar_x100_ok:
    int 60h                   ; Disparar la interrupción propia de limpieza

fin_menu:
    ; Esperar a que el usuario suelte el botón del mouse para evitar repetidos
esperar_soltar:
    call leer_mouse
    cmp bx, 0
    jne esperar_soltar
    jmp salto_proceso


; =========================================================================
; SALIDA DEL PROGRAMA Y RESTAURACIÓN
; =========================================================================
salir_paint:
    ; Restaurar la dirección original de la INT 60h
    mov al, vector_num
    mov dx, vector_offset
    mov bx, vector_segment
    push ds
    mov ds, bx
    mov ah, 25h
    int 21h
    pop ds

    ; Restaurar el modo texto estándar (80x25) de DOSBox
    mov ax, 0003h
    int 10h

    ; Retornar a DOS limpiando la memoria
    mov ax, 4C00h
    int 21h
main endp

end main