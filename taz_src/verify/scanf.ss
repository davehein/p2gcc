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


' void scanf(char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8)
_scanf   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int va;
'     int arglist[8];
'     char inbuf[100];
' 
'     va_start(va, fmt);

        sub     sp, #140
        mov     r9, #0
        mov     r10, #4
        add     r10, sp
        wrlong  r9, r10

'     for (i = 0; i < 8; i++)
        mov     r9, #0
        mov     r10, #0
        add     r10, sp
        wrlong  r9, r10
label0001
        mov     r9, #0
        add     r9, sp
        rdlong  r9, r9
        mov     r10, #8
        cmps    r9, r10  wc
 if_c   mov     r9, #1
 if_nc  mov     r9, #0
        cmp     r9, #0  wz
 if_nz  jmp     #label0003
        jmp     #label0004
label0002
        mov     r11, #0
        add     r11, sp
        rdlong  r9, r11
        add     r9, #1
        wrlong  r9, r11

'         arglist[i] = va_arg(va, int);
        jmp     #label0001
label0003
        mov     r11, #4
        add     r11, sp
        rdlong  r9, r11
        add     r9, #1
        wrlong  r9, r11
        alts    r9, #r0
        mov     r9, 0-0
        mov     r10, #8
        add     r10, sp
        mov     r11, #0
        add     r11, sp
        rdlong  r11, r11
        shl     r11, #2
        add     r10, r11
        wrlong  r9, r10

'     va_end(va);
        jmp     #label0002
label0004


' 
'     gets(inbuf);
        mov     r9, #40
        add     r9, sp
        sub     sp, #36
        setq    #8
        wrlong  r0, sp
        mov     r0, r9
        calld   lr, #_gets
        setq    #8
        rdlong  r0, sp
        add     sp, #36

' 
'     return vsscanf(inbuf, fmt, arglist);
        mov     r9, #40
        add     r9, sp
        mov     r10, r0
        mov     r11, #8
        add     r11, sp
        sub     sp, #36
        setq    #8
        wrlong  r0, sp
        mov     r0, r9
        mov     r1, r10
        mov     r2, r11
        calld   lr, #_vsscanf
        mov     r9, r0
        setq    #8
        rdlong  r0, sp
        add     sp, #36
        mov     r0, r9
        add     sp, #140
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #140
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' EOF

CON
  main = 0
