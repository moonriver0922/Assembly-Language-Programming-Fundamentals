data segment
    hex db 3
data ends
code segment
    assume cs:code, ds:data
    a db 0
    j dw 0
    i dw 0
main:
    mov ax, data
    mov ds, ax
    mov ax, 0003h
    int 10h
    mov ax, 0B800h
    mov es, ax
    mov bx, 0
    mov a, 0
    mov j, 0
    mov di, 0
    mov ax, j
    mov cx, 14
    mul cx
    add di, ax
    mov i, 0
    mov al, a
    mov es:[di], al
    mov byte ptr es:[di+1], 0ch
    mov ah, 1
    int 21h; 键盘输入，起到等待敲键的作用
    mov ah, 4Ch
    int 21h
code ends
end main  