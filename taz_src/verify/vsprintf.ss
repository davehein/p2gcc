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


' //
' // This routines generates a formatted output string based on the string pointed
' // to by "format".  The parameter "arglist" is a pointer to a long array of values
' // that are merged into the output string.  The characters in the format string
' // are copied to the output string, exept for special character sequences that
' // start with %.  The % character is used to merge values from "arglist".  The
' // characters following the % are as follows: %[0][width][.digits][l][type].
' // If a "0" immediately follows the % it indicates that leading zeros should be
' // displayed.  The optional "width" paramter specifieds the minimum width of the
' // field.  The optional ".digits" parameter specifies the number of fractional
' // digits for floating point, or it may also be used to specify leading zeros and
' // the minimum width for integer values.  The "l" parameter indicates long values,
' // and it is ignored in this implementation.  The "type" parameter is a single
' // character that indicates the type of output that should be generated.  It can
' // be one of the following characters:
' //
' // d - signed decimal number
' // i - same as d
' // u - unsigned decimal number
' // x - hexidecimal number
' // o - octal number
' // b - binary number
' // c - character
' // s - string
' // e - floating-point number using scientific notation
' // f - floating-point number in standard notation
' // % - prints the % character
' //
' // Note, care must be taken the the generated output string does not exceed the size
' // of the string.  A string size of 200 bytes is normally more than sufficient.  
' //
' void vsprintf(char *str, char *fmtstr, int *arglist)
_vsprintf global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int arg, width, digits, val;
'     char *fmtstr0;
' 
'     arg = *arglist++;

        sub     sp, #20
        mov     r3, r2
        mov     r4, r3
        add     r4, #4
        mov     r2, r4
        rdlong  r3, r3
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     while (*fmtstr)
label0001
        mov     r3, r1
        rdbyte  r3, r3

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0002

'         if (*fmtstr == '%')
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #37
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0003

'             fmtstr0 = fmtstr + 1;
        mov     r3, r1
        mov     r4, #1
        add     r3, r4
        mov     r4, #16
        add     r4, sp
        wrlong  r3, r4

'             if (*fmtstr0 == '0')
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #48
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0004

'                 width = -1;
        mov     r3, #1
        neg     r3, r3
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'                 digits = getvalue(&fmtstr0);
        mov     r3, #16
        add     r3, sp
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_getvalue
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'             }
'             else
'             {
        jmp     #label0005
label0004

'                 width = getvalue(&fmtstr0);
        mov     r3, #16
        add     r3, sp
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_getvalue
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'                 if (*fmtstr0 == '.')
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #46
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 {
        cmp     r3, #0  wz
 if_z   jmp     #label0006

'                     fmtstr0++;
        mov     r5, #16
        add     r5, sp
        rdlong  r3, r5
        add     r3, #1
        wrlong  r3, r5

'                     digits = getvalue(&fmtstr0);
        mov     r3, #16
        add     r3, sp
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_getvalue
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'                 }
'                 else
'                     digits = -1;
        jmp     #label0007
label0006
        mov     r3, #1
        neg     r3, r3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'             }
label0007

'             if (*fmtstr0 == 'l')
label0005
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #108
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 fmtstr0++;
        cmp     r3, #0  wz
 if_z   jmp     #label0008
        mov     r5, #16
        add     r5, sp
        rdlong  r3, r5
        add     r3, #1
        wrlong  r3, r5

'             val = *fmtstr0;
label0008
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        rdbyte  r3, r3
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'             if (val == 'd' || val == 'i')
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #100
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        mov     r4, #12
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #105
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1

'                 str = putdecstr(str, arg, width, digits);
        cmp     r3, #0  wz
 if_z   jmp     #label0009
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        mov     r3, r6
        calld   lr, #_putdecstr
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3

'             else if (val == 'u')
        jmp     #label0010
label0009
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #117
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 str = putudecstr(str, arg, width, digits);
        cmp     r3, #0  wz
 if_z   jmp     #label0011
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        mov     r3, r6
        calld   lr, #_putudecstr
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3

'             else if (val == 'o')
        jmp     #label0012
label0011
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #111
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 str = putoctalstr(str, arg, width, digits);
        cmp     r3, #0  wz
 if_z   jmp     #label0013
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        mov     r3, r6
        calld   lr, #_putoctalstr
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3

'             else if (val == 'b')
        jmp     #label0014
label0013
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #98
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 str = putbinarystr(str, arg, width, digits);
        cmp     r3, #0  wz
 if_z   jmp     #label0015
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        mov     r3, r6
        calld   lr, #_putbinarystr
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3

'             else if (val == 'x')
        jmp     #label0016
label0015
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #120
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 str = puthexstr(str, arg, width, digits);
        cmp     r3, #0  wz
 if_z   jmp     #label0017
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        mov     r3, r6
        calld   lr, #_puthexstr
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3

'             else if (val == 'c')
        jmp     #label0018
label0017
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #99
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 *str++ = arg;
        cmp     r3, #0  wz
 if_z   jmp     #label0019
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        wrbyte  r3, r4

'             else if (val == '%')
        jmp     #label0020
label0019
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #37
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'                 *str++ = '%';
        cmp     r3, #0  wz
 if_z   jmp     #label0021
        mov     r3, #37
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        wrbyte  r3, r4

'             else if (val == 's')
        jmp     #label0022
label0021
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #115
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0023

'                 strcpy(str, arg);
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_strcpy
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'                 str += strlen(arg);
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_strlen
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r5, r0
        add     r3, r5
        mov     r0, r3

'             }
'             else
'             {
        jmp     #label0024
label0023

'                 *str++ = '%';
        mov     r3, #37
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        wrbyte  r3, r4

'                 continue;
        jmp     #label0001

'             }
'             fmtstr = fmtstr0 + 1;
label0024
label0022
label0020
label0018
label0016
label0014
label0012
label0010
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        mov     r1, r3

'             arg = *arglist++;
        mov     r3, r2
        mov     r4, r3
        add     r4, #4
        mov     r2, r4
        rdlong  r3, r3
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'         }
'         else
'             *str++ = *fmtstr++;
        jmp     #label0025
label0003
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        rdbyte  r3, r3
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        wrbyte  r3, r4

'     }
label0025

'     *str = 0;
        jmp     #label0001
label0002
        mov     r3, #0
        mov     r4, r0
        wrbyte  r3, r4

' }
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine is used to convert a signed integer contained in
' // "number" to a decimal character string.  It is called by itoa when the
' // numeric base parameter has a value of 10.
' //
' int itoa10(int number, char *str)
_itoa10  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *str0;
'     int divisor, temp;
' 
'     str0 = str;

        sub     sp, #12
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (number < 0)
        mov     r2, r0
        mov     r3, #0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0026

'         *str++ = '-';
        mov     r2, #45
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'         if (number == 0x80000000)
        mov     r2, r0
        mov     r3, ##$80000000
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0027

'             *str++ = '2';
        mov     r2, #50
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'             number += 2000000000;
        mov     r2, ##2000000000
        mov     r4, r0
        add     r2, r4
        mov     r0, r2

'         }
'         number = -number;
label0027
        mov     r2, r0
        neg     r2, r2
        mov     r0, r2

'     }
'     else if (number == 0)
        jmp     #label0028
label0026
        mov     r2, r0
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0029

'         *str++ = '0';
        mov     r2, #48
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'         *str = 0;
        mov     r2, #0
        mov     r3, r1
        wrbyte  r2, r3

'         return 1;
        mov     r2, #1
        mov     r0, r2
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     divisor = 1000000000;
label0029
label0028
        mov     r2, ##1000000000
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     while (divisor > number)
label0030
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'       divisor /= 10;
        cmp     r2, #0  wz
 if_z   jmp     #label0031
        mov     r2, #10
        mov     r3, #4
        add     r3, sp
        rdlong  r4, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r4
        sub     sp, #4
        wrlong  r1, sp
        mov     r1, r2
        call    #__DIVSI
        mov     r4, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r4, r3

'     while (divisor > 0)
        jmp     #label0030
label0031
label0032
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0033

'         temp = number / divisor;
        mov     r2, r0
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
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
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'         *str++ = temp + '0';
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #48
        add     r2, r3
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'         number -= temp * divisor;
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        qmul    r2, r3
        getqx   r2
        mov     r4, r0
        sub     r4, r2
        mov     r0, r4

'         divisor /= 10;
        mov     r2, #10
        mov     r3, #4
        add     r3, sp
        rdlong  r4, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r4
        sub     sp, #4
        wrlong  r1, sp
        mov     r1, r2
        call    #__DIVSI
        mov     r4, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r4, r3

'     }
'     *str++ = 0;
        jmp     #label0032
label0033
        mov     r2, #0
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'     return (str - str0 - 1);
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     r2, r3
        mov     r3, #1
        sub     r2, r3
        mov     r0, r2
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine is used to extract the width and digits
' // fields from a format string.  It is called by vsprintf.
' //
' int getvalue(char **pstr)
_getvalue global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int val;
'     char *str;
'     str = *pstr;

        sub     sp, #8
        mov     r1, r0
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (!isdigit(*str)) return -1;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_isdigit
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0034
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     val = 0;
label0034
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     while (isdigit(*str))
label0035
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_isdigit
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'         val = (val * 10) + *str++ - '0';
        cmp     r1, #0  wz
 if_z   jmp     #label0036
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #10
        qmul    r1, r2
        getqx   r1
        mov     r4, #4
        add     r4, sp
        rdlong  r2, r4
        mov     r3, r2
        add     r3, #1
        wrlong  r3, r4
        rdbyte  r2, r2
        add     r1, r2
        mov     r2, #48
        sub     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     *pstr = str;
        jmp     #label0035
label0036
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        wrlong  r1, r2

'     return val;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine is used to generate a formatted string
' // containg at least "width" characters.  The value of count
' // must be identical to the length of the string in "str".
' // Leading spaces will be generated if width is larger than the
' // maximum of count and digits.  Leading zeros will be generated
' // if digits is greater than count.
' //
' char *printpadded(char *str, char *numstr, int count, int width, int digits)
_printpadded global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (digits < count) digits = count;

        mov     r5, r4
        mov     r6, r2
        cmps    r5, r6  wc
 if_c   mov     r5, #1
 if_nc  mov     r5, #0
        cmp     r5, #0  wz
 if_z   jmp     #label0037
        mov     r5, r2
        mov     r4, r5

'     while (width-- > digits) *str++ = ' ';
label0037
label0038
        mov     r5, r3
        mov     r6, r5
        sub     r6, #1
        mov     r3, r6
        mov     r6, r4
        cmps    r6, r5 wc
 if_c   mov     r5, #1
 if_nc  mov     r5, #0
        cmp     r5, #0  wz
 if_z   jmp     #label0039
        mov     r5, #32
        mov     r6, r0
        mov     r7, r6
        add     r7, #1
        mov     r0, r7
        wrbyte  r5, r6

'     if (*numstr == '-')
        jmp     #label0038
label0039
        mov     r5, r1
        rdbyte  r5, r5
        mov     r6, #45
        cmp     r5, r6  wz
 if_z   mov     r5, #1
 if_nz  mov     r5, #0

'     {
        cmp     r5, #0  wz
 if_z   jmp     #label0040

'         *str++ = *numstr++;
        mov     r5, r1
        mov     r6, r5
        add     r6, #1
        mov     r1, r6
        rdbyte  r5, r5
        mov     r6, r0
        mov     r7, r6
        add     r7, #1
        mov     r0, r7
        wrbyte  r5, r6

'         digits--;
        mov     r5, r4
        sub     r5, #1
        mov     r4, r5

'     }
'     while (digits-- > count) *str++ = '0';
label0040
label0041
        mov     r5, r4
        mov     r6, r5
        sub     r6, #1
        mov     r4, r6
        mov     r6, r2
        cmps    r6, r5 wc
 if_c   mov     r5, #1
 if_nc  mov     r5, #0
        cmp     r5, #0  wz
 if_z   jmp     #label0042
        mov     r5, #48
        mov     r6, r0
        mov     r7, r6
        add     r7, #1
        mov     r0, r7
        wrbyte  r5, r6

'     strcpy(str, numstr);
        jmp     #label0041
label0042
        mov     r5, r0
        mov     r6, r1
        sub     sp, #20
        setq    #4
        wrlong  r0, sp
        mov     r0, r5
        mov     r1, r6
        calld   lr, #_strcpy
        setq    #4
        rdlong  r0, sp
        add     sp, #20

'     return str + strlen(numstr);
        mov     r5, r0
        mov     r6, r1
        sub     sp, #24
        setq    #5
        wrlong  r0, sp
        mov     r0, r6
        calld   lr, #_strlen
        mov     r6, r0
        setq    #5
        rdlong  r0, sp
        add     sp, #24
        add     r5, r6
        mov     r0, r5
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine converts a number to a string of binary digits.
' // printpadded is called to insert leading blanks and zeros.
' //
' char *putbinarystr(char *str, int number, int width, int digits)
_putbinarystr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int count;
'     char numstr[36];
' 
'     count = itoa(number, numstr, 2);

        sub     sp, #40
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        mov     r6, #2
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        calld   lr, #_itoa
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     return printpadded(str, numstr, count, width, digits);
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        mov     r6, #0
        add     r6, sp
        rdlong  r6, r6
        mov     r7, r2
        mov     r8, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        mov     r4, r8
        calld   lr, #_printpadded
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r0, r4
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
' //
' // This private routine converts a number to a string of octal digits.
' // printpadded is called to insert leading blanks and zeros.
' //
' char *putoctalstr(char *str, int number, int width, int digits)
_putoctalstr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int count;
'     char numstr[12];
' 
'     count = itoa(number, numstr, 8);

        sub     sp, #16
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        mov     r6, #8
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        calld   lr, #_itoa
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     return printpadded(str, numstr, count, width, digits);
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        mov     r6, #0
        add     r6, sp
        rdlong  r6, r6
        mov     r7, r2
        mov     r8, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        mov     r4, r8
        calld   lr, #_printpadded
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r0, r4
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine converts a number to a string of hexadecimal digits.
' // printpadded is called to insert leading blanks and zeros.
' //
' char *puthexstr(char *str, int number, int width, int digits)
_puthexstr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int count;
'     char numstr[12];
' 
'     count = itoa(number, numstr, 16);

        sub     sp, #16
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        mov     r6, #16
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        calld   lr, #_itoa
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     return printpadded(str, numstr, count, width, digits);
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        mov     r6, #0
        add     r6, sp
        rdlong  r6, r6
        mov     r7, r2
        mov     r8, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        mov     r4, r8
        calld   lr, #_printpadded
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r0, r4
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'    
' //
' // This private routine converts a signed number to a string of decimal
' // digits.  printpadded is called to insert leading blanks and zeros.
' //
' char *putdecstr(char *str, int number, int width, int digits)
_putdecstr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int count;
'     char numstr[12];
' 
'     count = itoa10(number, numstr);

        sub     sp, #16
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_itoa10
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     return printpadded(str, numstr, count, width, digits);
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        mov     r6, #0
        add     r6, sp
        rdlong  r6, r6
        mov     r7, r2
        mov     r8, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        mov     r4, r8
        calld   lr, #_printpadded
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r0, r4
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This private routine converts an unsigned number to a string of decimal
' // digits.  printpadded is called to insert leading blanks and zeros.
' //
' char *putudecstr(char *str, int number, int width, int digits)
_putudecstr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int count;
'     char numstr[12];
'     int adjust;
' 
'     adjust = 0;

        sub     sp, #20
        mov     r4, #0
        mov     r5, #16
        add     r5, sp
        wrlong  r4, r5

'     while (number < 0)
label0043
        mov     r4, r1
        mov     r5, #0
        cmps    r4, r5  wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0

'     {
        cmp     r4, #0  wz
 if_z   jmp     #label0044

'         number -= 1000000000;
        mov     r4, ##1000000000
        mov     r6, r1
        sub     r6, r4
        mov     r1, r6

'         adjust++;
        mov     r6, #16
        add     r6, sp
        rdlong  r4, r6
        add     r4, #1
        wrlong  r4, r6

'     }
'     count = itoa10(number, numstr);
        jmp     #label0043
label0044
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_itoa10
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     *numstr += adjust;
        mov     r4, #16
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #4
        add     r5, sp
        rdbyte  r6, r5
        add     r4, r6
        wrbyte  r4, r5

'     return printpadded(str, numstr, count, width, digits);
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        mov     r6, #0
        add     r6, sp
        rdlong  r6, r6
        mov     r7, r2
        mov     r8, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        mov     r4, r8
        calld   lr, #_printpadded
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r0, r4
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This routine return true if the value of "char" represents an ASCII decimal
' // digit between 0 and 9.  Otherwise, it returns false.
' //
' int isdigit(int val)
_isdigit global
        sub     sp, #4
        wrlong  lr, sp

' {
'   return (val >= '0') & (val <= '9');

        mov     r1, r0
        mov     r2, #48
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        mov     r2, r0
        mov     r3, #57
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        and     r1, r2
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // This routine converts the 32-bit value in "number" to an ASCII string at the
' // location pointed to by "str".  The numeric base is determined by the value
' // of "base", and must be either 2, 4, 8, 10 or 16.  Leading zeros are suppressed,
' // and the number is treated as unsigned except when the base is 10.  The length
' // of the resulting string is returned.
' //
' int itoa(int number, char *str, int base)
_itoa    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int mask, shift, nbits;
'     char *str0;
'     char *HexDigit;
' 
'     if (base == 10) return itoa10(number, str);

        sub     sp, #20
        mov     r3, r2
        mov     r4, #10
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0045
        mov     r3, r0
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_itoa10
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     if (base == 2) nbits = 1;
label0045
        mov     r3, r2
        mov     r4, #2
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0046
        mov     r3, #1
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     else if (base == 4) nbits = 2;
        jmp     #label0047
label0046
        mov     r3, r2
        mov     r4, #4
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0048
        mov     r3, #2
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     else if (base == 8) nbits = 3;
        jmp     #label0049
label0048
        mov     r3, r2
        mov     r4, #8
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0050
        mov     r3, #3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     else if (base == 16) nbits = 4;
        jmp     #label0051
label0050
        mov     r3, r2
        mov     r4, #16
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0052
        mov     r3, #4
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     else
'     {
        jmp     #label0053
label0052

'         *str = 0;
        mov     r3, #0
        mov     r4, r1
        wrbyte  r3, r4

'         return 0;
        mov     r3, #0
        mov     r0, r3
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
' 
'     str0 = str;
label0053
label0051
label0049
label0047
        mov     r3, r1
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'     mask = base - 1;
        mov     r3, r2
        mov     r4, #1
        sub     r3, r4
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     HexDigit = "0123456789abcdef";
        calld   lr, #label0055
        byte    "0123456789abcdef", 0
        alignl
label0055
        mov     r3, lr
        mov     r4, #16
        add     r4, sp
        wrlong  r3, r4

'     if (nbits == 3) shift = 30;
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #3
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0056
        mov     r3, #30
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     else            shift = 32 - nbits;
        jmp     #label0057
label0056
        mov     r3, #32
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        sub     r3, r4
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

' 
'     while (shift > 0 && ((number >> shift) & mask) == 0)
label0057
label0058
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        cmps    r4, r3 wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        sar     r4, r5
        mov     r5, #0
        add     r5, sp
        rdlong  r5, r5
        and     r4, r5
        mov     r5, #0
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        cmp     r3, #0  wz
 if_nz  cmp     r4, #0  wz
 if_nz  mov     r3, #1
 if_z   mov     r3, #0

'         shift -= nbits;
        cmp     r3, #0  wz
 if_z   jmp     #label0059
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #4
        add     r4, sp
        rdlong  r5, r4
        sub     r5, r3
        wrlong  r5, r4

' 
'     while (shift >= 0)
        jmp     #label0058
label0059
label0060
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0061

'         *str++ = HexDigit[(number >> shift) & mask];
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r0
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        sar     r4, r5
        mov     r5, #0
        add     r5, sp
        rdlong  r5, r5
        and     r4, r5
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, r1
        mov     r5, r4
        add     r5, #1
        mov     r1, r5
        wrbyte  r3, r4

'         shift -= nbits;
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #4
        add     r4, sp
        rdlong  r5, r4
        sub     r5, r3
        wrlong  r5, r4

'     }
' 
'     *str = 0;
        jmp     #label0060
label0061
        mov     r3, #0
        mov     r4, r1
        wrbyte  r3, r4

'     return (str - str0);
        mov     r3, r1
        mov     r4, #12
        add     r4, sp
        rdlong  r4, r4
        sub     r3, r4
        mov     r0, r3
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF

CON
  main = 0
