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


' int strtol(char *str, char **endptr, int base)
_strtol  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int negate, value;
'     value = 0;

        sub     sp, #8
        mov     r3, #0
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     negate = 0;
        mov     r3, #0
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

' 
'     // Skip leading blanks
'     while(*str == ' ') str++;
label0001
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #32
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0002
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

' 
'     // Check for + or - 
'     if (*str == '+')
        jmp     #label0001
label0002
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #43
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         str++;
        cmp     r3, #0  wz
 if_z   jmp     #label0003
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'     else if (*str == '-')
        jmp     #label0004
label0003
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #45
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0005

'         str++;
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'         negate = 1;
        mov     r3, #1
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     }
' 
'     // Skip 0x or 0X if base 16
'     if (base == 16)
label0005
label0004
        mov     r3, r2
        mov     r4, #16
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0006

'         if (*str == '0')
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #48
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0007

'             str++;
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'             if (*str == 'x' || *str == 'X')
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #120
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        mov     r4, r0
        rdbyte  r4, r4
        mov     r5, #88
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1

'                 str++;
        cmp     r3, #0  wz
 if_z   jmp     #label0008
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'         }
label0008

'     }
label0007

' 
'     // If base is 0 set it to 8, 10 or 16
'     else if (!base)
        jmp     #label0009
label0006
        mov     r3, r2
        cmp     r3, #0  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0010

'         if (*str == '0')
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #48
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0011

'             str++;
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'             if (*str == 'x' || *str == 'X')
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #120
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        mov     r4, r0
        rdbyte  r4, r4
        mov     r5, #88
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0012

'                 str++;
        mov     r3, r0
        add     r3, #1
        mov     r0, r3

'                 base = 16;
        mov     r3, #16
        mov     r2, r3

'             }
'             else
'                 base = 8;
        jmp     #label0013
label0012
        mov     r3, #8
        mov     r2, r3

'         }
label0013

'         else
'             base = 10;
        jmp     #label0014
label0011
        mov     r3, #10
        mov     r2, r3

'     }
label0014

' 
'     while (*str >= '0')
label0010
label0009
label0015
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #48
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0016

'         if (*str <= '9')
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #57
        cmps    r4, r3 wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0017

'             if (*str - '0' >= base) break;
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #48
        sub     r3, r4
        mov     r4, r2
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0018
        jmp     #label0016

'             value = value*base + (*str++) - '0';
label0018
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r2
        qmul    r3, r4
        getqx   r3
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        rdbyte  r4, r4
        add     r3, r4
        mov     r4, #48
        sub     r3, r4
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'         }
'         else if (*str >= 'a')
        jmp     #label0019
label0017
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #97
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0020

'             if (*str - 'a' + 10 >= base) break;
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #97
        sub     r3, r4
        mov     r4, #10
        add     r3, r4
        mov     r4, r2
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0021
        jmp     #label0016

'             value = value*base + (*str++) - 'a' + 10;
label0021
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r2
        qmul    r3, r4
        getqx   r3
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        rdbyte  r4, r4
        add     r3, r4
        mov     r4, #97
        sub     r3, r4
        mov     r4, #10
        add     r3, r4
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'         }
'         else if (*str >= 'A')
        jmp     #label0022
label0020
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #65
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0023

'             if (*str - 'A' + 10 >= base) break;
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #65
        sub     r3, r4
        mov     r4, #10
        add     r3, r4
        mov     r4, r2
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0024
        jmp     #label0016

'             value = value*base + (*str++) - 'A' + 10;
label0024
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r2
        qmul    r3, r4
        getqx   r3
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        rdbyte  r4, r4
        add     r3, r4
        mov     r4, #65
        sub     r3, r4
        mov     r4, #10
        add     r3, r4
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'         }
'         else
'             break;
        jmp     #label0025
label0023
        jmp     #label0016

'     }
label0025
label0022
label0019

' 
'     if (endptr) *endptr = str;
        jmp     #label0015
label0016
        mov     r3, r1
        cmp     r3, #0  wz
 if_z   jmp     #label0026
        mov     r3, r0
        mov     r4, r1
        wrlong  r3, r4

'     if (negate) value = -value;
label0026
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        cmp     r3, #0  wz
 if_z   jmp     #label0027
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        neg     r3, r3
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

' 
'     return value;
label0027
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r0, r3
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF

CON
  main = 0
