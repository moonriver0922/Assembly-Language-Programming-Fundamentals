(3) IF（Interrupt Flag）中断标志
mov ah, 1
int 21h;源代码中显示写出int n指令来实现中断
			 ;调用成为软件中断
由硬件事件触发让cpu插入一条隐式的int n指令并调用此指令，称为硬件中断。

当IF=1时,允许中断;否则禁止中断。
cli 指令使IF=0表示关/禁止硬件中断;
sti 指令使IF=1表示开/允许硬件中断。
cli 及 sti 在Windows及Linux中(工作在保护模式下)均为特权指令，用户程序不能执行
dos系统中可以实验这两条指令，因为dos工作在实模式下（real mode），
用户代码和操作系统拥有一样的权限

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

(4)TF（Trace/Trap  Flag）跟踪/陷阱标志
当TF=1时,CPU会进入单步模式(single-step mode)。
当TF=1时,CPU在每执行完一条指令后,会自动在该条指令与下条指令之间插入一条int 1h指令并执行它。
已知TF位于FL寄存器的第8位
pushf；把FL压入堆栈
pop ax; AX = FL
or ax， 100h
push  ax
popf；从堆栈中弹出一个16位的值给FL，FL = AX
不能写出 mov FL, ax；因为FL在指令中不能直接引用
类似的，ip寄存器在指令中也不能直接引用



利用单步模式可以实现反调试,演示代码见以下链接:
http://10.71.45.100/bhh/antidbg.zip
请在Bochs虚拟机中用S-ICE对int1dec0.exe进行调试。

利用单步模式可以实现反调试：
进入单步模式
设当前TF=1

Bochs虚拟机中的调试器s-ice可以对i1.exe进行单步调试
bochs\dos.img是虚拟机的硬盘文件
winimage安装后可以自动打开dos.img
双击bochsdbg.exe启动虚拟机
点load->dos.bxrc载入配置文件->start
点continue
nop
; int 1 单步中断
mov ah， 2
; int 1
mov dl， 'A'
; int 1
int 1h 实现用户和调试器交替获得cpu的控制权

中断
example:
mov ah, 1                
int 21h
back:
mov ah, 2
mov dl, al
int 21h   

int 21h发生时，cpu会做3个push + 1个jmp
pushf; 保存以便返回flag的状态
push cs                }返回
push 下条指令的偏移地址  }地址
jmp dword ptr 0:[21h * 4]; 0 : 84 78h   0 : 85 56h  0 : 86 34h  0 : 87 12h
                            int 21h的中断向量 1234h:5678h(can modify to our own function address)
                            1234:5678 ...
                            1234:5679 iret
jmp 之后，完成操作后会执行 iret(go back to back: line64)
iret: pop ip }跳回
      pop cs }back
      popf

trap实验:
code segment
assume cs:code, ds:code
old_1h dw 0, 0
prev_addr: dw offset previous, code

old bp  <- ss:sp ss:bp
offset back
cs
FL
int_1h:
    push bp;protect bp's value
    mov bp sp(sp不能放在[]中)
    push bx;can't break any registers' value
    push es;
    mov bx [bp+2];\es:bx -> first
    mov es [bp+4];/
    sub byte ptr es:[bx], 1; first: 处的指令首字节-1 (解密下条指令)
    push bx
    push es
    mov bx cs:prev_addr[0];\ es:bx -> 上条指令
    mov es cs:prev_addr[2];/
    add byte ptr es:[bx], 1; 加密上条指令
    pop cs:prev_addr[2];\更新prev
    pop cs:prev_addr[0];/
    pop es
    pop bx
    pop bp
    ...
    iret
main:
    push cs
    pop ds
    xor ax, ax; ax = 0 (faster than mov ax 0)
    mov es, ax; es = 0
    mov bx, 1*4; bx = 4
    mov ax, es:[bx]
    mov dx, es:[bx+2]
    mov old_1h[0], ax;\保存int 1h的
    mov old_1h[2], dx;/中断向量
    mov word ptr es:[bx], offset int_1h
    mov word ptr es:[bx+2], cs; seg int_1h
    pushf; TF=0 (copy, convenient for backing flag)
    pushf
    pop ax
    or ax, 100h
    push ax
    popf; TF=1
    ; 没有int 1h
previous:
    nop
    ; 1st int 1h
    ;pushf
    ;push cs
    ;push offset first
    ;jmp dword ptr 0:[4]
first:
    xor ax, ax
    mov cx, 3
next:
    add ax, cx
    sub cx, 1
    jnz next
    ;
    popf; TF=0
    ;final int 1h
    ;执行指令前TF=1，则该指令后会插入int 1h
    nop
    ;这里不再有int 1h
    push old_1h[0]
    pop es:[bx]
    push old_1h[2]
    pop es:[bx+2]
    mov ah 4ch
    int 21h
-----------------------------------------------------------------
4. 乘法指令: mul
8位乘法: 被乘数一定是AL, 乘积一定是AX
例如mul bh表示AX=AL*BH
mov al 12h
mov bl 10h
mul bl; ax = 120h
16位乘法: 被乘数一定是AX, 乘积一定是DX:AX
例如mul bx表示DX:AX=AX*BX
mov ax 1234h
mov bx 100h; 00123400h
mul bx; dx=0012h ax=3400h
32位乘法: 被乘数一定是 EAX, 乘积一定是 EDX:EAX
例如 mul ebx 表示 EDX:EAX=EAX*EBX

利用乘法指令把十进制字符串转化成32位整数的例子:
http://10.71.45.100/bhh/dec2v32.asm
利用乘法指令把十进制字符串转化成16位整数的例子:
http://10.71.45.100/bhh/dec2v16.asm

5. 除法指令: div
(1) 16位除以8位得8位
ax / 除数 = AL..AH
例如: div bh
设 AX=123h, BH=10h
div bh; AL=12h, AH=03h
(2) 32位除以16位得16位
dx:ax / 除数 = ax..dx
例如: div bx
设 dx=123h, ax=4567h, bx=1000h
div bx	; 1234567h/1000h
       	; AX=1234h, DX=0567h
(3) 64位除以32位得32位
edx:eax / 除数 = eax..edx
例如: div ebx
假定要把一个32位整数如7FFF FFFFh转化成十进制格式
则一定要采用(3)这种除法以防止发生除法溢出。
代码: http://10.71.45.100/bhh/val2decy.asm


