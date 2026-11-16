.8086
.model small
.stack 100h

extrn init_mouse:proc
extrn leer_mouse:proc
extrn limpiar_pantalla:proc
extrn dibujar_intro:proc
extrn dibujar_interfaz:proc
extrn pintar_trazo:proc
extrn limpiarLienzoISR:proc
extrn guardar_lienzo:proc
extrn cargar_lienzo:proc

.data
    ; Coordenadas y estado del mouse
    mouse_x         dw 0
    mouse_y         dw 0
    mouse_status    dw 0

    ; Estado del pincel
    color_actual    db 0Fh     ; Blanco por defecto (Color 15)
    char_actual     db '*'     ; Carácter '*' por defecto
    public tamanio_pincel
    tamanio_pincel  db 1       ; Tamaño 1x1 por defecto

    ; Resguardo del vector de la interrupción propia INT 60h
    vector_num      db 60h
    vector_offset   dw 0
    vector_segment  dw 0

    ; Matriz del lienzo: 30 filas x 64 columnas
    ; Cada posición tiene 2 bytes: char + color
    ; 1920 repeticiones de 2 bytes = 3480 bytes: caracter vacio + color negro por defecto
    public lienzo
    lienzo          db 1920 dup(' ', 00h) 

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Configuracion interrupción propia (INT 60h)
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

    ; Activar Modo Gráfico VGA (640x480, 16 colores)
    call limpiar_pantalla

    ; Pantalla de Intro
    call dibujar_intro

    esperar_enter:
    mov ah, 00h
    int 16h
    cmp al, 0Dh         ; ENTER
    jne esperar_enter   ; Si no toca enter, espera

    call limpiar_pantalla

    ; Dibujar la interfaz
    call dibujar_interfaz

    call actualizar_tamanio

    ; Inicializar y mostrar el cursor del ratón
    call init_mouse

; BUCLE PRINCIPAL 
proceso:
    ; Leer estado del mouse
    call leer_mouse     ; Retorna: BX = Botones, CX = X, DX = Y
    mov mouse_x, cx
    mov mouse_y, dx
    mov mouse_status, bx

    ; Verificar si se hizo clic izquierdo (BX = 1)
    cmp bx, 1
    jne seguir_proceso
    jmp procesar_click

    seguir_proceso:
    ; Verificar lectura de teclado 
    mov ah, 01h
    int 16h
    jz no_hay_tecla

    ; Consumir la tecla presionada (INT 16h / AH=00h)
    mov ah, 00h
    int 16h
    jmp procesar_tecla

no_hay_tecla:
    jmp continuar_loop

procesar_tecla:
    cmp al, '1'
    jne check_2

    ; --- SELECCIÓN DE CARÁCTER ASCII (Teclas 1 a 6) ---

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
    mov char_actual, 219d
    jmp continuar_loop

check_4:
    cmp al, '4'
    jne check_5
    mov char_actual, '.'
    jmp continuar_loop

check_5:
    cmp al, '5'
    jne check_6
    mov char_actual, 196d
    jmp continuar_loop

check_6:
    cmp al, '6'
    jne check_guardar
    mov char_actual, '~'
    jmp continuar_loop

check_guardar:
    cmp al, 'g'
    jne check_cargar
    call guardar_lienzo
    jmp continuar_loop

check_cargar:
    cmp al, 'l'
    jne check_mas
    call cargar_lienzo
    jmp continuar_loop

    ; --- TAMAÑO DE PINCEL (Teclas + y -) ---
check_mas:
    cmp al, '+'
    jne check_menos
    cmp tamanio_pincel, 3     ; Límite máximo: 3x3
    jae continuar_loop
    inc tamanio_pincel
    call actualizar_tamanio
    jmp continuar_loop


check_menos:
    cmp al, '-'
    jne check_esc
    cmp tamanio_pincel, 1     ; Límite mínimo: 1x1
    jbe continuar_loop
    dec tamanio_pincel
    call actualizar_tamanio
    jmp continuar_loop

    ; --- SALIR CON LA TECLA ESC (ASCII 1Bh / 27) ---
check_esc:
    cmp al, 1Bh
    je salto_salir_paint

continuar_loop:
    jmp proceso

; Saltos intermedios
salto_procesar_click:
    jmp procesar_click

salto_salir_paint:
    jmp salir_paint

salto_fin_menu:
    jmp fin_menu

salto_proceso:
    jmp proceso

; MANEJO DE CLIC DEL MOUSE (Lienzo | Menú Lateral)
procesar_click:
    cmp mouse_x, 130
    ja dibujar_lienzo         ; Si X > 130, pintar en la zona de lienzo
    jmp verificar_menu        ; Si X <= 130, procesar botón de la interfaz

dibujar_lienzo:
    ; Ocultar cursor temporalmente para no corromper la pantalla
    mov ax, 0002h
    int 33h

    ; Convertir píxeles a grilla de texto 80x25 (X / 8, Y / 16)
    mov ax, mouse_x
    mov cl, 3
    shr ax, cl                ; DL = Columna (X / 8)
    mov dl, al

    mov ax, mouse_y
    mov cl, 4
    shr ax, cl                ; DH = Fila (Y / 16)
    mov dh, al

    ; Cargar parámetros y llamar a la rutina de dibujo de trazo
    mov al, char_actual
    mov bl, color_actual
    mov ah, tamanio_pincel
    call pintar_trazo

    ; Mostrar nuevamente el cursor del mouse
    mov ax, 0001h
    int 33h
    jmp salto_proceso

; VERIFICACIÓN DE CLIC EN LA PALETA DE COLORES (X: 0 a 120)

verificar_menu:
; FILA 1: ROJO / VERDE
    cmp mouse_y, 40
    jae menu_y40_ok
    jmp fin_menu

menu_y40_ok:
    cmp mouse_y, 65
    jbe menu_fila1
    jmp comprobar_fila2

menu_fila1:
    cmp mouse_x, 15
    jb fila1_fin
    cmp mouse_x, 50
    jbe fila1_rojo
    cmp mouse_x, 65
    jb fila1_fin
    cmp mouse_x, 100
    jbe fila1_verde
    jmp fin_menu

fila1_fin:
    jmp fin_menu

fila1_rojo:
    jmp seleccionar_rojo

fila1_verde:
    jmp seleccionar_verde

seleccionar_rojo:
    mov color_actual, 04h
    jmp fin_menu

seleccionar_verde:
    mov color_actual, 02h
    jmp fin_menu

; FILA 2: AZUL / AMARILLO
comprobar_fila2:
    cmp mouse_y, 80
    jae menu_y80_ok
    jmp fin_menu

menu_y80_ok:
    cmp mouse_y, 105
    jbe menu_fila2
    jmp comprobar_fila3

menu_fila2:
    cmp mouse_x, 15
    jb fila2_fin
    cmp mouse_x, 50
    jbe fila2_azul
    cmp mouse_x, 65
    jb fila2_fin
    cmp mouse_x, 100
    jbe fila2_amarillo
    jmp fin_menu

fila2_fin:
    jmp fin_menu

fila2_azul:
    jmp seleccionar_azul

fila2_amarillo:
    jmp seleccionar_amarillo

seleccionar_azul:
    mov color_actual, 01h
    jmp fin_menu

seleccionar_amarillo:
    mov color_actual, 0Eh
    jmp fin_menu

; FILA 3: BLANCO / CIAN
comprobar_fila3:
    cmp mouse_y, 120
    jae menu_y120_ok
    jmp fin_menu

menu_y120_ok:
    cmp mouse_y, 145
    jbe menu_fila3
    jmp comprobar_pinceles

menu_fila3:
    cmp mouse_x, 15
    jb fila3_fin
    cmp mouse_x, 50
    jbe fila3_blanco
    cmp mouse_x, 65
    jb fila3_fin
    cmp mouse_x, 100
    jbe fila3_cian
    jmp fin_menu

fila3_fin:
    jmp fin_menu

fila3_blanco:
    jmp seleccionar_blanco

fila3_cian:
    jmp seleccionar_cian

seleccionar_blanco:
    mov color_actual, 0Fh
    jmp fin_menu

seleccionar_cian:
    mov color_actual, 03h
    jmp fin_menu

comprobar_pinceles:
    ; CONTROLES DE TAMANO Y = 272 a 287
    cmp mouse_y, 272
    jb no_es_fila_tamanio

    cmp mouse_y, 287
    ja no_es_fila_tamanio

    ; Boton +
    cmp mouse_x, 80
    jb salir_control_tamanio

    cmp mouse_x, 87
    jbe aumentar_tamanio_mouse

    ; Boton -
    cmp mouse_x, 112
    jb salir_control_tamanio

    cmp mouse_x, 119
    jbe reducir_tamanio_mouse

salir_control_tamanio:
    jmp fin_menu

reducir_tamanio_mouse:
    cmp tamanio_pincel, 1
    jbe tamanio_minimo

    dec tamanio_pincel
    call actualizar_tamanio
    jmp fin_menu

tamanio_minimo:
    jmp fin_menu

aumentar_tamanio_mouse:
    cmp tamanio_pincel, 3
    jae tamanio_maximo

    inc tamanio_pincel
    call actualizar_tamanio
    jmp fin_menu

tamanio_maximo:
    jmp fin_menu

no_es_fila_tamanio:
    jmp revisar_pinceles_fila1

; PINCELES
revisar_pinceles_fila1:
    cmp mouse_y, 304
    jb segunda_fila_pinceles
    cmp mouse_y, 319
    ja segunda_fila_pinceles

    cmp mouse_x, 16
    jb pincel_fin
    cmp mouse_x, 40
    jbe seleccionar_asterisco

    cmp mouse_x, 56
    jb pincel_fin
    cmp mouse_x, 80
    jbe seleccionar_numeral

    cmp mouse_x, 96
    jb pincel_fin
    cmp mouse_x, 120
    jbe seleccionar_bloque

    jmp fin_menu

segunda_fila_pinceles:
    ; Segunda fila: Y = 336 a 351
    cmp mouse_y, 336
    jb comprobar_borrador
    cmp mouse_y, 351
    ja comprobar_borrador

    cmp mouse_x, 16
    jb pincel_fin
    cmp mouse_x, 40
    jbe seleccionar_punto

    cmp mouse_x, 56
    jb pincel_fin
    cmp mouse_x, 80
    jbe seleccionar_guion

    cmp mouse_x, 96
    jb pincel_fin
    cmp mouse_x, 120
    jbe seleccionar_onda

    jmp fin_menu

pincel_fin:
    jmp fin_menu

seleccionar_asterisco:
    mov char_actual, '*'
    jmp fin_menu

seleccionar_numeral:
    mov char_actual, '#'
    jmp fin_menu

seleccionar_bloque:
    mov char_actual, 219
    jmp fin_menu

seleccionar_punto:
    mov char_actual, '.'
    jmp fin_menu

seleccionar_guion:
    mov char_actual, 196
    jmp fin_menu

seleccionar_onda:
    mov char_actual, '~'
    jmp fin_menu

; BORRADOR
comprobar_borrador:
    cmp mouse_y, 192
    jae borrador_y_ok
    jmp comprobar_borrar_todo

borrador_y_ok:
    cmp mouse_y, 207
    jbe borrador_y_dentro
    jmp comprobar_borrar_todo

borrador_y_dentro:
    cmp mouse_x, 8
    jae borrador_x_ok
    jmp fin_menu

borrador_x_ok:
    cmp mouse_x, 100
    jbe ejecutar_borrador
    jmp fin_menu

ejecutar_borrador:
    mov char_actual, ' '
    jmp fin_menu

; BORRAR TODO
comprobar_borrar_todo:
    cmp mouse_y, 224
    jae borrar_y_ok
    jmp comprobar_guardar

borrar_y_ok:
    cmp mouse_y, 239
    jbe borrar_y_dentro
    jmp comprobar_guardar

borrar_y_dentro:
    cmp mouse_x, 8
    jae borrar_x_ok
    jmp fin_menu

borrar_x_ok:
    cmp mouse_x, 100
    jbe ejecutar_borrar_todo
    jmp fin_menu

ejecutar_borrar_todo:
    int 60h
    jmp fin_menu

; BOTÓN GUARDAR
comprobar_guardar:
    cmp mouse_y, 384
    jb saltar_fin_guardar
    cmp mouse_y, 399
    jbe guardar_y_dentro
    jmp comprobar_cargar

saltar_fin_guardar:
    jmp fin_menu

guardar_y_dentro:
    cmp mouse_x, 8
    jb saltar_fin_guardar_x
    cmp mouse_x, 100
    jbe ejecutar_guardado

saltar_fin_guardar_x:
    jmp fin_menu

ejecutar_guardado:
    call guardar_lienzo
    jmp fin_menu

; BOTÓN CARGAR
comprobar_cargar:
    cmp mouse_y, 416
    jae cargar_y_ok
    jmp fin_menu

cargar_y_ok:
    cmp mouse_y, 431
    jbe cargar_y_dentro
    jmp fin_menu

cargar_y_dentro:
    cmp mouse_x, 8
    jae cargar_x_ok
    jmp fin_menu

cargar_x_ok:
    cmp mouse_x, 100
    jbe ejecutar_carga
    jmp fin_menu

ejecutar_carga:
    call cargar_lienzo
    jmp fin_menu

fin_menu:
    ; Esperar a que el usuario suelte el botón del mouse para evitar repetidos
esperar_soltar:
    call leer_mouse
    cmp bx, 0
    jne esperar_soltar
    jmp salto_proceso

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

    mov ax, 4C00h
    int 21h
main endp

actualizar_tamanio proc
    push ax
    push dx

    ; Ocultar cursor del mouse para evitar bug visual
    mov ax, 0002h
    int 33h

    ; Posicionar cursor en fila 17, columna 13
    mov ah, 02h
    mov bh, 0
    mov dh, 17
    mov dl, 12
    int 10h

    ; Convertir el tamaño a ASCII
    mov dl, tamanio_pincel
    add dl, '0'

    ; Mostrar el número
    mov ah, 02h
    int 21h

    ; Mostrar nuevamente el cursor del mouse
    mov ax, 0001h
    int 33h

    pop dx
    pop ax
    ret
actualizar_tamanio endp

end main
