data segment
hz db 04h,80h,0Eh,0A0h,78h,90h,08h,90h
   db 08h,84h,0FFh,0FEh,08h,80h,08h,90h
   db 0Ah,90h,0Ch,60h,18h,40h,68h,0A0h
   db 09h,20h,0Ah,14h,28h,14h,10h,0Ch
data ends
code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov ax, 0A000h
   mov es, ax
   mov di, 0
   mov ax, 0013h
   int 10h
   mov dx, 16
   mov si, 0
next_row:
   mov ah, hz[si]
   mov al, hz[si+1]
   add si, 2
   mov cx, 16
check_next_dot:
   shl ax, 1; 刚移出的位会自动进入CF(进位标志)
   jnc no_dot; 若没有进位即CF=0则跳到no_dot
is_dot:
   mov byte ptr es:[di], 0Ch
no_dot:
   add di, 1
   sub cx, 1
   jnz check_next_dot
   sub di, 16
   add di, 320
   sub dx, 1
   jnz next_row
   mov ah, 1
   int 21h
   mov ax, 0003h
   int 10h
   mov ah, 4Ch
   int 21h
code ends
end main