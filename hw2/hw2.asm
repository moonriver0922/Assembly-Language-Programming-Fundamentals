data segment
    hex db 2
data ends
code segment
    assume cs:code, ds:data
    a db 0 ;记录字符数
    j db 0 ;记录列数
    i db 0 ;记录行数
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
;打印11列
column:
    mov di, 0
    mov al, j
    mov bl, 14
    mul bl ;每列间隔7个字符
    mov bl, 0
    add di, ax
    mov i, 0
;打印25行
row:
    mov ah, 0
    mov al, a
    mov es:[di], al
    mov byte ptr es:[di+1], 0ch ;打印字符
    rol ax, 4
    rol al, 4
    cmp al, 9 ;比较16进制的第0位是否小于10
    ja letter_al ;不是，则按照字母计算
    jbe num_al ;是，则按照数字计算
letter_al:
    add al, 7
num_al:
    add al, 48
cmp ah, 9 ;比较16进制的第1位是否小于10
    ja letter_ah ;不是，则按照字母计算
    jbe num_ah ;是，则按照数字计算
letter_ah:
    add ah, 7
num_ah:
    add ah, 48
    mov bx, 0
    mov hex[bx], ah 
    mov hex[bx+1], al ;将计算结果存入hex数组

    ;输出hex数组中的16进制数
    mov bx, offset hex
    mov al, [bx]
    mov es:[di+2], al
    mov byte ptr es:[di+3], 0Ah 
    mov al, [bx+1]
    mov es:[di+4], al
    mov byte ptr es:[di+5], 0Ah ;打印对应字符的16进制ASCII码值
    ;换至下一行
    add di, 160
    add a, 1 ;字符数加1
    cmp a, 0 ;判断是否为0，即FF之后加1溢出，程序结束
    jz done ;若是则跳转结束，若不是继续执行
    add i, 1 ;行数加1
    mov al, 25
    sub al, i
    jnz row ;若行数到25，则继续下一列，否则继续下一行
    add j, 1
    mov al, 11
    sub al, j ;若列数到11，则跳转结束，否则继续下一列
    jz done
    jmp column
 done:
    mov ah,0
    int 16h;bios键盘输入,类似int 21h的01h功能
    mov ax, 0003h
    int 10h; 切换到80*25文本模式
    mov ah, 4Ch
    int 21h
code ends
end main
    