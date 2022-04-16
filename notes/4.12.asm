----------------------------------
ss 和 sp
mov eax, 12345678h           
mov ebx, 89ABCDEFh
push eax					 
push ebx
...
pop ebx
pop eax
-----------------------------------
设ss=1000h, sp=200h

ss:1F8h EFh <-	push ebx 后
ss:1F9h CDh
ss:1FAh ABh
ss:1FBh 89h
ss:1FCh 78h <-	push eax 后
ss:1FDh 56h
ss:1FEh 34h
ss:1FFh 12h
ss:200h ??
pop ebx 操作：返回sp指针指向的ebx对象，并且sp指针+4（32bits）若是16位则+2
-------------------------------------
当源代码中没有定义堆栈段时，操作系统会分配一个堆栈段，ss=首段的段地址（5DEDh）, sp=0
5DEDh : 0 data
				长度=10h 字节
5DEEh : 0
或
5DEDh : 10 code 
				长度=20h 字节
5DEDh : 30		假定 ax=1234h 并 push ax


		FFFEh  ---34h <sp 指针
5DEDh : FFFFh  ---12h
------------------------------------
es 寄存器
data1 segment
abc db 1,2,3
data1 ends

data2 segment
xyz db 4,5,6
data2 ends

code segment
assume cs:code, ds:data1, es:data2
main:
   mov ax, data1
   mov ds, ax
   mov ax, data2
   mov es, ax
   mov ah, abc[1]; 编译后变成mov ah, ds:[1]
   ;也可以写成mov ah, ds:abc[1]
   mov xyz[1], ah; 编译后变成mov es:[1], ah
   ;也可以写成mov es:xyz[1], ah
   ;错误写法:mov abc[1], xyz[1]; 因两个对象不能都为内存变量
   mov ah, 4Ch
   int 21h
code ends
end main
--------------------------------------
FL标志寄存器
FL共16位, 但只用其中9位，这9位包括6个状态标志和3个控制标志，如下所示：
11  10  9   8   7  6   4   2   0
O   D    I  T   S  Z   A   P   C
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
×	×	×	×	OF	DF	IF	TF	SF	ZF	×	AF	×	PF	×	CF
0	0	0	0							0		0		1	
CF: 进位标志(carry flag)
mov ah, 0FFh
add ah, 1; AH=0, CF=1产生了进位
add ah, 2; AH=2, CF=0
sub ah, 3; AH=0FFh, CF=1产生了借位
与CF相关的两条跳转指令: jc, jnc

ZF: 零标志(zero flag)
sub ax, ax; AX=0, ZF=1
add ax, 1; AX=1, ZF=0
add ax, 0FFFFh; AX=0, ZF=1, CF=1
jz is_zero; 会发生跳转, 因为当前ZF==1
与jz相反的指令是jnz, jnz是根据ZF==0作出跳转
jz ≡ je jnz ≡ jne
cmp ax, bx （内部会做一次减法运算）

注意:mov指令不影响任何标志位, 例如:
mov ax, 1234h          		mov ax, 1234h
mov bx, 1234h          		mov bx, 1234h
sub ax, bx;ZF=1             sub ax, bx;ZF=1
mov bx, 1;此mov不影      	jz iszero
         ;响sub指令
         ;产生的ZF状态
jz iszero             		mov bx, 0
                        	jmp done; 与左边相比
									; 这里多出一条
									; jmp指令
mov bx, 0      				iszero: ; 故左边写法更好
iszero:              			mov bx, 1
                 			done:
与ZF相关的跳转指令除了jz, jnz还有je, jne
其实je≡jz, jne≡jnz
设ax=1234h, bx=1234h
cmp ax, bx; ZF=1, 因为cmp指令内部做了减法会
; 影响ZF的状态
je is_equal; 写成jz is_equal效果一样


SF: 符号标志(sign flag)
mov ah, 7Fh
add ah, 1; AH=80h=1000 0000B, SF=1
sub ah, 1; AH=7Fh=0111 1111B, SF=0
jns positive; 会发生跳转, 因为SF==0
与jns相反的指令为js, js是根据SF==1作出跳转

CF可以理解成是非符号数的溢出

OF: 溢出标志(overflow flag)
mov ah, 7Fh
add ah, 1; AH=80h, OF=1, ZF=0, CF=0, SF=1
mov ah,  80h
add ah, 0FFh; AH=7Fh, OF=1, ZF=0, CF=1, SF=0
mov ah, 80h
sub ah, 1; AH=7Fh, OF=1, ZF=0, CF=0, SF=0
OF也有两条相关的指令:jo, jno
-------------------------------------------
1. 标志位: PF, AF, DF, IF, TF
(1) PF(Parity Flag)奇偶标志和AF辅助进位标志
mov ah, 4
add ah, 1; AH=0000 0101B, PF=1表示有偶数个1
mov ax, 0101h
add ax, 0004h; AX=0105h=0000 0001 0000 0101B
                ; PF=1只统计低8位中1的个数
要是低8位中1的个数是奇数时，PF=0
PF有两条相关指令: 
jp(当PF==1时则跳), jnp(当PF==0时则跳)
其中jp也可以写成jpe(jump if parity even), 
jnp也可以写成jpo(jump if parity odd)

假定要发送字符'C'=0100 0011B, 现假定低7位为数据位, 
最高位为校验位。那么校验位的计算方法有2种:
(1) 奇校验: 数据位+校验位合起来，1的个数必须是奇数
(2) 偶校验: 数据位+校验位合起来，1的个数必须是偶数
现在我们采用偶校验来发送'C',那么校验位必须等于1,即实际要发送的8位二进制值为1100 0011B。对方接收这8位值并保存在寄存器AL中, 接下去可以执行如下代码来验证AL中的值是否有错:
or al, al
jnp error; if(PF==0) goto error
good:
...
error:
...



AF(Auxiliary Flag) 辅助进位标志
低4位向高4位产生进位或借位
例如:
mov ah, 1Fh; 	0001 1111
add ah, 1  	;	0000 0001 +)
             	; ah=20h, AF=1
AF跟BCD(Binary Coded Decimal)码有关。
mov al, 29h; 分钟
add al, 08 ; 过了8分钟
             ; 31h
daa; decimal adjust for addition加法的十进制调整
; 这条指令会根据AF=1或(AL & 0Fh)>9，做以
; 下运算: AL = AL + 6
; AL=37h

mov al, 29h
add al, 1; AL=2Ah
daa; AL=AL+6=2Ah+6=30h


CF ZF SF OF AF PF: 这6个称为状态标志
DF TF IF: 这3个称为控制标志
DF:direction flag
TF:trace/trap flag
IF:interrupt flag

(2) DF(Direction Flag)方向标志: 控制字符串的操作方向。
当DF=0时为正方向(低地址到高地址)，当DF=1是反方向。
cld指令使DF=0， std指令使DF=1
若源数据首地址>目标数据首地址，则复制时要按正方向
(从低地址到高地址)；
若源数据首地址<目标数据首地址，则复制时要按反方向
(从高地址到低地址)；
strcpy(target, source); 永远按正方向复制
memcpy(target, source, n);永远按正方向复制
memmove(target, source, n); 能正确处理部分重叠
有2条指令可以设置DF的值: 
cld使DF=0, 字符串复制按正方向
std使DF=1, 字符串复制按反方向
若源首地址<目标首地址，则复制按反方向。
1000'A'		1002'A'
1001'B'		1003'B'
1002'C'A	1004'C'
1003'D'B	1005'D'
1004'E'C	1006'E'											
当源首地址>目标首地址时，复制时按正方向
1002'A'C	1000'A'
1003'B'D	1001'B'
1004'C'E	1002'C'
1005'D'		1003'D'
1006'E'		1004'E'

(3) IF（Interrupt Flag）中断标志
mov ah, 1
int 21h;源代码中显示写出int n指令来实现中断
			 ;调用成为软件中断
由硬件事件触发让cpu插入一条隐式的int n指令并调用此指令，称为硬件中断。

当IF=1时,允许中断;否则禁止中断。cli指令使IF=0表示关/禁止硬件中断;
sti指令使IF=1表示开/允许硬件中断。

mov ax, 0
mov bx, 1
next:
add ax, bx
;此时若用户敲键,则CPU会在此处插入一条int 9h指令并执行它
;int 9h的功能是读键盘编码并保存到键盘缓冲区中
add bx, 1
cmp bx, 100
;若程序已运行了1/18秒,则cpu会在此处插入一条int 8h指令
jbe next

用cli和sti把一段代码包围起来可以达到该段代码在
执行过程中不会被打断的效果:
cli; clear interrupt禁止硬件中断
...; 重要代码
sti; set interrupt允许硬件中断
































