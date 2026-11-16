.8086
.model small
.stack 100h

public init_mouse
public leer_mouse
public limpiar_pantalla
public pintar_trazo
public limpiarLienzoISR
public guardar_lienzo
public cargar_lienzo
extrn dibujar_rectangulo_color:PROC
extrn lienzo:byte ;importamos el lienzo del .data del main

.data
    ;data temporal para escritura y guardado matriz para archivo
    char_tmp            db 0
    color_tmp           db 0
    tamanio_tmp         db 0
    col_base            db 0
    fila_actual         db 0
    col_actual          db 0
    filas_restantes     db 0
    columnas_restantes  db 0

    ;guardado
    nombre_archivo db 'DIBUJO.DAT', 0 ;nombre del archivo a guardar
    handle_archivo dw 0 ;identificador para 

    ;carga
    fila_carga       db 0
    columna_carga    db 0

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

; Entradas:
; DL = Columna de pantalla DH = Fila de pantalla
; AL = Caracter ASCII BL = Color AH = Tamaño (1, 2 o 3)
pintar_trazo proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Guardamos los parametros recibidos
    mov char_tmp, al
    mov color_tmp, bl
    mov tamanio_tmp, ah

    ; Convertimos la columna de pantalla
    ; a columna relativa del lienzo (restamos 16)
    cmp dl, 16
    jb salto_fin_trazo

    cmp dl, 80
    jae salto_fin_trazo

    cmp dh, 30
    jae salto_fin_trazo

    jmp continuar

    salto_fin_trazo:
        jmp fin_trazo

    continuar:
    mov col_base, dl
    sub col_base, 16

    mov fila_actual, dh

    ; Inicializamos el contador de filas
    mov al, tamanio_tmp
    mov filas_restantes, al

bucle_filas_trazo:
    ; Verificar que no salgamos de las 30 filas
    cmp fila_actual, 30
    jb continuar_fila
    jmp fin_trazo

continuar_fila:
    mov al, tamanio_tmp
    mov columnas_restantes, al

    mov al, col_base
    mov col_actual, al

bucle_columnas_trazo:
    ; Verificamos que no salgamos de las 64 columnas
    cmp col_actual, 63
    jae saltar_casillero

    ; CALCULAR POSICION EN LA MATRIZ
    xor ax, ax
    mov al, fila_actual
    mov cl, 7
    shl ax, cl

    xor bx, bx
    mov bl, col_actual
    shl bx, 1

    add ax, bx
    mov si, ax

    ; GUARDAR EN LA MATRIZ
    mov al, char_tmp
    mov [lienzo+si], al

    mov al, color_tmp
    mov [lienzo+si+1], al

    ; DIBUJAR EN PANTALLA
    mov dl, col_actual
    add dl, 17

    mov dh, fila_actual

    mov ah, 02h
    mov bh, 00h
    int 10h

    mov al, char_tmp
    mov bl, color_tmp
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h

saltar_casillero:
    inc col_actual
    dec columnas_restantes
    jnz bucle_columnas_trazo

    ; Siguiente fila

    inc fila_actual
    dec filas_restantes
    jnz bucle_filas_trazo

    jmp fin_trazo

fin_trazo:
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

    ; LIMPIAR MATRIZ DEL LIENZO
    mov ax, ds
    mov es, ax          ; ES apunta al segmento de datos

    mov di, offset lienzo
    mov ax, 0020h       ; AL = espacio, AH = color negro
    mov cx, 1920        ; Cantidad de posiciones

    cld                 ; Avanzar en memoria
    rep stosw           ; Escribir 1920 palabras (3840 bytes)

    ; Ocultar el cursor del ratón temporalmente
    mov ax, 0002h
    int 33h

    ; Pinta de negro todo el lienzo (X: 131 a 639, Y: 0 a 479)
    mov cx, 131         ; X inicial (después de la línea divisora)
    mov dx, 0           ; Y inicial
    mov si, 510         ; Ancho del lienzo (639 - 131)
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

; Guarda el contenido del lienzo en DIBUJO.DAT se guarda en la carpeta tasm
; Retorno en AX:
; 0 = Exito 1 = Error al crear el archivo
; 2 = Error al escribir 3 = Error al cerrar
guardar_lienzo proc
    push bx
    push cx
    push dx
    push ds

    mov ax, @data
    mov ds, ax

    ; 1. CREAR ARCHIVO
    mov ah, 3Ch
    mov cx, 0
    mov dx, offset nombre_archivo
    int 21h

    jc error_crear

    ; Guardamos el identificador
    mov handle_archivo, ax

    ; 2. ESCRIBIR EN EL ARCHIVO
    mov bx, handle_archivo ; identificador del archjivo
    mov ah, 40h            ; funcion 40 escribir
    mov cx, 3840           ; cant bytes
    mov dx, offset lienzo
    int 21h

    jc error_escritura

    ; Comprobar que se escribieron todos los bytes
    cmp ax, 3840
    jne error_escritura

    ; 3. CERRAR ARCHIVO
    mov bx, handle_archivo
    mov ah, 3Eh
    int 21h

    jc error_cierre

    mov ax, 0
    jmp fin_guardar

error_escritura:
    ; Intentar cerrar el archivo aunque falle la escritura
    mov bx, handle_archivo
    mov ah, 3Eh
    int 21h

    mov ax, 2
    jmp fin_guardar

error_crear:
    mov ax, 1
    jmp fin_guardar

error_cierre:
    mov ax, 3

fin_guardar:
    pop ds
    pop dx
    pop cx
    pop bx
    ret
guardar_lienzo endp


; Carga DIBUJO.DAT en la matriz y lo dibuja en pantalla.
; Retorno en AX:
; 0 = Exito 1 = Error al abrir
; 2 = Error al leer 3 = Error al cerrar
cargar_lienzo proc
    push bx
    push cx
    push dx
    push si
    push di
    push ds

    mov ax, @data
    mov ds, ax

    ; 1. ABRIR ARCHIVO
    mov ah, 3Dh
    mov al, 00h             ; Solo lectura
    mov dx, offset nombre_archivo
    int 21h

    jnc archivo_abierto
    jmp error_abrir

archivo_abierto:
    mov handle_archivo, ax

    ; 2. LEER ARCHIVO
    mov bx, handle_archivo
    mov ah, 3Fh
    mov cx, 3840
    mov dx, offset lienzo
    int 21h

    jnc lectura_ok
    jmp error_lectura

lectura_ok:
    ; Comprobar que se leyeron todos los bytes
    cmp ax, 3840
    je lectura_completa
    jmp error_lectura

lectura_completa:

    ; 3. CERRAR ARCHIVO
    mov bx, handle_archivo
    mov ah, 3Eh
    int 21h

    jnc archivo_cerrado
    jmp error_cerrar

archivo_cerrado:
; 4. DIBUJAR MATRIZ EN PANTALLA
    ; Ocultar cursor del mouse
    mov ax, 0002h
    int 33h

    mov fila_carga, 0

bucle_filas_carga:
    mov columna_carga, 0

bucle_columnas_carga:
    ; Calcular offset:
    ; (fila * 128) + (columna * 2)
    xor ax, ax
    mov al, fila_carga
    mov cl, 7
    shl ax, cl

    xor bx, bx
    mov bl, columna_carga
    shl bx, 1

    add ax, bx
    mov si, ax

    ; Recuperar caracter y color
    mov al, [lienzo+si]     ;char
    mov bl, [lienzo+si+1]   ;color

    ; Posicionar cursor en pantalla
    mov dl, columna_carga
    add dl, 17

    mov dh, fila_carga
    mov ah, 02h
    mov bh, 00h
    int 10h

    ; Imprimir caracter recuperado
    mov al, [lienzo+si]
    mov bl, [lienzo+si+1]
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h

    ; Siguiente columna
    inc columna_carga
    cmp columna_carga, 64
    jb bucle_columnas_carga

    ; Siguiente fila
    inc fila_carga
    cmp fila_carga, 30
    jb bucle_filas_carga

    ; Mostrar nuevamente el mouse
    mov ax, 0001h
    int 33h
    mov ax, 0
    jmp fin_cargar

error_lectura:
    ; Cerrar archivo aunque haya fallado la lectura
    mov bx, handle_archivo
    mov ah, 3Eh
    int 21h
    mov ax, 2
    jmp fin_cargar

error_abrir:
    mov ax, 1
    jmp fin_cargar

error_cerrar:
    mov ax, 3

fin_cargar:
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
cargar_lienzo endp

end
