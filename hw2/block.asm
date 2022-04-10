code segment
assume cs:code; cs不需要赋值会自动等于code
main:
   jmp begin
i  dw 0
begin:
   mov ax, 0013h
   int 10h
   mov ax, 0A000h
   mov es, ax
   ;(320/2, 200/2)
   mov di, (100-20)*320+(160-20); (160-20,100-20)
   ;mov cx, 41; rows=41
   mov i, 41
next_row:
   ;push cx
   push di
   mov al, 4; color=red
   mov cx, 41; dots=41
next_dot:
   mov es:[di], al
   add di, 1
   sub cx, 1
   jnz next_dot
   pop di; 左上角(x,y)对应的地址
   ;pop cx; cx=41
   add di, 320; 下一行的起点的地址
   ;sub cx, 1; 行数-1
   sub i, 1
   jnz next_row
   mov ah,0
   int 16h;bios键盘输入,类似int 21h的01h功能
   mov ax, 0003h
   int 10h; 切换到80*25文本模式
   mov ah, 4Ch
   int 21h
code ends
end main