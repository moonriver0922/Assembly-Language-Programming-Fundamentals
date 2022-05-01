data segment
s db 10 dup(0)
t db 10 dup(0)
crlf db 0Dh, 0Ah, '$'
data ends

code segment
assume cs:code, ds:data
input:
   push di; 保存寄存器di的值
input_next:
   mov ah, 1
   int 21h
   cmp al, 0Dh; 判断AL是否为回车键
   je input_done
   mov [di], al
   inc di; add di, 1
   jmp input_next
input_done:
   mov byte ptr [di], 0
   ;pop di; 恢复di的值
   mov ah, 9
   mov dx, offset crlf
   int 21h
   pop di; 恢复di的值
   ret

main:
   mov ax, data
   mov ds, ax
   mov di, offset s
   call input
   mov di, offset t
   call input
   mov ah, 4Ch
   int 21h
code ends
end main