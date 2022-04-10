code segment
assume cs:code
main:
   mov ax, 0B800h
   mov es, ax
   mov di, 0
   mov al, 'A'; mov al, 65;或 mov al,41h
   mov ah, 0ch; 高八位背景，低八位前景
   mov cx, 2000
again:
   mov word ptr es:[di], ax; AX=1741h
   ;mov byte ptr es:[di], al
   ;mov byte ptr es:[di+1], ah
   add di, 2
   sub cx, 1
   jnz again
   mov ah, 1
   int 21h; 键盘输入，起到等待敲键的作用
   mov ah, 4Ch
   int 21h
code ends
end main