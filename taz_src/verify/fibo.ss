con
	rx_pin = 63
	tx_pin = 62
	clock_freq = 80_000_000
	baud_rate = 115_200
	lr = $1f6
	init_stack_ptr = 32*1024 - 32*4

dat
	orgh	0

'*******************************************************************************
'  COG Code
'*******************************************************************************
	org

start	call	#prefix_setup
	calld	lr, main_address
	cogid	r1
        mov     r2, #0
        wrlong  r2, r2
	cogstop	r1
main_address
	long	_main

r0	long	0
r1	long	0
r2	long	0
r3	long	0
r4	long	0
r5	long	0
r6	long	0
r7	long	0
r8	long	0
r9	long	0
r10	long	0
r11	long	0
r12	long	0
r13	long	0
r14	long	0
sp	long	0

temp	long    0
temp1	long	0
temp2	long	0

__DIVSI	mov	temp, #0
	abs	r0, r0 wc
 if_c	mov	temp, #1
	abs	r1, r1 wc
 if_c	xor	temp, #1
	call	#__UDIVSI
	cmp	temp, #0 wz
 if_nz	neg	r0, r0
	ret

'__LONGFILL
'        wrfast  #0, r0
'        rep     #1, r2
'        wflong  r1
'        ret

__LONGFILL
        mov     __LONG1, r1
        shr     __LONG1, #9
        or      __LONG1, ##$ff800000
        setd    __LONG2, r1
        sub     r2, #1
        setq    r2
__LONG1 augd    #0
__LONG2 wrlong  #0, r0
        ret

__MEMCPY
        rdbyte  r3, r1
        wrbyte  r3, r0
        add     r0, #1
        add     r1, #1
        djnz    r2, #__MEMCPY
        ret

prefix_setup
	mov	sp, ##init_stack_ptr
	drvh    #tx_pin
        hubset  #$ff
	mov	r0, #1
        qmul    r0, r0
        getqx   __has_cordic
	ret

__has_cordic
	long	0

' Used CORDIC multiply if available
__MULSI cmp	__has_cordic, #0 wz
 if_z   jmp	#__MULSI0
	qmul	r0, r1
	getqx	r0
	getqy	r1
	ret
' else, do shift and add method
__MULSI0
        mov     temp1,#0
        mov     temp2,#32
        shr     r0,#1        wc
__MULSI1
 if_c   add     temp1,r1     wc
        rcr     temp1,#1     wc
        rcr     r0,#1        wc
        djnz    temp2,#__MULSI1
        mov     r1, temp1
        ret

' Used CORDIC divide if available
__UDIVSI
	cmp	__has_cordic, #0 wz
 if_z   jmp	#__UDIVSI0
	qdiv	r0, r1
	getqx	r0
	getqy	r1
	ret
' else, do shift and subtract method
__UDIVSI0
        mov     temp2,#32
        mov     temp1,#0
        cmp     r1, #0       wz
 if_nz  jmp     #__UDIVSI1
        mov     r0, #0
        ret
__UDIVSI1
        shr     r1,#1        wcz
        rcr     temp1,#1
 if_nz  djnz    temp2,#__UDIVSI1
__UDIVSI2
        cmpsub  r0,temp1     wc
        rcl     r1,#1
        shr     temp1,#1
        djnz    temp2,#__UDIVSI2
        mov     temp1, r1
	mov	r1, r0
	mov	r0, temp1
        ret

'*******************************************************************************
'  Program HUB Code
'*******************************************************************************
	orgh	$400


' int fibo(int n)
_fibo    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (n < 2) return (n);

        mov     r1, r0
        mov     r2, #2
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0001
        mov     r1, r0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return fibo(n - 1) + fibo(n - 2);
label0001
        mov     r1, r0
        mov     r2, #1
        sub     r1, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_fibo
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, #2
        sub     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fibo
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        add     r1, r2
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int main(int argc, int argv)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int n;
'     int value;
'     int startTime;
'     int endTime;
'     int executionTime;
'     int rawTime;
' 
'     printf("hello, world!\r\n");

        sub     sp, #24
        calld   lr, #label0003
        byte    "hello, world!", 13, 10, 0
        alignl
label0003
        mov     r2, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r2, sp
        calld   lr, #_printf
        add     sp, #4
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     for (n = 0; n <= 28; n++)
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0004
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #28
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0006
        jmp     #label0007
label0005
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0004
label0006

'         printf("fibo(%d) = ", n);
        calld   lr, #label0009
        byte    "fibo(%d) = ", 0
        alignl
label0009
        mov     r2, lr
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r3, sp
        sub     sp, #4
        wrlong  r2, sp
        calld   lr, #_printf
        add     sp, #8
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         startTime = getcount();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcount
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'         value = fibo(n);
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fibo
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         endTime = getcount();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcount
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #12
        add     r3, sp
        wrlong  r2, r3

'         rawTime = endTime - startTime;
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        sub     r2, r3
        mov     r3, #20
        add     r3, sp
        wrlong  r2, r3

'         executionTime = rawTime / 80000;
        mov     r2, #20
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##80000
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r2
        sub     sp, #4
        wrlong  r1, sp
        mov     r1, r3
        call    #__DIVSI
        rdlong  r1, sp
        add     sp, #4
        mov     r2, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

'         printf ("%d (%dms) (%d ticks)\n", value, executionTime, rawTime);
        calld   lr, #label0011
        byte    "%d (%dms) (%d ticks)", 10, 0
        alignl
label0011
        mov     r2, lr
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #16
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #20
        add     r5, sp
        rdlong  r5, r5
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r5, sp
        sub     sp, #4
        wrlong  r4, sp
        sub     sp, #4
        wrlong  r3, sp
        sub     sp, #4
        wrlong  r2, sp
        calld   lr, #_printf
        add     sp, #16
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
'     return 0;
        jmp     #label0005
label0007
        mov     r2, #0
        mov     r0, r2
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getcount(void)
_getcount global
        sub     sp, #4
        wrlong  lr, sp

' {
'     inline("        getct   reg0");

        getct   reg0

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' EOF
