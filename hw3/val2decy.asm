
.386
data segment use16
abc dd 00000002h
s db 10 dup(' '), 0Dh, 0Ah, '$'
data ends
code segment use16
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov di, 0; 数组s的下标
   mov eax, abc
   mov cx, 0; 统计push的次数
again:
   mov edx, 0; 被除数为EDX:EAX
   mov ebx, 10
   div ebx; EAX=商, EDX=余数
   add dl, '0'
   push dx
   inc cx; 相当于add cx, 1
   cmp eax, 0
   jne again
pop_again:
   pop dx
   mov s[di], dl
   inc di
   dec cx; 相当于sub cx, 1
   jnz pop_again

   mov ah, 9
   mov dx, offset s
   int 21h
   mov ah, 4Ch
   int 21h
code ends
end main



