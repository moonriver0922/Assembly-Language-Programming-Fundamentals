(2) 移位指令
shl, shr, sal, sar, rol,ror, rcl, rcr
上述八条指令最后移出的那个位一定在CF中
mov ah, 10110110B
rol ah, 1; AH=01101101, cf=1
rcl: rotate through carry left 带进位循环左移
rcr: rotate through carry right 带进位循环右移
mov ah, 0B6h
stc; CF=1
rcl ah, 1; CF=1 AH=1 0110110 移位前
           ; CF=1 AH=0110110 1 移位后
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
----------------------------------------------------------------
3. 字符串操作指令
(1) 字符串传送指令: MOVSB，MOVSW，MOVSD
movsb: move string by byte
rep movsb 类似C语言的函数memcpy()的功能
memcpy(char *t, char*s, int n)
把s指向的n个字节复制到t指向的内存块中
strncpy(char *t, char *s, int n)
最大复制字符串为s
其中rep表示repeat，s表示string，b表示byte
在执行此指令前要做以下准备工作：
①ds:si 内存块(si就是source index)
②es:di 目标内存块(di就是destination index)
③cx=移动次数即循环次数
④DF=0即方向标志设成正方向(用指令cld)
rep movsb所做的操作如下:
again:
if(cx == 0)
   goto done;
byte ptr es:[di] = byte ptr ds:[si]
if(df==0)
{si++; di++;}
else
{si--; di--;}
cx--
goto again
done:

单独movsb指令所做的操作如下:
byte ptr es:[di] = byte ptr ds:[si]
if(df==0)
{si++; di++;}
else
{si--; di--;}

例子: 要把以下左侧4个字节复制到右侧
1000:0000 'A'        2000:0000  'A'
1000:0001 'B'        2000:0001  'B'
1000:0002 'C'        2000:0002  'C'
1000:0003 00         2000:0003  00
则程序可以这样写:
mov ax, 1000h
mov ds, ax
mov si, 0      ; mov si, 3
mov ax, 2000h
mov es, ax
mov di, 0      ; mov di, 3
mov cx, 4
cld             ; std
rep movsb
循环结束时         循环结束时
si=4              si=FFFF
di=4              di=FFFF
cx=0              cx=0

rep movsw的操作过程:
again:
if(cx == 0)
   goto done;
word ptr es:[di] = word ptr ds:[si]
if(df==0)
{si+=2; di+=2;}
else
{si-=2; di-=2;}
cx--
goto again
done:

rep movsd的操作过程:
again:
if(cx == 0)
   goto done;
dword ptr es:[di] = dword ptr ds:[si]
if(df==0)
{si+=4; di+=4;}
else
{si-=4; di-=4;}
cx--
goto again
done:

在32位系统下, 假定ds:esi->源内存块, es:edi->目标块, DF=0, 则当要复制的字节数ecx不是4的倍数时，可以做如下处理:
push ecx
shr ecx, 2
rep movsd
pop ecx
and ecx, 3; 相当于ecx = ecx % 4
rep movsb

(2) 字符串比较指令: CMPSB，CMPSW，CMPSD
①cmpsb
比较byte ptr ds:[si]与byte ptr es:[di]
当DF=0时，SI++，DI++
当DF=1时，SI--，DI--
②repe cmpsb;(若本次比较相等则继续比较下一个)
again:
if(cx == 0) goto done;
比较byte ptr ds:[si]与byte ptr es:[di]
当DF=0时，SI++，DI++
当DF=1时，SI--，DI--
cx--
若本次比较相等则 goto again
done:
③repne cmpsb
(若本次比较不等则继续比较下一个)

1000:10A0	‘A’		2000:20F0	‘A’ 
1000:10A1	‘B’		2000:20F1	‘B’ 
1000:10A2	‘C’		2000:20F2	‘C’ 
1000:10A3	‘1’		2000:20F3	‘4’ 
1000:10A4	‘2’		2000:20F4	‘5’ 
1000:10A5	‘3’		2000:20F5	‘6’ 
设ds=1000h, si=10A0h, es=2000h, di=20F0h
cx=6, DF=0
repe cmpsb     
je equal; 全等 或 jz equal
dec si       
dec di   
...    
equal:
(3) 字符串扫描指令: scasb，scasw, scasd
scasb:
  cmp al, es:[di]
  di++; 当DF=1时，为di--

repne scasb:
next:
  if(cx == 0) goto done;
  cmp al, es:[di]
      di++; 当DF=1时，为di--
      cx--
  je done
  goto next
done:

例子: 假定从地址1000:2000开始存放一个字符串，请计算该字符串的长度并存放到CX中。假定字符串以ASCII码0结束，字符串长度不包括0。
mov ax, 1000h
mov es, ax
mov di, 2000h; ES:DI目标串
mov cx, 0FFFFh; CX=最多找FFFF次
mov al, 0; AL=待找的字符
cld       ; DF=0，表示正方向
repne scasb; again:
not cx      ; 相当于cx=FFFF-cx
dec cx
;上述两条指令也可以替换成以下两条指令:
;inc cx
;not cx

repe scasb
假定从地址1000:0000起存放以下字符串:
"###ABC"，现要求跳过前面的#，把后面剩余的
全部字符复制到2000:0000中。
假定es=1000h, di=0, cx=7, 则
mov al, '#'
cld
repe scasb
dec di; ES:DI->"ABC"
inc cx; CX=4
push es
pop ds; DS=ES
push di
pop si; SI=DI
mov ax, 2000h
mov es, ax
mov di, 0
rep movsb
-----------------------------------
1. 字符串操作指令stosb及lodsb
(1) stosb, stosw, stosd
stosb:
stosb的操作过程如下:
es:[di] = AL
di++; DF=1时为di--
rep stosb: 循环CX次stosb,实现C语言的memset()
rep stosb的操作过程:
again:
if(cx == 0) goto done;
ES:[DI] = AL
DI++; 当DF=1时, 为DI--
CX--
goto again;
done:

例: 把从地址1000:10A0开始共100h个字节的
内存单元全部填0
mov ax, 1000h
mov es, ax; ES=1000h
mov di, 10A0h                    	mov di,10A0h
mov cx, 100h     mov cx, 80h    	mov cx,40h
cld                cld             	cld
xor al, al       xor ax, ax     	xor eax, eax
rep stosb        rep stosw       	rep stosd

(2) lodsb
lodsb的操作过程:
AL=DS:[SI]
SI++;当DF=1时, 为SI--

例: 设DS:SI "##AB#12#XY"
且ES:DI指向一个空的数组, CX=11
通过编程过滤#最后使得ES:DI "AB12XY"
   cld
again:
   lodsb; AL=DS:[SI], SI++
         ; mov al, ds:[si]
         ; inc si
   cmp al, '#'
   je   next
   stosb; ES:[DI]=AL, DI++
         ; mov es:[di], al
         ; inc di
next:
   dec cx
   jnz again

si: source index  和ds配合
di: destination index  和es配合
--------------------------------------------------------
2. 控制转移指令
(1) jmp的3种类型
①jmp short target		; 短跳
②jmp near ptr target 	; 近跳
③jmp far ptr target  	; 远跳
一般情况下，编译器会自动度量跳跃的距离，因此我们在
写源程序的时候不需要加上short、near ptr、far ptr等类型修饰。即上述三种写法一律可以简化为jmp target。

(2)短跳指令
①短跳指令的格式
jmp 偏移地址或标号
以下条件跳转指令也都属于短跳: jc jnc jo jno js jns jz jnz ja jb jae jbe jg jge jl jle jp jnp

②短跳指令的机器码
      地址            机器码   汇编指令  
    1D3E:0090     ...
    1D3E:0100     EB06(为什么不直接采用地址值？方便代码的移动)     jmp  108h
短跳指令的机器码由2字节构成:
第1个字节=EB
第2个字节=短跳的距离
短跳的距离Δ=目标地址-下条指令的偏移地址=108h-102h=06h
    1D3E:0102     B402     mov  ah，2
    1D3E:0104     B241     mov  dl, 41h
    1D3E:0106     CD21     int  21h
    1D3E:0108     B44C     mov  ah，4Ch
    1D3E:010A     CD21     int  21h
   例:自我移动的代码 http://10.71.45.100/bhh/movcode.asm
   例: 修改printf让它做加法运算http://10.71.45.100/bhh/printf.c

③ 短跳太远跳不过去的解决办法
cmp ax, bx
;je  equal; jump out of range
jne not_equal
jmp equal; 近跳
not_equal:
...; 假定这里省略指令的机器码总长度超过7Fh字节
equal:
...

(3)近跳指令
①近跳指令的3种格式
jmp 偏移地址或标号; 如jmp 1000h
jmp 16位寄存器		; 如jmp bx
jmp 16位变量  		; 如jmp word ptr [addr]

②近跳指令的机器码
  地址        机器码      汇编指令    
1D3E:0100   E9FD1E      jmp  2000h
近跳指令的第1个字节=E9
第2个字节=Δ=目标地址-下条指令的偏移地址
=2000h-103h=1EFDh
1D3E:0103   B44C         mov  ah，4Ch
1D3E:0105   CD21         int  21h
...
1D3E:2000   ...

byte ptr ; 1字节
word ptr ; 2字节
dword ptr; 4字节(32位整数或float类型小数)
fword ptr; 6字节(4字节偏移地址+2字节段地址)
qword ptr; 8字节(64位整数或double类型小数)
tbyte ptr; 10字节(long double类型的80位小数)
short     用来修饰一个短的标号
near ptr 用来修饰一个近的标号
far ptr  用来修饰一个远的标号

(4)远跳指令
①远跳指令的2种格式
jmp 段地址:偏移地址
jmp dword ptr 32位变量
②远跳指令的机器码
jmp 1234h:5678h; 机器码为0EAh,78h,56h,34h,12h
远跳到某个常数地址时,在源程序中不能直接用jmp指令，而应该改用机器码0EAh定义，如:
db 0EAh
dw 5678h
dw 1234h
上述3行定义合在一起表示jmp 1234h:5678h

例: jmp dword ptr 32位变量 的用法
data segment
addr dw 0000h, 0FFFFh 
;或写成addr dd 0FFFF0000h
data ends
code segment
assume cs:code, ds:data
main:
mov ax, data
mov ds, ax
jmp dword ptr [addr] 
;相当于jmp FFFF:0000
code ends
end main
 例: 演示短跳、近跳、远跳 http://10.71.45.100/bhh/jmp.asm
3. 循环指令：LOOP
loop  dest的操作过程:
CX = CX - 1   	; 循环次数减1
if(CX != 0)   	; 若CX不等于0，则
    goto  dest 	; 跳转至dest

例: 求1+2+3的和
mov ax, 0
mov cx, 3
next:
add ax, cx; ax +3, +2, +1
loop next; cx=2, 1, 0
           ; dec cx
           ; jnz next
done:


mov ax, 0
mov cx, 0
jcxz done  这条指令可以防止cx为0时进入循环
next:
add ax, cx
loop next; 循环10000h次
done:
