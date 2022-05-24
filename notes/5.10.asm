(2) 减法指令: SUB，SBB，DEC，NEG，CMP
dec: decrement自减, dec指令不影响CF
  mov ax, 3
dec ax; AX=AX-1=2

neg:negate 求相反数, 会影响CF,ZF,SF等标志位。
mov ax, 1
neg ax; AX=-1=0FFFFh，相当于做减法0-ax

mov ax, 0FFFEh
neg ax; AX=2, CF=1, SF=0, ZF=0

neg ax ≡ (not ax) + 1
-x ≡ ~x + 1

sbb: subtract with borrow 带借位减
例如求56781234h-1111FFFFh的差
mov ax, 1234h
sub ax, 0FFFFh; CF=1
mov dx, 5678h
sbb dx, 1111h; DX=5678h-1111h-CF

cmp: cmp 与 sub 的区别是抛弃两数之差, 仅保留标志位状态
mov ax, 3
mov bx, 3
cmp ax, bx; 内部是做了减法ax-bx，但
; 是抛弃两数之差，只影响标志位。
  je they_are_equal; 当ZF=1时则跳
  jz they_are_equal; 当ZF=1时则跳
  因此je≡jz

① ja, jb, jae, jbe 都是非符号数比较相关的跳转指令
jb: CF=1, 故jb≡jc
ja: CF=0 且 ZF=0
② jg, jl, jge, jle 是符号数比较相关的跳转指令
jg: SF(相减后的符号)==OF(overflow flag) 且 ZF(是否相等)==0
jge: SF==OF
jl: SF!=OF 不需要考虑ZF的状态
mov ax, 3
mov bx, 2
cmp ax, bx; AX-BX=1, SF=0, OF=0  AX > BX
mov ah, 7Fh
mov bh, 80h
cmp ah, bh; AH-BH=0FFh, SF=1, OF=1  AX>BX
mov ax, 2
mov bx, 3
cmp ax, bx; AX-BX=FFFFh, SF=1, OF=0AX<BX
mov ah, 80h
mov bh, 7Fh
cmp ah, bh; AH-BH=1, SF=0, OF=1AX<BX
----------------------------------------------------------------
(5) 小数运算
fadd  fsub  fmul fdiv 小数的+-*/运算指令
由浮点处理器负责执行, 用法请参考主页intel指令集

小数变量的定义:
pi dd 3.14; 32位小数,相当于float
r  dq  3.14159; 64位小数, 相当于double
; q:quadruple 4倍的
s  dt  3.14159265; 80位小数, 相当于long double
  在C语言中要输出long double的值需要使用"%Lf"格式

CPU内部一共有8个小数寄存器，分别叫做
st(0)、st(1)、…、st(7)
其中st(0)简称st
这8个寄存器的宽度均达到80位，相当于C语言中的
long double类型。
VC里面的long double类型已经退化成double类型。
例子: http://10.71.45.100/bhh/float.asm
 ;Turbo Debugger跟踪时，
;点菜单View->Numeric Processor查看小数堆栈
data segment
abc dd 3.14
xyz dd 2.0;2
result dd 0
data ends
code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   fld abc; 把3.14载入到小数堆栈 --> st(0)
   ;st(0)=3.14
   ;st(1)=null
   fld xyz; 把2.0载入到小数堆栈 --> st(0)
   ;st(0)=2.0
   ;st(1)=3.14
   fild xyz; 读入整数以小数存储
   fmul st, st(1); 两数相乘st(0)=st(0)*st(1)
   ;st(0)=6.28
   ;st(1)=3.14
   fstp result; 保存结果到result，并弹出
   ;[result]=st(0)
   ;st(0)=3.14
   ;st(1)=null
   fstp st      ; 弹出小数堆栈中残余的值
   ;st(0)=st(0)
   ;st(0)=null
   ;st(1)=null
   mov ah, 4Ch
   int 21h
code ends
end main
----------------------------------------------------------------
1. 除法溢出
(1) 除法溢出的两种情形:
①
mov ax, 1234h
mov bh, 0
div bh; 此时因为除以0, 所以会发生除法溢出
②
mov ax, 123h
mov bh, 1
div bh; 此时由于商无法保存到AL中, 因此也会发生溢出。

(2) 除法溢出时会发生什么?
mov ax, 123h
mov ch, 1
;除法溢出时会在此处插入int 00h并执行
;在dos系统下, int 00h会显示溢出信息并终止程序运行
;int 00h 
div ch; 此处发生除法溢出
mov ah, 4Ch; \ 这2条指令将不可能被执行到
int 21h     ; /

不过,我们可以通过修改0:0处的远指针(即int 00h的目标函数地址或中断向量)把我们自己的函数如int_00h与int 00h中断进行绑定,从而使得int 00h发生时让cpu来执行我们自己定义的中断函数int_00h。以下代码通过自定义中断函数int_00h改变ch的值使其等于10h, 于是当cpu从中断函数返回并继续执行div ch时能正常执行除法而不发生溢出:
http://10.71.45.100/bhh/divov.asm
code segment
assume cs:code
old_00h dw 0, 0
int_00h:
   mov ch, 10h
   iret
main:
   push cs
   pop ds
   xor ax, ax
   mov es, ax
   mov bx, 0
   mov ax, es:[bx]
   mov dx, es:[bx+2]
   mov old_00h[0], ax
   mov old_00h[2], dx
   mov word ptr es:[bx], offset int_00h
   mov es:[bx+2], cs
   mov ax, 123h
   mov ch, 1
   div ch
   mov ax, old_00h[0]
   mov dx, old_00h[2]
   mov es:[bx], ax
   mov es:[bx+2], dx
   mov ah, 4Ch
   int 21h
code ends
end main
----------------------------------------------------------------
2. 逻辑运算和移位指令
(1) 逻辑运算指令:  AND，OR，XOR，NOT，TEST
mov ax, 9234h
test ax, 8000h; ZF=0, AX=9234h
jnz msb_is_one; most significant bit最高位
test和and的关系相当于cmp和sub的关系。

判断某个寄存器是否为0的几种方法:
test cl, cl
or cl, cl
and cl, cl
or cl, 0
cmp cl, 0
上述每条指令后面都可以跟jz或jnz来判断CL是否为0。

(2) 移位指令
shl, shr, sal(signed), sar(signed), rol, ror, rcl, rcr

rcl: rotate through carry left 带进位循环左移
rcr: rotate through carry right带进位循环右移
mov ah, 0B6h
stc; CF=1
rcl ah, 1; CF=1 AH=1011 0110 移位前
           ; CF=1 AH=0110 1101 移位后
mov ah, 0B6h
stc; CF=1
rcr ah, 1; AH=1011 0110  CF=1移位前
           ; AH=1101 1011  CF=0移位后
例如: 要把1234ABCDh逻辑左移3位, 结果保存在dx:ax
解法1:
设ax=0ABCDh
and ax, 0E000h

mov dx, 1234h
mov ax, 0ABCDh
mov cl, 3
shl dx, cl
mov bx, ax
shl ax, cl
mov cl, 13
shr bx, cl
or dx, bx
解法2:
mov dx, 1234h
mov ax, 0ABCDh
mov cx, 3
next:
shl ax, 1
rcl dx, 1
dec cx
jnz next


sal: shift arithmetic left  算术左移
sar: shift arithmetic right 算术右移
sal及sar是针对符号数的移位运算, 对负数右移的时候
要在左边补1, 对正数右移的时候左边补0, 无论对正数还是负数左移右边都补0。显然sal≡shl。
shl及shr是针对非符号数的移位运算,无论左移还是
右移, 空缺的部分永远补0。
shl, shr, rol, ror, rcl, rcr最后移出去的那一位一定在CF中。

假定要把AX中的16位值转化成二进制输出:
解法1:
mov cx, 16
next:
shl ax, 1
jc is_1
is_0:
mov dl, '0'
jmp output
is_1:
mov dl, '1'
output:
push ax
mov ah, 2
int 21h
pop ax
dec cx
jnz next
解法2:
mov cx, 16
next:
shl ax, 1
mov dl, '0'
adc dl, 0
output:
push ax
mov ah, 2
int 21h
pop ax
dec cx
jnz next


C语言有2个库函数用来做循环左移及右移:
unsigned int _rotl(unsigned int x, int n)
unsigned int _rotr(unsigned int x, int n)

unsigned int _rotl(unsigned int x, int n)
{
    return x << n  | x >> sizeof(x)*8-n;
}

