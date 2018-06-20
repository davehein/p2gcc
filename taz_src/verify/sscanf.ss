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


' int sscanf(char *str, char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8)
_sscanf  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int va;
'     int arglist[8];
' 
'     va_start(va, fmt);

        sub     sp, #40
        mov     r10, #1
        mov     r11, #4
        add     r11, sp
        wrlong  r10, r11

'     for (i = 0; i < 8; i++)
        mov     r10, #0
        mov     r11, #0
        add     r11, sp
        wrlong  r10, r11
label0001
        mov     r10, #0
        add     r10, sp
        rdlong  r10, r10
        mov     r11, #8
        cmps    r10, r11  wc
 if_c   mov     r10, #1
 if_nc  mov     r10, #0
        cmp     r10, #0  wz
 if_nz  jmp     #label0003
        jmp     #label0004
label0002
        mov     r12, #0
        add     r12, sp
        rdlong  r10, r12
        add     r10, #1
        wrlong  r10, r12

'         arglist[i] = va_arg(va, int);
        jmp     #label0001
label0003
        mov     r12, #4
        add     r12, sp
        rdlong  r10, r12
        add     r10, #1
        wrlong  r10, r12
        alts    r10, #r0
        mov     r10, 0-0
        mov     r11, #8
        add     r11, sp
        mov     r12, #0
        add     r12, sp
        rdlong  r12, r12
        shl     r12, #2
        add     r11, r12
        wrlong  r10, r11

'     va_end(va);
        jmp     #label0002
label0004


' 
'     return vsscanf(str, fmt, arglist);
        mov     r10, r0
        mov     r11, r1
        mov     r12, #8
        add     r12, sp
        sub     sp, #40
        setq    #9
        wrlong  r0, sp
        mov     r0, r10
        mov     r1, r11
        mov     r2, r12
        calld   lr, #_vsscanf
        mov     r10, r0
        setq    #9
        rdlong  r0, sp
        add     sp, #40
        mov     r0, r10
        add     sp, #40
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #40
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int vsscanf(char *str, char *fmt, int *arglist)
_vsscanf global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     char *ptr1;
'     int *iptr;
'     int num;
' 
'     num = 0;

        sub     sp, #16
        mov     r3, #0
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'     ptr = str;
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     while (*fmt)
label0005
        mov     r3, r1
        rdbyte  r3, r3

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0006

'         if (*fmt == '%')
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #37
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0007

'             fmt++;
        mov     r3, r1
        add     r3, #1
        mov     r1, r3

'             if (*fmt == 0) break;
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #0
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0008
        jmp     #label0006

'             if (*fmt == 'd')
label0008
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #100
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0009

'                 iptr = *arglist++;
        mov     r3, r2
        mov     r4, r3
        add     r4, #4
        mov     r2, r4
        rdlong  r3, r3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'                 *iptr = strtol(ptr, &ptr, 10);
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        add     r4, sp
        mov     r5, #10
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        calld   lr, #_strtol
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        wrlong  r3, r4

'             }
'             else if (*fmt == 'x')
        jmp     #label0010
label0009
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #120
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0011

'                 iptr = *arglist++;
        mov     r3, r2
        mov     r4, r3
        add     r4, #4
        mov     r2, r4
        rdlong  r3, r3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'                 *iptr = strtol(ptr, &ptr, 16);
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        add     r4, sp
        mov     r5, #16
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        calld   lr, #_strtol
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        wrlong  r3, r4

'             }
'             else if (*fmt == 's')
        jmp     #label0012
label0011
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #115
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0013

'                 ptr1 = *arglist++;
        mov     r3, r2
        mov     r4, r3
        add     r4, #4
        mov     r2, r4
        rdlong  r3, r3
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'                 while (*ptr && *ptr == ' ') ptr++;
label0014
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        rdbyte  r4, r4
        mov     r5, #32
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        cmp     r3, #0  wz
 if_nz  cmp     r4, #0  wz
 if_nz  mov     r3, #1
 if_z   mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0015
        mov     r5, #0
        add     r5, sp
        rdlong  r3, r5
        add     r3, #1
        wrlong  r3, r5

'                 while (*ptr && *ptr != ' ') *ptr1++ = *ptr++;
        jmp     #label0014
label0015
label0016
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        rdbyte  r4, r4
        mov     r5, #32
        sub     r4, r5  wz
 if_nz  mov     r4, #1
        cmp     r3, #0  wz
 if_nz  cmp     r4, #0  wz
 if_nz  mov     r3, #1
 if_z   mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0017
        mov     r5, #0
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #1
        wrlong  r4, r5
        rdbyte  r3, r3
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        wrbyte  r3, r4

'                 *ptr1 = 0;
        jmp     #label0016
label0017
        mov     r3, #0
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        wrbyte  r3, r4

'             }
'             num++;
label0013
label0012
label0010
        mov     r5, #12
        add     r5, sp
        rdlong  r3, r5
        add     r3, #1
        wrlong  r3, r5

'         }
'         fmt++;
label0007
        mov     r3, r1
        add     r3, #1
        mov     r1, r3

'     }
'     return num;
        jmp     #label0005
label0006
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r0, r3
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF

CON
  main = 0
