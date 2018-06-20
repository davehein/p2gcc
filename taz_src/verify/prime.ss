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


' int prime(int maxnum)
_prime   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, j, numprimes, maxprimes;
'     int count, prime, isprime;
'     short primes[10000];
' 
'     primes[0] = 1;

        sub     sp, ##20028
        mov     r1, #1
        mov     r2, #28
        add     r2, sp
        mov     r3, #0
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     primes[1] = 2;
        mov     r1, #2
        mov     r2, #28
        add     r2, sp
        mov     r3, #1
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

' 
'     printf("%d ", 1);
        calld   lr, #label0002
        byte    "%d ", 0
        alignl
label0002
        mov     r1, lr
        mov     r2, #1
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #8
        rdlong  r0, sp
        add     sp, #4

'     printf("%d ", 2);
        calld   lr, #label0004
        byte    "%d ", 0
        alignl
label0004
        mov     r1, lr
        mov     r2, #2
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #8
        rdlong  r0, sp
        add     sp, #4

' 
'     numprimes = 2;
        mov     r1, #2
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     count = 2;
        mov     r1, #2
        mov     r2, #16
        add     r2, sp
        wrlong  r1, r2

'     maxprimes = 10000;
        mov     r1, ##10000
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     for (i = 3; i < maxnum; i += 2)
        mov     r1, #3
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0005
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0007
        jmp     #label0008
label0006
        mov     r1, #2
        mov     r2, #0
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'     {
        jmp     #label0005
label0007

'         isprime = 1;
        mov     r1, #1
        mov     r2, #24
        add     r2, sp
        wrlong  r1, r2

'         for (j = 2; j < numprimes; j++)
        mov     r1, #2
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2
label0009
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0011
        jmp     #label0012
label0010
        mov     r3, #4
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         {
        jmp     #label0009
label0011

'             prime = primes[j];
        mov     r1, #28
        add     r1, sp
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #1
        add     r1, r2
        rdword  r1, r1
        shl     r1, #16
        sar     r1, #16
        mov     r2, #20
        add     r2, sp
        wrlong  r1, r2

'             if (prime * prime > i) j = numprimes;
        mov     r1, #20
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #20
        add     r2, sp
        rdlong  r2, r2
        qmul    r1, r2
        getqx   r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0013
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'             else if (i / prime * prime == i)
        jmp     #label0014
label0013
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #20
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        call    #__DIVSI
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #20
        add     r2, sp
        rdlong  r2, r2
        qmul    r1, r2
        getqx   r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0015

'                 j = numprimes;
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'                 isprime = 0;
        mov     r1, #0
        mov     r2, #24
        add     r2, sp
        wrlong  r1, r2

'             }
'         }
label0015
label0014

'         if (isprime)
        jmp     #label0010
label0012
        mov     r1, #24
        add     r1, sp
        rdlong  r1, r1

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0016

'             printf("%d ", i);
        calld   lr, #label0018
        byte    "%d ", 0
        alignl
label0018
        mov     r1, lr
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #8
        rdlong  r0, sp
        add     sp, #4

'             if (++count >= 10)
        mov     r3, #16
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3
        mov     r2, #10
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0019

'                 count = 0;
        mov     r1, #0
        mov     r2, #16
        add     r2, sp
        wrlong  r1, r2

'                 printf("\n");
        calld   lr, #label0021
        byte    10, 0
        alignl
label0021
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'             }
'             primes[numprimes++] = i;
label0019
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #28
        add     r2, sp
        mov     r5, #8
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #1
        wrlong  r4, r5
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'             if (numprimes >= maxprimes) i = maxnum;
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0022
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         }
label0022

'     }
label0016

'     if (count)
        jmp     #label0006
label0008
        mov     r1, #16
        add     r1, sp
        rdlong  r1, r1

'         printf("\n");
        cmp     r1, #0  wz
 if_z   jmp     #label0023
        calld   lr, #label0025
        byte    10, 0
        alignl
label0025
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     return 0;
label0023
        mov     r1, #0
        mov     r0, r1
        add     sp, ##20028
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, ##20028
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void main(void)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int max_number;
' 
'     while (1)

        sub     sp, #4
label0026
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0027

'         printf("Enter the max number: ");
        calld   lr, #label0029
        byte    "Enter the max number: ", 0
        alignl
label0029
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'         scanf("%d", &max_number);
        calld   lr, #label0031
        byte    "%d", 0
        alignl
label0031
        mov     r0, lr
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_scanf
        add     sp, #8

'         if (max_number <= 0) break;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0032
        jmp     #label0027

'         if (max_number < 2) continue;
label0032
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0033
        jmp     #label0026

'         prime(max_number);
label0033
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_prime

'     }
' }
        jmp     #label0026
label0027
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF
