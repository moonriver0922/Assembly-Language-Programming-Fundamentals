.386
data segment use16
s db "2147483647", 0; 7FFF FFFFh
abc dd 0
crlf db 0dh, 0ah, '$'
data ends
code segment use16
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov eax, 0; 被乘数
   mov si, 0; 数组s的下标
again:
   cmp s[si], 0; 判断是否到达数组的结束标志
   je done
   mov ebx, 10
   mul ebx; EDX:EAX=乘积, 其中EDX=0
          ; 或写成imul eax, ebx
   mov edx, 0
   mov dl, s[si]; DL='1'
   sub dl, '0'
   add eax, edx
   ;mov dl, s[si]
   ;sub dl, '0'
   ;movzx edx, dl
   ;add eax, edx
   inc si
   jmp again
done:
   mov di, offset abc
   mov dword ptr [di], eax
   mov ah, 9
   mov dx, offset abc
   int 21h
   mov ah, 4Ch
   int 21h
code ends
end main

