data segment
	s db 100 dup(0)
	t db 100 dup(0)
data ends
code segment
	assume cs:code, ds:data
main:
	mov ax, data
	mov ds, ax
	mov bx, 0
	mov bp, 0
input_next:
	mov ah, 01h
	int 21h; 键盘输入
	cmp al, 0dh; 判断是否为回车符
	je input_done
	mov s[bx], al
	add bx, 1
	jmp input_next
input_done:
	mov s[bx], 00h; 将回车转化为null
	mov ah, 2
	mov dl, 0dh
	int 21h; 输出回车
	mov ah, 2
	mov dl, 0ah
	int 21h; 输出换行
	mov bx, offset s
	mov si, 0
	mov di, 0
transfer:
	mov dl, [bx+si]
	cmp dl, 0; 遍历s数组结束
	je output_next
	cmp dl, 20h
	je discard
	cmp dl, 61h
	jnb jump; ASCII码值不小于'a'
	jmp transferhelper
transferhelper:
	mov al, [bx+si]
	mov t[bp], al; 原样保存
	add bp, 1
	add si, 1
	jmp transfer
jump:
	cmp dl, 7ah; ASCII码值不大于'z'
	jna touppercase
	jmp transferhelper
touppercase:
	mov al, [bx+si]
	sub al, 32; 将小写字母转化成大写字母
	mov t[bp], al
	add bp, 1
	add si, 1
	jmp transfer
discard:
	add si, 1; 舍弃空格
	jmp transfer
output_next:
	mov bx, offset t
	mov dl, [bx+di]
	cmp dl, 0; 遍历t数组结束
	je output_done
	mov ah, 2
	int 21h
	add di, 1
	jmp output_next
output_done:
	mov ah, 2
	mov dl, 0dh
	int 21h; 输出回车
	mov ah, 2
	mov dl, 0ah
	int 21h; 输出换行
	mov ah, 4ch
	int 21h
code ends
end main

