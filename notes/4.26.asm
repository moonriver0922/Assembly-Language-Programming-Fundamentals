2. 对内存变量的访问可以使用两种方式
(1) 直接寻址
设某个8位变量的地址为1000h:2000h，现要取出它的值到AL中:
mov ax, 1000h
mov ds, ax
mov al, ds:[2000h]; 这个就是直接寻址

(2) 间接寻址
①[bx]  [bp]  [si]  [di]就成了最简单的间接寻址方式
[ax]  [cx]  [dx]  [sp]语法错误
②[bx+si] [bx+di] [bp+si] [bp+di]
注意[bx+bp]以及[si+di]是错误的。
③[bx+2] [bp-2] [si+1] [di-1]
④[bx+si+2] [bx+di-2] [bp+si+1]  [bp+di-1]
两个寄存器相加的间接寻址方式中, bx或bp通常用来表示数组的首地址, 而si或di则用来表示下标。
例如: http://10.71.45.100/bhh/arydemo.asm

两个寄存器相加再加一个常数的间接寻址通常用来访问结构数组中某个元素中的某个成员, 例如:
struct student
{
   char name[8];
   short int score;
};
struct student a[10];
ax = a[3].score;
设bx=&a[0], si=30, 
bx+si -> a[3]
则ax=a[3].score可转化成以下汇编代码:
mov ax, [bx+si+8]; /* bx+sia[3] */

-----------------------------------------------------------------------------
how to define a function and call it ?
define:
1. use label (not every label is a function. two features: call and ret)
   f: ; f is the function name
      inc ax
      ret
   main:
      mov ax 3
      call f ; call the function f()
   exit:
      mov ah 2
      mov dl al
      add dl '0'
      int 21h
      mov ah 4ch
      int 21h


2. use proc
;description
;name PROC
   
;name ENDP
   f PROC; procedure
      inc ax
      ret
   f ENDP; end of prodecure
---------------------------------------------------------------------------
;inputs two number 2 bits hex number outputs their sum
;example: inputs:ff02 outputs:0101
.386
code segment use16
assume cs:code
input: ; inputs one bits hex number
   mov ah 1
   int 21h; AL=getchar()
   cmp al 'A'; 'A'==41h, '9'==39h
   jb is_digit
is_alpha:
   sub al 'A'
   add al 10
   jmp input_done
is_digit:
   sub al '0'; AL is the return value of this function
input_done: ; in asm, use al ax eax for the return value usually
   ret

input_a_number: ; inputs two bits hex number
   push bx; prevent the value of bx from being broken
   call input ; inputs 'F' 
   mov bl al
   call input ; inputs 'F'
   shl bl 4
   add al bl; al is the return value(FFh) of the function
   pop bx
   ret

output_a_number:
   push cx
   push dx
   mov cx 4; loop counts
convert_next_digit:
   rol ax 4
   push ax
   and ax 0fh
   cmp al 10
   jb output_is_digit
   sub al 10
   add al 'A'
   jmp output_a_digit
output_is_digit:
   add al '0'
output_a_digit:
   mov ah 2
   mov dl al
   int 21h; putchar(DL)
   pop ax
   sub cx 1
   jnz convert_next_digit
   pop dx
   pop cx
   ret

main:
   call input_a_number
   mov bh 0
   mov bl al; bx=00ff
   call input_a_number
   mov ah 0 ; ax=0002
   add ax bx; calculate the sum
   ;puts arg of the function next in ax, convey arg by register
   call output_a_number; outputs the value of ax as hex number
   mov ah 4ch
   int 21h
code ends
end main
--------------------------------------------------------------------------
3. 端口
CPU  <->  端口(port)  <->  I/O设备
端口编号就是端口地址。
端口地址和内存地址无关。
端口地址的范围是：
[0000h, 0FFFFh]，共65536个端口。
对端口操作使用指令in与out实现。
通过60h号端口，CPU与键盘之间可以建立通讯。
计算机语言有高级、低级之分
汇编语言中要实现相同的功能，其代码也有高级、低级之分
1.dos级别:高
char c;
c = getchar(); 不能读取F1-F12功能键，也不能读home、end、pgup、pgdn
or
scanf("%c", &c);
;-------------------------
mov ah 1
int 21h; AL=键的ASCII码

2.bios级别:中
TC里面有一个bios级别的读键函数:
unsigned short int key;
key = bioskey(0); 能读取F1-F12功能键，也能读取方向键、home、end、pgup、pgdn这些键。
;但不能读ctrl alt shift capslock这些键
;------------------------------------
mov ah 0
int 16h; ax=键盘的编码

3.端口级别:低
TC中可以调用key=inport(0x60); 读取键
;------------------------------------
in al 60h; 端口级别的编程能读到ctrl键


要让硬盘的磁头移动到0道/0头/1扇区并读取该扇区的内容:
1.bios
mov ah 2; 2=read
mov al 80h; c:
mov dh 0; 0头
mov ch 0; 0道
mov cl 1; 1扇区
mov ax seg buf
mov es ax
mov bx offset buf
int 13h; 读取1个扇区共200h字节到es:bx指向的内存
2.端口
需要许多 out/in 指令

in al, 60h; 从端口60h读取一个字节并存放到AL中
mov al 1
out 70h al; send 1 to port 70
例如: http://10.71.45.100/bhh/key.asm

70h及71h端口与cmos内部的时钟有关。
其中cmos中的地址4、2、0中分别保存了当前的时、分、秒，并且格式均为BCD码。
mov al, 2
out 70h, al
in al, 71h; 读取cmos中2号单元的值

mov al, 4
out 70h, al; index hour  inform cmos i will visit 4th memory unit in cmos next
mov al, 23h
out 71h, al; 把cmos4号单元即小时的值改成23点

例如: http://10.71.45.100/bhh/readtime.asm

以读取键盘为例, 以下为从高层到低层的编程方式排序:
dos     	高	mov ah, 1; int 21h 功能弱,但编程简单
bios    	中	mov ah, 0; int 16h
in/out 	低	in al, 60h; 功能强, 但编程麻烦

例如: http://10.71.45.100/bhh/music.asm
---------------------------------------------------------
1. 32位间接寻址方式
(1) 32位比16位多了以下这种寻址方式:
[寄存器+寄存器*n+常数]
其中n=2、4、8。
例如:
mov eax, [ebx + esi*4]
设ebx是数组a的首地址, 下标i用esi表示
则上述语句相当于C语言的: eax = a[i];
long a[4] = {1, 2, 3, 4}, y;
y = a[2];
设 ebx = &a[0], esi = 2是下标
mov y [ebx+esi*4]; 4=sizeof(long int)
mov eax, [ebx+esi*4+6]

VC里面要查看当前C代码对应的机器语言，可以在按F10开始调试后选菜单:
View->Debug Windows->Disassembly
TC里面要查看当前C代码对应的机器语言:
先把ary.c(http://10.71.45.100/bhh/ary.c)拷到dosbox86\tc,
集成环境中选菜单File->Dos Shell->
cd \tc
tc
File->Load->ary.c
Compile->Compile
Compile->Link
File->Quit
td ary.exe
View->CPU

这种寻址方式的应用:
long a[10]={...};
int i, n=10, sum=0;
for(i=0; i<n; i++)
   sum += a[i];
设ebx=&a[0], esi=0, eax=0, 则上述C代码可转化
成以下汇编代码:
again:
add eax, [ebx+esi*4]
add esi, 1
cmp esi, 10
jb again

(2) 32位寻址方式里面，对[]中的两个寄存器几乎不加限制例如:
ebx, ebp, esi, edi, 
eax, ecx, edx, esp都可以放到[]里面;
mov eax, [ebx+ebx*4]; 两个寄存器可以任意组合

2. 段覆盖(segment overriding)
通过在操作数前添加一个段前缀(segment prefix)如CS:、DS:、ES:、SS:来强制改变操作数的段址，这就是段覆盖。
段地址的隐含:
mov ax, [bx]
mov ax, [si]
mov ax, [di+2]
mov ax, [bx+si]
mov ax, [bx+di+2]
mov ax, [1000h]
上述指令的源操作数都省略了段地址ds。

[bp], [bp+2], [bp+si+2], [bp+di-1]
等价于
ss:[bp], ss:[bp+2], ss:[bp+si+2], ss:[bp+di-1]
当[]中包含有寄存器bp时，该变量的段地址一定是ss。
例如:
mov ax, [bp+2] 相当于
mov ax, ss:[bp+2]


默认的段地址是可以改变的, 例如:
mov ax, ds:[bp+2]
这条指令的源操作数段地址从默认的ss改成了ds。
同理,
mov ax, [bx+si+2]改成mov ax, cs:[bx+si+2]的话,
默认段地址就从ds变成了cs。

3.通用数据传送指令:MOV，PUSH，POP，XCHG
mov byte ptr ds:[bx], byte ptr es:[di]
错误原因:两个操作数不能同时为内存变量
以下为正确写法:
mov al, es:[di]
mov ds:[bx], al
push、pop遵循先进后出(FILO)规则,例如:
 
 32位push、pop过程演示:
http://10.71.45.100/bhh/stk1.txt 代码
http://10.71.45.100/bhh/stk2.txt 堆栈布局
push/pop后面也可以跟变量,例如:
push word ptr ds:[bx+2]
pop word ptr es:[di]
8086中, push不能跟常数, 但80386及以后的cpu允许push一个常数。
push/pop 后面不能跟一个8位的寄存器或变量:
push ah; 语法错误 push byte ptr ds:[bx]
pop al;语法错误   pop byte ptr es:[di]

mov ax, 1
mov bx, 2
xchg ax, bx; 则ax=2, bx=1
xchg ax, ds:[bx]

.386
data segment use16
abc dd 7fffffffh; 2147483647
s db 10 dup(' ') 0dh 0ah '$'(字符串结束的标志)
data ends
7fffffffh / 10h will overflow
use 64 bits / 32 bits
code segment use16
assume cs:code ds:data
main:
   mov ax data
   mov ds ax
   mov di 0; 数组s的下标
   mov eax abc
   mov cx 0; 统计push的次数
again:
   mov edx 0; 被除数为edx:eax
   mov ebx 10
   div ebx; eax=商 edx=余数 < 10
   add dl '0' ; edx的高16位及dh一定=0
   push dx
   inc cx; add cx 1
   cmp eax 0
   jne again
pop_again:
   pop dx
   mov s[di] dl
   inc di
   dec cx; 相当于sub cx 1
   jnz pop_again

   mov ah 9
   mov dx offset s
   int 21h
   mov ah 4ch
   int 21h
code ends
end main



