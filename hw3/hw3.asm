; 主要思路：
;将输入的各项数根据识别到运算符来区分
;并且转换成键入的字符对应的数字存储，运算
;完成最终的运算后，再分别进行16进制和10进制的转换即可
.386
data segment use16
hex db 1
decimal dd 00000000h
load_hex db 8 dup(' '), 'h', 0dh, 0ah, '$'
load_deciaml db 10 dup(' '), 0dh, 0ah, '$'
s db 100 dup(0) 
data ends
code segment use16
    assume cs:code, ds:data
input:
    push di; 保存寄存器di的值
    push di
    mov eax, 0
    mov ebx, 0
    mov ecx, 0
    mov edx, 0
input_next:
    mov ah, 1
    int 21h
    cmp al, 0Dh; 判断AL是否为回车键
    je input_done
    cmp al, 2Bh; 判断AL是否为+键
    je do
    cmp al, 2Dh; 判断AL是否为-键
    je do
    cmp al, 2Ah; 判断AL是否为*键
    je do
    cmp al, 2Fh; 判断AL是否为/键
    je do
    mov [di], al
    inc di
    jmp input_next
input_done:; 按下回车后进行最后一次运算
    cmp cx, 1; 如果没有运算符，则结束程序
    jne ending
    mov byte ptr [di], 00h; terminate flag
    pop di; load previous address
    mov bl, [di]; 寻找运算符匹配
    cmp bl, 2Bh
    je do_add
    cmp bl, 2Dh
    je do_sub
    cmp bl, 2Ah
    je do_mul
    cmp bl, 2Fh
    je do_div
do:
    cmp cx, 1; 是否是首次遇到运算符
    je do_next
    mov si, di; store current address
    mov byte ptr [di], 00h; terminate flag
    pop di; load previous address
    call convert
    inc cx; counts
    mov di, si; load current address
    push di; store current address
    mov [di], al
    inc di
    jmp input_next
convert:; 将键入的字符转换成对应的字符值
    push eax
    push ebx
    push edx
    mov eax, 0
    mov edx, 0
    cmp cx, 1
    je convert_ebx
convert_edx:; 用edx存储算式最后的值
    cmp byte ptr [di], 00h
    je convert_done
    mov ebx, 10
    mul ebx
    mov edx, 0
    mov dl, [di]
    sub dl, '0'
    add eax, edx
    inc di
    jmp convert_edx
convert_ebx:; 用ebx存储后续参与运算的数
    inc di
    jmp convert_edx
convert_done:
    cmp cx, 1
    je convert_done_after
    pop edx
    mov edx, eax
    pop ebx
    pop eax
    ret
convert_done_after:
    pop edx
    pop ebx
    mov ebx, eax
    pop eax
    ret
do_next:; 取出运算符进行运算
    mov si, di; store current address
    mov byte ptr [di], 00h; terminate flag
    pop di; load previous address
    mov bl, [di]
    cmp bl, 2Bh
    je do_add
    cmp bl, 2Dh
    je do_sub
    cmp bl, 2Ah
    je do_mul
    cmp bl, 2Fh
    je do_div
do_add:
    call convert
    add edx, ebx
    cmp al, 0Dh
    je output_done
    mov di, si; load current address
    push di; store current address
    mov [di], al
    inc di
    jmp input_next
do_sub:
    call convert
    sub edx, ebx
    cmp al, 0Dh
    je output_done
    mov di, si; load current address
    push di; store current address
    mov [di], al
    inc di
    jmp input_next
do_mul:
    call convert
    push eax
    mov eax, edx
    mul ebx
    mov edx, eax
    pop eax
    cmp al, 0Dh
    je output_done
    mov di, si; load current address
    push di; store current address
    mov [di], al
    inc di
    jmp input_next
do_div:
    call convert
    push eax
    mov eax, edx
    mov edx, 0
    div ebx
    mov edx, eax
    pop eax
    cmp al, 0Dh
    je output_done
    mov di, si; load current address
    push di; store current address
    mov [di], al
    inc di
    jmp input_next

output_done:; 算式运算完成，开始转换
    pop di
    mov dword ptr [di], edx
    add decimal, edx; 存储需要转换成十进制的值
    mov bp, di
    mov bx, offset load_hex
    push bx
    mov si, offset hex; 进行十六进制的显示转换
    mov cx, 3; 进行4次，每次取出一个字节
    jmp convert_hex
over:; 转换结束，输出16进制的结果
    mov ah, 9
    pop bx
    mov dx, bx
    int 21h
    ret

;以下是运算结果向十进制和十六进制的转换过程
convert_hex:
    mov eax, 0
    mov di, cx
    mov ah, 0
    mov al, [bp+di]
    rol ax, 4
    rol al, 4
    cmp al, 9; compare to 9
    ja letter_al; greater than or equals
    jbe num_al; less than
letter_al:
    add al, 7
num_al:
    add al, 48
    cmp ah, 9
    ja letter_ah
    jbe num_ah
letter_ah:
    add ah, 7
num_ah:
    add ah, 48
    mov byte ptr [bx], ah; 将转换后的值存储到load_hex中
    mov byte ptr [bx+1], al
    cmp cx, 0; 十六进制转换结束，进行十进制的转换
    je convert_decimal
    add bx, 2
    dec cx
    jmp convert_hex
convert_decimal:
    push eax
    push ecx
    push edx
    mov eax, decimal
    mov cx, 0
    mov di, 0
again:
    mov edx, 0
    mov ebx, 10
    div ebx
    add dl, '0'
    push dx
    inc cx
    cmp eax, 0
    jne again
pop_again:
    pop dx
    mov load_deciaml[di], dl
    inc di
    dec cx
    jnz pop_again
    ;转换结束，输出十进制的结果
    mov ah, 9
    mov dx, offset load_deciaml
    int 21h
    pop edx
    pop ecx
    pop eax
    jmp over
main:
    mov ax, data
    mov ds, ax
    mov di, offset s
    call input
ending:
    mov ah, 4ch
    int 21h
code ends
end main
