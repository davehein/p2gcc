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


' int height = 3;
height long 3

' int xmax = 78;
xmax long 78

' int xmin = 1;
xmin long 1

' int ymax = 22;
ymax long 22

' int ymin = 1;
ymin long 1

' int left = 0;
left long 0

' int right = 0;
right long 0

' int x = 0;
x long 0

' int y = 0;
y long 0

' int xvel = 0;
xvel long 0

' int yvel = 0;
yvel long 0

' int score0 = 0;
score0 long 0

' int score1 = 0;
score1 long 0

' int center = 0;
center long 0

' int xold = 1;
xold long 1

' int yold = 1;
yold long 1

' unsigned char digit[50] = {0x3f, 0x33, 0x33, 0x33, 0x3f, 0x0c, 0x1c, 0x0c,
digit byte $3f, $33, $33, $33, $3f, $0c, $1c, $0c

'     0x0c, 0x1e, 0x3f, 0x03, 0x3f, 0x30, 0x3f, 0x3f, 0x03, 0x0f, 0x03, 0x3f,
  byte $0c, $1e, $3f, $03, $3f, $30, $3f, $3f, $03, $0f, $03, $3f

'     0x33, 0x33, 0x3f, 0x03, 0x03, 0x3f, 0x30, 0x3f, 0x03, 0x3f, 0x3f, 0x30,
  byte $33, $33, $3f, $03, $03, $3f, $30, $3f, $03, $3f, $3f, $30

'     0x3f, 0x33, 0x3f, 0x3f, 0x03, 0x06, 0x06, 0x06, 0x3f, 0x33, 0x3f, 0x33,
  byte $3f, $33, $3f, $3f, $03, $06, $06, $06, $3f, $33, $3f, $33

'     0x3f, 0x3f, 0x33, 0x3f, 0x03, 0x03};
  byte $3f, $3f, $33, $3f, $03, $03

' 
' int isrflag = 0;
        alignl
isrflag long 0

' int isrval;
isrval long 0

' int isr_dummy;
isr_dummy long 0

' 
' void isr(unsigned int val, int count)
_isr     global
        sub     sp, #4
        wrlong  lr, sp

' {
'     inline("getct temp2");

getct temp2

'     inline("add temp2, #25000000/115200");
add temp2, #25000000/115200

'     count = 8;
        mov     r2, #8
        mov     r1, r2

'     while (count--)
label0001
        mov     r2, r1
        mov     r3, r2
        sub     r3, #1
        mov     r1, r3

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0002

'         inline("addct1 temp2, #50000000/115200");
addct1 temp2, #50000000/115200

'         inline("waitct1");
waitct1

'         val = (val >> 1) | (inb & 0x80000000);
        mov     r2, r0
        mov     r3, #1
        shr     r2, r3
        mov     r3, inb
        mov     r4, ##$80000000
        and     r3, r4
        or      r2, r3
        mov     r0, r2

'     }
'     inline("addct1 temp2, #50000000/115200");
        jmp     #label0001
label0002
addct1 temp2, #50000000/115200

'     inline("waitct1");
waitct1

'     isrval = val >> 24;
        mov     r2, r0
        mov     r3, #24
        shr     r2, r3
        wrlong  r2, ##isrval

'     isrflag = 1;
        mov     r2, #1
        wrlong  r2, ##isrflag

'     inline("add sp, #4");
add sp, #4

'     inline("reti1");
reti1

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void install_isr(void)
_install_isr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int isr_address;
'     isr_address = &isr_dummy;

        sub     sp, #4
        mov     r0, ##isr_dummy
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     isr_address += 4;
        mov     r0, #4
        mov     r1, #0
        add     r1, sp
        rdlong  r2, r1
        add     r0, r2
        wrlong  r0, r1

'     inline("rdlong ijmp1, sp"); // Move isr_address to ijmp1
rdlong ijmp1, sp

'     inline("setedg #$bf");      // Set up event for falling edge on pin 63
setedg #$bf

'     inline("setint1 #5");       // Set interrupt 1 for edge event
setint1 #5

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int kbhit()
_kbhit   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return isrflag;

        rdlong  r0, ##isrflag
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getc_isr()
_getc_isr global
        sub     sp, #4
        wrlong  lr, sp

' {
'     while (!isrflag) {}

label0003
        rdlong  r0, ##isrflag
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0004

'     isrflag = 0;
        jmp     #label0003
label0004
        mov     r0, #0
        wrlong  r0, ##isrflag

'     return isrval;
        rdlong  r0, ##isrval
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int main(int argc,  char **argv)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'   int time, deltat;
'   install_isr();

        sub     sp, #8
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_install_isr
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   splash();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_splash
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   initialize();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_initialize
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   deltat = 50000000 / 20;
        mov     r2, ##50000000
        mov     r3, #20
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
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'   time = getcnt();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'   while (1)
label0005
        mov     r2, #1

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0006

'     check_input();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_check_input
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     update_position();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_update_position
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     check_score();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_check_score
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     plotit(xold, yold, getval(xold, yold));
        rdlong  r2, ##xold
        rdlong  r3, ##yold
        rdlong  r4, ##xold
        rdlong  r5, ##yold
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_getval
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_plotit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     plotit(x, y, '@');
        rdlong  r2, ##x
        rdlong  r3, ##y
        mov     r4, #64
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_plotit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     xold = x;
        rdlong  r2, ##x
        wrlong  r2, ##xold

'     yold = y;
        rdlong  r2, ##y
        wrlong  r2, ##yold

'     time += deltat;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'     while ((getcnt() - time) < deltat) time = time;
label0007
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     r2, r3
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0008
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'   }
        jmp     #label0007
label0008

'   putch(13);
        jmp     #label0005
label0006
        mov     r2, #13
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_putch
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   return 0;
        mov     r2, #0
        mov     r0, r2
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
' int getcnt(void)
_getcnt  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     inline("getct reg0");

getct reg0

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Initialize
' void initialize(void)
_initialize global
        sub     sp, #4
        wrlong  lr, sp

' {
'   int i;
'   putch(0);

        sub     sp, #4
        mov     r0, #0
        calld   lr, #_putch

'   center = (xmin + xmax) / 2;
        rdlong  r0, ##xmin
        rdlong  r1, ##xmax
        add     r0, r1
        mov     r1, #2
        sub     sp, #4
        wrlong  r1, sp
        call    #__DIVSI
        rdlong  r1, sp
        add     sp, #4
        wrlong  r0, ##center

'   x = 1;
        mov     r0, #1
        wrlong  r0, ##x

'   y = 10;
        mov     r0, #10
        wrlong  r0, ##y

'   xvel = 1;
        mov     r0, #1
        wrlong  r0, ##xvel

'   yvel = 1;
        mov     r0, #1
        wrlong  r0, ##yvel

'   left = (ymin + ymax) / 2;
        rdlong  r0, ##ymin
        rdlong  r1, ##ymax
        add     r0, r1
        mov     r1, #2
        sub     sp, #4
        wrlong  r1, sp
        call    #__DIVSI
        rdlong  r1, sp
        add     sp, #4
        wrlong  r0, ##left

'   right = left;
        rdlong  r0, ##left
        wrlong  r0, ##right

'   moveto(xmin - 1, ymin - 1);
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##ymin
        mov     r2, #1
        sub     r1, r2
        calld   lr, #_moveto

'   i = xmin - 1;
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'   while (i++ <= xmax + 1)
label0009
        mov     r2, #0
        add     r2, sp
        rdlong  r0, r2
        mov     r1, r0
        add     r1, #1
        wrlong  r1, r2
        rdlong  r1, ##xmax
        mov     r2, #1
        add     r1, r2
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0010

'     putch('#');
        mov     r0, #35
        calld   lr, #_putch

'   }
'   moveto(xmin - 1, ymax + 1);
        jmp     #label0009
label0010
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##ymax
        mov     r2, #1
        add     r1, r2
        calld   lr, #_moveto

'   i = xmin - 1;
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'   while (i++ <= xmax + 1)
label0011
        mov     r2, #0
        add     r2, sp
        rdlong  r0, r2
        mov     r1, r0
        add     r1, #1
        wrlong  r1, r2
        rdlong  r1, ##xmax
        mov     r2, #1
        add     r1, r2
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0012

'     putch('#');
        mov     r0, #35
        calld   lr, #_putch

'   }
'   i = ymin;
        jmp     #label0011
label0012
        rdlong  r0, ##ymin
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'   while (i <= ymax)
label0013
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        rdlong  r1, ##ymax
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0014

'     moveto(center, i);
        rdlong  r0, ##center
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        calld   lr, #_moveto

'     putch('.');
        mov     r0, #46
        calld   lr, #_putch

'     i++;
        mov     r2, #0
        add     r2, sp
        rdlong  r0, r2
        add     r0, #1
        wrlong  r0, r2

'   }
'   plotpaddle(xmin - 1, left);
        jmp     #label0013
label0014
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##left
        calld   lr, #_plotpaddle

'   plotpaddle(xmax + 1, right);
        rdlong  r0, ##xmax
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##right
        calld   lr, #_plotpaddle

'   putnum(center - 8, ymin + 1, 0);
        rdlong  r0, ##center
        mov     r1, #8
        sub     r0, r1
        rdlong  r1, ##ymin
        mov     r2, #1
        add     r1, r2
        mov     r2, #0
        calld   lr, #_putnum

'   putnum(center + 3, ymin + 1, 0);
        rdlong  r0, ##center
        mov     r1, #3
        add     r0, r1
        rdlong  r1, ##ymin
        mov     r2, #1
        add     r1, r2
        mov     r2, #0
        calld   lr, #_putnum

'   moveto(xmin + 1, ymin);
        rdlong  r0, ##xmin
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##ymin
        calld   lr, #_moveto

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void update_position(void)
_update_position global
        sub     sp, #4
        wrlong  lr, sp

' {
'   x += xvel;

        rdlong  r0, ##xvel
        rdlong  r2, ##x
        add     r0, r2
        wrlong  r0, ##x

'   y += yvel;
        rdlong  r0, ##yvel
        rdlong  r2, ##y
        add     r0, r2
        wrlong  r0, ##y

'   if (y < ymin)
        rdlong  r0, ##y
        rdlong  r1, ##ymin
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0015

'     y = ymin - y;
        rdlong  r0, ##ymin
        rdlong  r1, ##y
        sub     r0, r1
        wrlong  r0, ##y

'     yvel = 0 - yvel;
        mov     r0, #0
        rdlong  r1, ##yvel
        sub     r0, r1
        wrlong  r0, ##yvel

'     putch(7);
        mov     r0, #7
        calld   lr, #_putch

'   }
'   else if ( y > ymax)
        jmp     #label0016
label0015
        rdlong  r0, ##y
        rdlong  r1, ##ymax
        cmps    r1, r0 wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0017

'     y = 2 * ymax - y;
        mov     r0, #2
        rdlong  r1, ##ymax
        qmul    r0, r1
        getqx   r0
        rdlong  r1, ##y
        sub     r0, r1
        wrlong  r0, ##y

'     yvel = 0 - yvel;
        mov     r0, #0
        rdlong  r1, ##yvel
        sub     r0, r1
        wrlong  r0, ##yvel

'     putch(7);
        mov     r0, #7
        calld   lr, #_putch

'   }
' }
label0017
label0016
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void check_score(void)
_check_score global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (x <= xmin)

        rdlong  r0, ##x
        rdlong  r1, ##xmin
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0018

'     if (y <= left + height && y >= left - height)
        rdlong  r0, ##y
        rdlong  r1, ##left
        rdlong  r2, ##height
        add     r1, r2
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0
        rdlong  r1, ##y
        rdlong  r2, ##left
        rdlong  r3, ##height
        sub     r2, r3
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        cmp     r0, #0  wz
 if_nz  cmp     r1, #0  wz
 if_nz  mov     r0, #1
 if_z   mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0019

'       x = 2 * xmin - x;
        mov     r0, #2
        rdlong  r1, ##xmin
        qmul    r0, r1
        getqx   r0
        rdlong  r1, ##x
        sub     r0, r1
        wrlong  r0, ##x

'       xvel = 0 - xvel;
        mov     r0, #0
        rdlong  r1, ##xvel
        sub     r0, r1
        wrlong  r0, ##xvel

'       putch(7);
        mov     r0, #7
        calld   lr, #_putch

'     }
'     else
'     {
        jmp     #label0020
label0019

'       scoreit(1);
        mov     r0, #1
        calld   lr, #_scoreit

'     }
'   }
label0020

'   else if ( x >= xmax)
        jmp     #label0021
label0018
        rdlong  r0, ##x
        rdlong  r1, ##xmax
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0022

'     if (y <= right + height &&y >= right - height)
        rdlong  r0, ##y
        rdlong  r1, ##right
        rdlong  r2, ##height
        add     r1, r2
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0
        rdlong  r1, ##y
        rdlong  r2, ##right
        rdlong  r3, ##height
        sub     r2, r3
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        cmp     r0, #0  wz
 if_nz  cmp     r1, #0  wz
 if_nz  mov     r0, #1
 if_z   mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0023

'       x = 2 * xmax - x;
        mov     r0, #2
        rdlong  r1, ##xmax
        qmul    r0, r1
        getqx   r0
        rdlong  r1, ##x
        sub     r0, r1
        wrlong  r0, ##x

'       xvel = 0 - xvel;
        mov     r0, #0
        rdlong  r1, ##xvel
        sub     r0, r1
        wrlong  r0, ##xvel

'       putch(7);
        mov     r0, #7
        calld   lr, #_putch

'     }
'     else
'     {
        jmp     #label0024
label0023

'       scoreit(0);
        mov     r0, #0
        calld   lr, #_scoreit

'     }
'   }
label0024

' }
label0022
label0021
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void check_input(void)
_check_input global
        sub     sp, #4
        wrlong  lr, sp

' {
'   int val;
'   while (kbhit())

        sub     sp, #4
label0025
        calld   lr, #_kbhit
        mov     r0, r0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0026

'     val = getc_isr();
        calld   lr, #_getc_isr
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (val == 'x')
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #120
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0027

'       putch(0);
        mov     r0, #0
        calld   lr, #_putch

'       exit(0);
        mov     r0, #0
        calld   lr, #_exit

'     }
'     if (val == 'q')
label0027
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #113
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0028

'       move_left_up();
        calld   lr, #_move_left_up

'       move_left_up();
        calld   lr, #_move_left_up

'     }
'     if (val == 'a')
label0028
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #97
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0029

'       move_left_down();
        calld   lr, #_move_left_down

'       move_left_down();
        calld   lr, #_move_left_down

'     }
'     if (val == 'p')
label0029
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #112
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0030

'       move_right_up();
        calld   lr, #_move_right_up

'       move_right_up();
        calld   lr, #_move_right_up

'     }
'     if (val == 'l')
label0030
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #108
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0031

'       move_right_down();
        calld   lr, #_move_right_down

'       move_right_down();
        calld   lr, #_move_right_down

'     }
'   }
label0031

' }
        jmp     #label0025
label0026
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void move_left_up(void)
_move_left_up global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (left > ymin + height)

        rdlong  r0, ##left
        rdlong  r1, ##ymin
        rdlong  r2, ##height
        add     r1, r2
        cmps    r1, r0 wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0032

'     plotit(xmin - 1, left + height, ' ');
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##left
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #32
        calld   lr, #_plotit

'     left--;
        rdlong  r0, ##left
        sub     r0, #1
        wrlong  r0, ##left

'     plotit(xmin - 1, left - height, '#');
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##left
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #35
        calld   lr, #_plotit

'   }
' }
label0032
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void move_left_down(void)
_move_left_down global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (left < ymax - height)

        rdlong  r0, ##left
        rdlong  r1, ##ymax
        rdlong  r2, ##height
        sub     r1, r2
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0033

'     plotit(xmin - 1, left - height, ' ');
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##left
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #32
        calld   lr, #_plotit

'     left++;
        rdlong  r0, ##left
        add     r0, #1
        wrlong  r0, ##left

'     plotit(xmin - 1, left + height, '#');
        rdlong  r0, ##xmin
        mov     r1, #1
        sub     r0, r1
        rdlong  r1, ##left
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #35
        calld   lr, #_plotit

'   }
' }
label0033
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void move_right_up(void)
_move_right_up global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (right > ymin + height)

        rdlong  r0, ##right
        rdlong  r1, ##ymin
        rdlong  r2, ##height
        add     r1, r2
        cmps    r1, r0 wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0034

'     plotit(xmax + 1, right + height, ' ');
        rdlong  r0, ##xmax
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##right
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #32
        calld   lr, #_plotit

'     right--;
        rdlong  r0, ##right
        sub     r0, #1
        wrlong  r0, ##right

'     plotit(xmax + 1, right - height, '#');
        rdlong  r0, ##xmax
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##right
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #35
        calld   lr, #_plotit

'   }
' }
label0034
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void move_right_down(void)
_move_right_down global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (right < ymax - height)

        rdlong  r0, ##right
        rdlong  r1, ##ymax
        rdlong  r2, ##height
        sub     r1, r2
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'   {
        cmp     r0, #0  wz
 if_z   jmp     #label0035

'     plotit(xmax + 1, right - height, ' ');
        rdlong  r0, ##xmax
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##right
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #32
        calld   lr, #_plotit

'     right++;
        rdlong  r0, ##right
        add     r0, #1
        wrlong  r0, ##right

'     plotit(xmax + 1, right + height, '#');
        rdlong  r0, ##xmax
        mov     r1, #1
        add     r0, r1
        rdlong  r1, ##right
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #35
        calld   lr, #_plotit

'   }
' }
label0035
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void scoreit(int player)
_scoreit global
        sub     sp, #4
        wrlong  lr, sp

' {
'   if (player)

        mov     r1, r0

'   {
        cmp     r1, #0  wz
 if_z   jmp     #label0036

'     score1 = (score1 + 1) % 10;
        rdlong  r1, ##score1
        mov     r2, #1
        add     r1, r2
        mov     r2, #10
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        call    #__DIVSI
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##score1

'     putnum(center + 3, ymin + 1, score1);
        rdlong  r1, ##center
        mov     r2, #3
        add     r1, r2
        rdlong  r2, ##ymin
        mov     r3, #1
        add     r2, r3
        rdlong  r3, ##score1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_putnum
        rdlong  r0, sp
        add     sp, #4

'     if (right > (ymin + ymax) / 2)
        rdlong  r1, ##right
        rdlong  r2, ##ymin
        rdlong  r3, ##ymax
        add     r2, r3
        mov     r3, #2
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
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0037

'       y = right - height - 3;
        rdlong  r1, ##right
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #3
        sub     r1, r2
        wrlong  r1, ##y

'     }
'     else
'     {
        jmp     #label0038
label0037

'       y = right + height + 3;
        rdlong  r1, ##right
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #3
        add     r1, r2
        wrlong  r1, ##y

'     }
'     x = xmax;
label0038
        rdlong  r1, ##xmax
        wrlong  r1, ##x

'     xvel = 0 - 1;
        mov     r1, #0
        mov     r2, #1
        sub     r1, r2
        wrlong  r1, ##xvel

'   }
'   else
'   {
        jmp     #label0039
label0036

'     score0 = (score0 + 1) % 10;
        rdlong  r1, ##score0
        mov     r2, #1
        add     r1, r2
        mov     r2, #10
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        call    #__DIVSI
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##score0

'     putnum(center - 8, ymin + 1, score0);
        rdlong  r1, ##center
        mov     r2, #8
        sub     r1, r2
        rdlong  r2, ##ymin
        mov     r3, #1
        add     r2, r3
        rdlong  r3, ##score0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_putnum
        rdlong  r0, sp
        add     sp, #4

'     if (left > (ymin + ymax) / 2)
        rdlong  r1, ##left
        rdlong  r2, ##ymin
        rdlong  r3, ##ymax
        add     r2, r3
        mov     r3, #2
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
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0040

'       y = left - height - 3;
        rdlong  r1, ##left
        rdlong  r2, ##height
        sub     r1, r2
        mov     r2, #3
        sub     r1, r2
        wrlong  r1, ##y

'     }
'     else
'     {
        jmp     #label0041
label0040

'       y = left + height + 3;
        rdlong  r1, ##left
        rdlong  r2, ##height
        add     r1, r2
        mov     r2, #3
        add     r1, r2
        wrlong  r1, ##y

'     }
'     x = xmin;
label0041
        rdlong  r1, ##xmin
        wrlong  r1, ##x

'     xvel = 1;
        mov     r1, #1
        wrlong  r1, ##xvel

'   }
'   yvel = 1;
label0039
        mov     r1, #1
        wrlong  r1, ##yvel

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void splash(void)
_splash  global
        sub     sp, #4
        wrlong  lr, sp

' {
'   putch(0);

        mov     r0, #0
        calld   lr, #_putch

'   printf("PONG\r");
        calld   lr, #label0043
        byte    "PONG", 13, 0
        alignl
label0043
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf("----\r");
        calld   lr, #label0045
        byte    "----", 13, 0
        alignl
label0045
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf("Press 'q' and 'a' to move the");
        calld   lr, #label0047
        byte    "Press 'q' and 'a' to move the", 0
        alignl
label0047
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf(" left paddle up and down\r");
        calld   lr, #label0049
        byte    " left paddle up and down", 13, 0
        alignl
label0049
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf("Press 'p' and 'l' to move the");
        calld   lr, #label0051
        byte    "Press 'p' and 'l' to move the", 0
        alignl
label0051
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf(" right paddle up and down\r");
        calld   lr, #label0053
        byte    " right paddle up and down", 13, 0
        alignl
label0053
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf("Press 'x' to exit\r");
        calld   lr, #label0055
        byte    "Press 'x' to exit", 13, 0
        alignl
label0055
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   printf("Press any key to start\r");
        calld   lr, #label0057
        byte    "Press any key to start", 13, 0
        alignl
label0057
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'   getc_isr();
        calld   lr, #_getc_isr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void plotit(int xpos,  int ypos,  int val)
_plotit  global
        sub     sp, #4
        wrlong  lr, sp

' {
'   moveto(xpos, ypos);

        mov     r3, r0
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_moveto
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'   putch(val);
        mov     r3, r2
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_putch
        setq    #2
        rdlong  r0, sp
        add     sp, #12

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void moveto(int xpos,  int ypos)
_moveto  global
        sub     sp, #4
        wrlong  lr, sp

' {
'   putch(2);

        mov     r2, #2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_putch
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   putch(xpos);
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_putch
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'   putch(ypos);
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_putch
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getval(int xpos,  int ypos)
_getval  global
        sub     sp, #4
        wrlong  lr, sp

' {
'   int ptr, val;
'   if (xpos == center)

        sub     sp, #8
        mov     r2, r0
        rdlong  r3, ##center
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0058

'     return '.';
        mov     r2, #46
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
'   if (ypos < ymin + 1 || ypos > ymin + 5)
label0058
        mov     r2, r1
        rdlong  r3, ##ymin
        mov     r4, #1
        add     r3, r4
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r1
        rdlong  r4, ##ymin
        mov     r5, #5
        add     r4, r5
        cmps    r4, r3 wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0
        or      r2, r3  wz
 if_nz  mov     r2, #1

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0059

'     return ' ';
        mov     r2, #32
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
'   if (xpos < center - 8 || xpos > center + 8)
label0059
        mov     r2, r0
        rdlong  r3, ##center
        mov     r4, #8
        sub     r3, r4
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        rdlong  r4, ##center
        mov     r5, #8
        add     r4, r5
        cmps    r4, r3 wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0
        or      r2, r3  wz
 if_nz  mov     r2, #1

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0060

'     return ' ';
        mov     r2, #32
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
'   if (xpos > center - 3 &&xpos < center + 3)
label0060
        mov     r2, r0
        rdlong  r3, ##center
        mov     r4, #3
        sub     r3, r4
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        rdlong  r4, ##center
        mov     r5, #3
        add     r4, r5
        cmps    r3, r4  wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0061

'     return ' ';
        mov     r2, #32
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
'   if (xpos < center)
label0061
        mov     r2, r0
        rdlong  r3, ##center
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0062

'     val = score0;
        rdlong  r2, ##score0
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     xpos -= center - 8;
        rdlong  r2, ##center
        mov     r3, #8
        sub     r2, r3
        mov     r4, r0
        sub     r4, r2
        mov     r0, r4

'   }
'   else
'   {
        jmp     #label0063
label0062

'     val = score1;
        rdlong  r2, ##score1
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     xpos -= center + 3;
        rdlong  r2, ##center
        mov     r3, #3
        add     r2, r3
        mov     r4, r0
        sub     r4, r2
        mov     r0, r4

'   }
'   val = digit[val * 5 + ypos - ymin - 1];
label0063
        mov     r2, ##digit
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #5
        qmul    r3, r4
        getqx   r3
        mov     r4, r1
        add     r3, r4
        rdlong  r4, ##ymin
        sub     r3, r4
        mov     r4, #1
        sub     r3, r4
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'   if (val & (0x20 >> xpos))
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$20
        mov     r4, r0
        sar     r3, r4
        and     r2, r3

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0064

'     return '#';
        mov     r2, #35
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
'   else
'   {
        jmp     #label0065
label0064

'     return ' ';
        mov     r2, #32
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'   }
' }
label0065
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void putnum(int xpos,  int ypos,  int num)
_putnum  global
        sub     sp, #4
        wrlong  lr, sp

' {
'   char *ptr;
'   int temp, i, j;
'   i = 5;

        sub     sp, #16
        mov     r3, #5
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'   ptr = digit + (num % 10) * 5;
        mov     r3, ##digit
        mov     r4, r2
        mov     r5, #10
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r4
        sub     sp, #4
        wrlong  r1, sp
        mov     r1, r5
        call    #__DIVSI
        mov     r4, r1
        rdlong  r1, sp
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4
        mov     r5, #5
        qmul    r4, r5
        getqx   r4
        add     r3, r4
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'   while (i--)
label0066
        mov     r5, #8
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        sub     r4, #1
        wrlong  r4, r5

'   {
        cmp     r3, #0  wz
 if_z   jmp     #label0067

'     j = 6;
        mov     r3, #6
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'     temp = *ptr++;
        mov     r5, #0
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #1
        wrlong  r4, r5
        rdbyte  r3, r3
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     moveto(xpos, ypos++);
        mov     r3, r0
        mov     r4, r1
        mov     r5, r4
        add     r5, #1
        mov     r1, r5
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_moveto
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     while (j--)
label0068
        mov     r5, #12
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        sub     r4, #1
        wrlong  r4, r5

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0069

'       if (temp &0x20)
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #$20
        and     r3, r4

'       {
        cmp     r3, #0  wz
 if_z   jmp     #label0070

'         putch('#');
        mov     r3, #35
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_putch
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'       }
'       else
'       {
        jmp     #label0071
label0070

'         putch(' ');
        mov     r3, #32
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_putch
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'       }
'       temp <<= 1;
label0071
        mov     r3, #1
        mov     r4, #4
        add     r4, sp
        rdlong  r5, r4
        shl     r5, r3
        wrlong  r5, r4

'     }
'   }
        jmp     #label0068
label0069

' }
        jmp     #label0066
label0067
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void plotpaddle(int xpos,  int ypos)
_plotpaddle global
        sub     sp, #4
        wrlong  lr, sp

' {
'   int i;
'   i = ypos - height;

        sub     sp, #4
        mov     r2, r1
        rdlong  r3, ##height
        sub     r2, r3
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'   while (i <= ypos + height)
label0072
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        rdlong  r4, ##height
        add     r3, r4
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'   {
        cmp     r2, #0  wz
 if_z   jmp     #label0073

'     plotit(xpos, i, '#');
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #35
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_plotit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     i++;
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'   }
' }
        jmp     #label0072
label0073
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF
