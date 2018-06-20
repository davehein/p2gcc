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


' void printf(char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10)
_printf  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, index;
'     int arglist[10];
'     char outstr[200];
' 
'     va_start(index, fmt);

        sub     sp, #248
        mov     r11, #0
        mov     r12, #4
        add     r12, sp
        wrlong  r11, r12

'     for (i = 0; i < 10; i++)
        mov     r11, #0
        mov     r12, #0
        add     r12, sp
        wrlong  r11, r12
label0001
        mov     r11, #0
        add     r11, sp
        rdlong  r11, r11
        mov     r12, #10
        cmps    r11, r12  wc
 if_c   mov     r11, #1
 if_nc  mov     r11, #0
        cmp     r11, #0  wz
 if_nz  jmp     #label0003
        jmp     #label0004
label0002
        mov     r13, #0
        add     r13, sp
        rdlong  r11, r13
        add     r11, #1
        wrlong  r11, r13

'         arglist[i] = va_arg(index, int);
        jmp     #label0001
label0003
        mov     r13, #4
        add     r13, sp
        rdlong  r11, r13
        add     r11, #1
        wrlong  r11, r13
        alts    r11, #r0
        mov     r11, 0-0
        mov     r12, #8
        add     r12, sp
        mov     r13, #0
        add     r13, sp
        rdlong  r13, r13
        shl     r13, #2
        add     r12, r13
        wrlong  r11, r12

'     va_end(index);
        jmp     #label0002
label0004


'     vsprintf(outstr, fmt, arglist);
        mov     r11, #48
        add     r11, sp
        mov     r12, r0
        mov     r13, #8
        add     r13, sp
        sub     sp, #44
        setq    #10
        wrlong  r0, sp
        mov     r0, r11
        mov     r1, r12
        mov     r2, r13
        calld   lr, #_vsprintf
        setq    #10
        rdlong  r0, sp
        add     sp, #44

'     puts(outstr);
        mov     r11, #48
        add     r11, sp
        sub     sp, #44
        setq    #10
        wrlong  r0, sp
        mov     r0, r11
        calld   lr, #_puts
        setq    #10
        rdlong  r0, sp
        add     sp, #44

' }
        add     sp, #248
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' EOF

CON
  main = 0
