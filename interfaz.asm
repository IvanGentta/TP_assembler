.8086
.model small

.data

.code

    PUBLIC dibujarInterfaz ; exportamos la interfaz


    dibujarInterfaz proc
        ; linea divisora
        mov cx, 120 ; x= 120
        mov dx, 0   ; y = 0
    
    linea_divisora:
        mov ah, 0Ch ; servicio de pintar pixel
        mov al, 0Fh ; color blanco
        mov bh, 0
        int 10h
        inc dx
        cmp dx, 480 ; fin ventana
        jne linea_divisora
    
        ; paleta de colores
        mov cx, 15  ; ubicacion x
        mov dx, 20  ; ubicacion y
        mov si, 35  ; ancho
        mov di, 25  ; alto
        mov al, 04h ; color rojo
        call dibujarRectanguloColor
    
        mov cx, 65  ; ubicacion x
        mov dx, 20  ; ubicacion y
        mov si, 35  ; Ancho
        mov di, 25  ; Alto
        mov al, 02h ; Color Verde
        call dibujarRectanguloColor
    
        mov cx, 15  ; ubicacion x
        mov dx, 60  ; ubicacion y
        mov si, 35  ; Ancho
        mov di, 25  ; alto
        mov al, 01h ; Color Azul
        call dibujarRectanguloColor
    
        mov cx, 65  ; ubicacion x
        mov dx, 60  ; ubicacion y
        mov si, 35  ; Ancho
        mov di, 25  ; alto
        mov al, 0eh ; Color Amarillo
        call dibujarRectanguloColor
    
        mov cx, 15  ; ubicacion x
        mov dx, 100 ; ubicacion y
        mov si, 35  ; Ancho
        mov di, 25  ; alto
        mov al, 0fh ; Color Blanco
        call dibujarRectanguloColor
    
        mov cx, 65  ; ubicacion x
        mov dx, 100 ; ubicacion y
        mov si, 35  ; Ancho
        mov di, 25  ; alto
        mov al, 03h ; Color Cian
        call dibujarRectanguloColor
    
        ret
    dibujarInterfaz endp
    
    dibujarRectanguloColor proc
        ; cx = inicio x - dx = inicio y - si = ancho - di = alto - al = color
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
        mov al, bl  ; se pasa el color
        mov bh, 0
        int 10h
        inc cx      ; siguiente x
        dec di      ; baja el seguimiento del ancho, al llegar 0 termina
        jnz columnas_loop
    
        pop di      ; restauramos contador de filas
        inc dx      ; siguiente y
        dec di      ; baja el seguimiento del alto, si llega a 0 termina
        jnz filas_loop
    
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    dibujarRectanguloColor endp
end