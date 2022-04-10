data segment
abc db 1,2,3,4
data ends

code segment
assume cs:code, ds:data
;assume es:data并不会把es赋值给data
;所以程序员必须手工对es赋值
;同一个段与多个段寄存器有关联时：ds>ss>es>cs
;当程序从main开始执行时，操作系统会自动对cs:ip及ss:sp进行赋值，
;其中cs=code, ip=offset main, ss=堆栈段的段地址, sp=堆栈段的长度
;ip:instruction pointer指令指针
;sp:stack pointer堆栈指针
;操作系统还会对ds及es做初始化，ds=es=首段地址-10h

main:
    jmp begin ;这条jmp指令的机器码为3字节
              ;向前引用(forward reference),不知道到begin的距离，估计成两个字节，后来发现很近，只要一个字节，多出来的一个就变成nop
xyz db 1,2,3,4
begin:
    ;mov ax, code
    ;mov cs, ax ;语法错误，因为cs不能通过mov来赋值，
               ;只能通过jmp、call等指令间接改变
               ;同理，ip也不能用

    mov ax, data
    mov ds, ax
    mov ah, abc[1]
    ;编译后变成
    mov ah, data:[abc+1] ;指令中引用变量时，
                         ;变量的段地址不能用常数表示，
                         ;所以data必须替换成某个段寄存器(ds,es,ss,cs之一)
    mov ah, data:[0+1]
    mov ah, data:[1] ;根据assume ds:data -->
    mov ah, ds:[1]

    mov al, xyz[1]
    ;编译后变成
    mov al, code:[xyz+1]
    mov al, code:[3+1]
    mov al, code:[4]
    mov al, cs:[4]
code ends
end main
    


