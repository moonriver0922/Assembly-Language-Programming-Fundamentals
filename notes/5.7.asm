4. 乘法指令: mul
8位乘法: 被乘数一定是 AL, 乘积一定是 AX
例如 mul bh 表示 AX=AL*BH

16位乘法: 被乘数一定是 AX, 乘积一定是 DX:AX
例如 mul bx 表示 DX:AX=AX*BX

32位乘法: 被乘数一定是 EAX, 乘积一定是 EDX:EAX
例如 mul ebx 表示 EDX:EAX=EAX*EBX

利用乘法指令把十进制字符串转化成32位整数的例子:
http://10.71.45.100/bhh/dec2v32.asm

comment #
    y          x
16位段地址:32位偏移地址
t是一张表
t+y->64位的值, 其中的32位表示y这个段的段首地址
这种寻址模式称为保护模式(protected mode)
    y          x
16位段地址:16位偏移地址
y*10h+x得到物理地址这种寻址模式称为实模式(real
mode)。dos启动后，它会把cpu切换到实模式，而非
保护模式; windows/linux启动后，它会把cpu切换到保护模式。
#
.386
data segment use16
s db "2147483647", 0; 7FFF FFFFh
abc dd 0
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
   ; 不能乘以或除以常数，因为常数在汇编中是没有宽度的
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
   mov abc, eax
   mov ah, 4Ch
   int 21h
code ends
end main


利用乘法指令把十进制字符串转化成16位整数的例子:
http://10.71.45.100/bhh/dec2v16.asm

imul 指令用来对符号数做乘法运算
386以上CPU对mul及imul的用法进行了扩充:
①mul eax,    ebx,     1234h
       寄存器  寄存器或  只能是常数
                变量
含义: eax = ebx * 1234h
②imul eax,     ebx; 含义: EAX=EAX*EBX
        寄存器    寄存器或变量
imul eax, dword ptr [esi]

imul eax, dword ptr [ebx+2], 1234h
含义: eax = dword ptr [ebx+2] * 1234h

--------------------------------------------------------------
5.地址传送指令: LEA, LDS, LES
(1) lea  dest, src  
load effective address=取变量的偏移地址
lea dx, ds:[1000h] ; DX=1000h
mov dx, 1000h; 上述lea指令的效果等同于mov指令

lea dx, abc ; 效果等价于以下指令
mov dx, offset abc
设abc的偏移地址=1000h
则lea dx, abc编译成:
lea dx, [1000h]
而mov dx, offset abc编译成:
mov dx, 1000h
          
mov dx, offset ds:[bx+si+3]; 语法错误 offset后面只能跟变量名、数组名，不能跟间接寻址方式表示的变量，因为offset运算是在编译时完成的
lea dx, ds:[bx+si+3]; dx=bx+si+3
mov dx, bx+si+3; 错误
mov dx, 1+2+3; 正确用法,因为右侧是常数表达式
mov dx, ((1*2+3) shl 2) xor 5; 正确

mov dx, bx; \
add dx, si;  | 效果等同于上述lea指令
add dx, 3 ; /

lea eax, [eax+eax*4]; EAX=EAX*5 用lea做乘法，运算速度比mul快很多
lea eax, [eax+eax*2]; EAX=EAX*3

(2) 远指针(far pointer) ; 近指针就是丢弃段地址，只有偏移地址的指针
16位汇编中，远指针是指16位段地址:16位偏移地址;
32位汇编中，远指针是指16位段地址:32位偏移地址。
                        16bits 32bits
                mov eax, ds:[ebx]
                在32位汇编中，段地址不再通过10h来得到段起始地址
                而是需要把段地址与gdt表的首地址相加指向一个8字节的元素
                再提取该元素中的4字节成为段起始地址
                gdt: global descriptor table全局描述符表
                gdt是一个数组，每个元素均为8字节
                gdt+00h
                gdt+08h ff ff 78 56 34 93 0f 12
                        -- --             *-
                        当第六字节的最高位=1时，limit表示最大页的编号不再是最大偏移地址，其中1页=1000h字节(4K)
                        当limit=fffff时。段内的最大偏移地址=ffffffff，因为该页的首地址=fffff000，末地址=ffffffff
                        第n页的偏移地址为:n000-nfff
                gdt+10h
                gdt+18h
                设 ds=8,则ds对应的段首地址=12345678h
                ds 总共的数量为 10000h/8=2000h个  
48位的远指针在汇编语言中有一个类型修饰词:
fword ptr; 用来修饰6字节的变量
近指针(near pointer)：偏移地址就是近指针
16位汇编中，近指针是指16位的偏移地址；
32位汇编中，近指针是指32位的偏移地址；

远指针(far pointer)包括段地址及偏移地址两个部分；
近指针(near pointer)只包括偏移地址，不包含段地址。
                 12345678h
假定把一个远指针1234h:5678h存放到地址1000:0000中，则内存布局如下:  &p=1000:0000
1000:0000 78h  
1000:0001 56h  
1000:0002 34h  
1000:0003 12h  
设ds=1000h, bx=0
mov di, ds:[bx]; di=5678h
mov es, ds:[bx+2]; es=1234h
les di, dword ptr ds:[bx]
mov al, es:[di]; AL=byte ptr 1234:[5678]

假定把一个48位的远指针001B:12345678存放到地址1000:0000中，则内存布局如下:
1000:0000 78h  
1000:0001 56h  
1000:0002 34h  
1000:0003 12h  
1000:0004 1Bh
1000:0005 00h
假定要把1000:0000中存放的48位远指针取出来，存放到es:edi中，则
mov ax, 1000h
mov ds, ax
mov edi, dword ptr ds:[0]
mov es, word ptr ds:[4]

les edi, fword ptr ds:[0000h]
; es=001Bh, edi=12345678h


远指针的汇编语言例子:
http://10.71.45.100/bhh/les.asm

data segment
video_addr dw 0000h, 0B800h, 160, 0B800h
;上述定义也可以写成:
;video_addr dd 0B8000000h, 0B80000A0h
data ends
code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov bx, 0
   mov cx, 2
next:
   les di, dword ptr video_addr[bx]
   mov word ptr es:[di], 1741h
   add bx, 4
   sub cx, 1
   jnz next
   mov ah, 1
   int 21h
   mov ah, 4Ch
   int 21h
code ends
end main



近指针的汇编语言例子:
http://10.71.45.100/bhh/nearptr.asm


data segment
video_addr dw 0000h, 160
data ends
code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov ax, 0B800h
   mov es, ax
   mov bx, 0
   mov cx, 2
next:
   mov di, video_addr[bx]
   mov word ptr es:[di], 1741h
   add bx, 2
   sub cx, 1
   jnz next
   mov ah, 1
   int 21h
   mov ah, 4Ch
   int 21h
code ends
end main



远指针的C语言例子:
http://10.71.45.100/bhh/farptr.c

#include <stdio.h>
main()
{
   char *q ; 16bits
   char far *p; 32bits
   p = (char far *)0xB8000000;
   *p = 'A';
   *(p+1) = 0x17;
   getchar();
}

----------------------------------------------
3.符号扩充指令: CBW, CWD, CDQ
cbw:convert byte to word
cwd:convert word to double word
cdq:convert double word to quadruple word
mov al, 0FEh
cbw; 把AL扩充成AX, AX=0FFFEh
mov ax, 8000h
cwd; 把AX扩充成DX:AX, DX=FFFFh, AX=8000h
mov eax, 0ABCD1234h
cdq; 把EAX扩充成EDX:EAX
    ; EDX=0FFFFFFFFh, EAX=0ABCD1234h

要计算-2/2
mov al, -2 或 mov al, 0feh
cbw; AH = 0ffh, AX = 0FFFEh
mov ax, -2 或 mov ax, 0fffeh
mov bl, 2
idiv bl; AL = FF, AH = 0

零扩充指令: movzx
movzx ax, al; zx:zero extension
movzx eax, al;
movzx ebx, cx;

新的符号扩充指令: movsx
movsx ax, al; sx:sign extension符号扩充
; 效果等同于cbw

--------------------------------
1.换码指令: XLAT  (translate) 也称查表指令
在 xlat 执行前必须让 ds:bx 指向表, al 必须赋值为
数组的下标; 执行xlat后, AL=ds:[bx+AL]
char t[]="0123456789ABCDEF";
char i;
i = 10;
i = t[i]; 最后i='A'

设ds=数组t的段地址
mov bx, offset t; BX=表的首地址
mov al, 10; AL为下标
xlat; 结果AL='A'
xlat指令要求DS:BX指向数组，AL=数组下标。
执行指令后, AL=数组元素
例子: http://10.71.45.100/bhh/xlat.asm

.386 ; 表示程序中会用32位的寄存器
data segment use16; use16表示偏移使用16位
t db "0123456789ABCDEF"
x dd 2147483647
data ends

code segment use16
assume cs:code, ds:data
main:
   mov ax, data    ;\
   mov ds, ax      ; / ds:bx->t[0]
   mov bx, offset t;/
   mov ecx, 8
   mov eax, x
next:
   rol eax, 4
   push eax
   and eax, 0Fh
   xlat
   mov ah, 2
   mov dl, al
   int 21h
   pop eax
   sub ecx, 1
   jnz next
   mov ah, 4Ch
   int 21h
code ends
end main

例子: http://10.71.45.100/bhh/xlat_sub.asm

-------------------------------
2. 算术指令
(1)加法指令: ADD，INC，ADC
inc: increment
mov ax, 3 
inc ax; AX=AX+1=4
inc指令不影响CF标志位

inc不影响CF位, add指令会影响CF:
again:           again:
add ax, cx        add ax, cx
jc done            inc cx
add cx,1           jnc again
jmp again        done:
done:

adc: add with carry 带进位加
计算 12345678h + 5678FFFFh
mov dx, 1234h
mov ax, 5678h
add ax, 0FFFFh; CF=1
adc dx, 5678h; DX=DX+5678h+CF

把x和y相加(x、y均为由100字节构成且用小端表示的大数)，结果保存到z中:
x db 100 dup(88h)
y db 100 dup(99h)
z db 101 dup(0)
设ds已经赋值为上述数组的段地址
mov cx, 100
mov si, offset x
mov di, offset y
mov bx, offset z
clc
next:
mov al, [si]
adc al, [di]
mov [bx], al
inc si
inc di
inc bx
dec cx
jnz next
adc z[100], 0; 或adc byte ptr [bx], 0
