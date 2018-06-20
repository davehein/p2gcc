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


' //  sdspi:  SPI interface to a Secure Digital card.
' //
' //  Copyright 2008   Radical Eye Software
' //
' //  See end of file for terms of use.
' //
' //  This version is in Spin so it is very slow (3Kb/sec).
' //  A version in assembly is about 100x faster.
' //
' //  You probably never want to call this; you want to use fswr
' //  instead (which calls this); this is only the lowest layer.
' //
' //  Assumes SD card is interfaced using four consecutive Propeller
' //  pins, as follows (assuming the base pin is pin 0):
' //
' //  The 150 ohm resistors are current limiters and are only
' //  needed if you don't trust your code (and don't want an SD
' //  driven signal to conflict with a Propeller driven signal).
' //  A value of 150 should be okay, unless you've got some
' //  unusually high capacitance on the line.  The 20k resistors
' //  are pullups, and should be there on all six lines (even
' //  the ones we don't drive).
' //
' //  This code is not general-purpose SPI code; it's very specific
' //  to reading SD cards, although it can be used as an example.
' //
' //  The code does not use CRC at the moment (this is the default).
' //  With some additional effort we can probe the card to see if it
' //  supports CRC, and if so, turn it on.   
' //
' //  All operations are guarded by a watchdog timer, just in case
' //  no card is plugged in or something else is wrong.  If an
' //  operation does not complete in one second it is aborted.
' //
' int di_pin, do_pin, clk_pin, cs_pin, starttime;
di_pin long 0
do_pin long 0
clk_pin long 0
cs_pin long 0
starttime long 0

' int di_mask, do_mask, clk_mask, cs_mask;
di_mask long 0
do_mask long 0
clk_mask long 0
cs_mask long 0

' 
' void errorexit(int val)
_errorexit global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("errorexit: %d\n", val);

        calld   lr, #label0002
        byte    "errorexit: %d", 10, 0
        alignl
label0002
        mov     r1, lr
        mov     r2, r0
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

'     exit(1);
        mov     r1, #1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_exit
        rdlong  r0, sp
        add     sp, #4

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void getcnt(void)
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
' void release(void)
_release global
        sub     sp, #4
        wrlong  lr, sp

' {
'     outa |= clk_mask | di_mask | cs_mask;

        rdlong  r0, ##clk_mask
        rdlong  r1, ##di_mask
        or      r0, r1
        rdlong  r1, ##cs_mask
        or      r0, r1
        mov     r2, outa
        or      r0, r2
        mov     outa, r0

'     dira &= ~(clk_mask | di_mask | cs_mask);
        rdlong  r0, ##clk_mask
        rdlong  r1, ##di_mask
        or      r0, r1
        rdlong  r1, ##cs_mask
        or      r0, r1
        xor     r0, ##$ffffffff
        mov     r2, dira
        and     r0, r2
        mov     dira, r0

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Send eight bits, then raise di.
' //
' void send(int outv)
_send    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     for (i = 0; i < 8; i++)

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0003
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0005
        jmp     #label0006
label0004
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0003
label0005

'         outa &= ~clk_mask;
        rdlong  r1, ##clk_mask
        xor     r1, ##$ffffffff
        mov     r3, outa
        and     r1, r3
        mov     outa, r1

'         if (outv & 0x80)
        mov     r1, r0
        mov     r2, #$80
        and     r1, r2

'             outa |= di_mask;
        cmp     r1, #0  wz
 if_z   jmp     #label0007
        rdlong  r1, ##di_mask
        mov     r3, outa
        or      r1, r3
        mov     outa, r1

'         else
'             outa &= ~di_mask;
        jmp     #label0008
label0007
        rdlong  r1, ##di_mask
        xor     r1, ##$ffffffff
        mov     r3, outa
        and     r1, r3
        mov     outa, r1

'         outv <<= 1;
label0008
        mov     r1, #1
        mov     r3, r0
        shl     r3, r1
        mov     r0, r3

'         outa |= clk_mask;
        rdlong  r1, ##clk_mask
        mov     r3, outa
        or      r1, r3
        mov     outa, r1

'     }
' 
'     outa |= di_mask;
        jmp     #label0004
label0006
        rdlong  r1, ##di_mask
        mov     r3, outa
        or      r1, r3
        mov     outa, r1

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Did we go over our time limit yet?
' //
' void checktime(void)
_checktime global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (getcnt() - starttime > 50000000)

        calld   lr, #_getcnt
        mov     r0, r0
        rdlong  r1, ##starttime
        sub     r0, r1
        mov     r1, ##50000000
        cmps    r1, r0 wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'         errorexit(-41); // Timeout during read
        cmp     r0, #0  wz
 if_z   jmp     #label0009
        mov     r0, #41
        neg     r0, r0
        calld   lr, #_errorexit

' }
label0009
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Read eight bits from the card.
' //
' int read(void)
_read    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, r;
' 
'     r = 0;

        sub     sp, #8
        mov     r0, #0
        mov     r1, #4
        add     r1, sp
        wrlong  r0, r1

'     for (i = 0; i < 8; i++)
        mov     r0, #0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1
label0010
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #8
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        cmp     r0, #0  wz
 if_nz  jmp     #label0012
        jmp     #label0013
label0011
        mov     r2, #0
        add     r2, sp
        rdlong  r0, r2
        add     r0, #1
        wrlong  r0, r2

'     {
        jmp     #label0010
label0012

'         outa &= ~clk_mask;
        rdlong  r0, ##clk_mask
        xor     r0, ##$ffffffff
        mov     r2, outa
        and     r0, r2
        mov     outa, r0

'         outa |= clk_mask;
        rdlong  r0, ##clk_mask
        mov     r2, outa
        or      r0, r2
        mov     outa, r0

'         r <<= 1;
        mov     r0, #1
        mov     r1, #4
        add     r1, sp
        rdlong  r2, r1
        shl     r2, r0
        wrlong  r2, r1

'         if (ina & do_mask)
        mov     r0, ina
        rdlong  r1, ##do_mask
        and     r0, r1

'             r |= 1;
        cmp     r0, #0  wz
 if_z   jmp     #label0014
        mov     r0, #1
        mov     r1, #4
        add     r1, sp
        rdlong  r2, r1
        or      r0, r2
        wrlong  r0, r1

'     }
label0014

'     return r;
        jmp     #label0011
label0013
        mov     r0, #4
        add     r0, sp
        rdlong  r0, r0
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
' //  Read eight bits, and loop until we
' //  get something other than $ff.
' //
' int readresp(void)
_readresp global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
' 
'     while (1)

        sub     sp, #4
label0015
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0016

'         r = read();
        calld   lr, #_read
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'         if (r != 0xff) break;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #$ff
        sub     r0, r1  wz
 if_nz  mov     r0, #1
        cmp     r0, #0  wz
 if_z   jmp     #label0017
        jmp     #label0016

'         checktime();
label0017
        calld   lr, #_checktime

'     }
' 
'     return r;
        jmp     #label0015
label0016
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     
' //
' //  Wait until card stops returning busy
' //
' int busy(void)
_busy    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
' 
'     while (1)

        sub     sp, #4
label0018
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0019

'         r = read();
        calld   lr, #_read
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'         if (r) break;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0020
        jmp     #label0019

'         checktime();
label0020
        calld   lr, #_checktime

'     }
' 
'     return r;
        jmp     #label0018
label0019
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Send a full command sequence, and get and
' //  return the response.  We make sure cs is low,
' //  send the required eight clocks, then the
' //  command and parameter, and then the CRC for
' //  the only command that needs one (the first one).
' //  Finally we spin until we get a result.
' //
' int cmd(int op, int parm)
_cmd     global
        sub     sp, #4
        wrlong  lr, sp

' {
'     outa &= ~cs_mask;

        rdlong  r2, ##cs_mask
        xor     r2, ##$ffffffff
        mov     r4, outa
        and     r2, r4
        mov     outa, r2

'     read();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(0x40+op);
        mov     r2, #$40
        mov     r3, r0
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(parm >> 15);
        mov     r2, r1
        mov     r3, #15
        sar     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(parm >> 7);
        mov     r2, r1
        mov     r3, #7
        sar     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(parm << 1);
        mov     r2, r1
        mov     r3, #1
        shl     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(0);
        mov     r2, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(0x95);
        mov     r2, #$95
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return readresp();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_readresp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Deselect the card to terminate a command.
' //
' int endcmd(void)
_endcmd  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     outa |= cs_mask;

        rdlong  r0, ##cs_mask
        mov     r2, outa
        or      r0, r2
        mov     outa, r0

'     return 0;
        mov     r0, #0
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Initialize the card!  Send a whole bunch of
' //  clocks (in case the previous program crashed
' //  in the middle of a read command or something),
' //  then a reset command, and then wait until the
' //  card goes idle.  If you want to change this
' //  method to make the pins not be adjacent, all you
' //  need to do is change these first four lines.
' //
' int sdspi_start_explicit(int DO, int CLK, int DI, int CS)
_sdspi_start_explicit global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     do_pin  = DO;

        sub     sp, #4
        mov     r4, r0
        wrlong  r4, ##do_pin

'     clk_pin = CLK;
        mov     r4, r1
        wrlong  r4, ##clk_pin

'     di_pin  = DI;
        mov     r4, r2
        wrlong  r4, ##di_pin

'     cs_pin  = CS;
        mov     r4, r3
        wrlong  r4, ##cs_pin

'     do_mask  = 1 << do_pin;
        mov     r4, #1
        rdlong  r5, ##do_pin
        shl     r4, r5
        wrlong  r4, ##do_mask

'     clk_mask = 1 << clk_pin;
        mov     r4, #1
        rdlong  r5, ##clk_pin
        shl     r4, r5
        wrlong  r4, ##clk_mask

'     di_mask  = 1 << di_pin;
        mov     r4, #1
        rdlong  r5, ##di_pin
        shl     r4, r5
        wrlong  r4, ##di_mask

'     cs_mask  = 1 << cs_pin;
        mov     r4, #1
        rdlong  r5, ##cs_pin
        shl     r4, r5
        wrlong  r4, ##cs_mask

' 
'     outa |= clk_mask | di_mask | cs_mask;
        rdlong  r4, ##clk_mask
        rdlong  r5, ##di_mask
        or      r4, r5
        rdlong  r5, ##cs_mask
        or      r4, r5
        mov     r6, outa
        or      r4, r6
        mov     outa, r4

'     dira |= clk_mask | di_mask | cs_mask;
        rdlong  r4, ##clk_mask
        rdlong  r5, ##di_mask
        or      r4, r5
        rdlong  r5, ##cs_mask
        or      r4, r5
        mov     r6, dira
        or      r4, r6
        mov     dira, r4

' 
'     starttime = getcnt();
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        wrlong  r4, ##starttime

'     for (i = 0; i < 600; i++) read();
        mov     r4, #0
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5
label0021
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, ##600
        cmps    r4, r5  wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        cmp     r4, #0  wz
 if_nz  jmp     #label0023
        jmp     #label0024
label0022
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        add     r4, #1
        wrlong  r4, r6
        jmp     #label0021
label0023
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_read
        setq    #3
        rdlong  r0, sp
        add     sp, #16

' 
'     cmd(0, 0);
        jmp     #label0022
label0024
        mov     r4, #0
        mov     r5, #0
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_cmd
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     endcmd();
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_endcmd
        setq    #3
        rdlong  r0, sp
        add     sp, #16

' 
'     while (1)
label0025
        mov     r4, #1

'     {
        cmp     r4, #0  wz
 if_z   jmp     #label0026

'         cmd(55, 0);
        mov     r4, #55
        mov     r5, #0
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_cmd
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'         i = cmd(41, 0);
        mov     r4, #41
        mov     r5, #0
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_cmd
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'         endcmd();
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_endcmd
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'         if (i != 1) break;
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #1
        sub     r4, r5  wz
 if_nz  mov     r4, #1
        cmp     r4, #0  wz
 if_z   jmp     #label0027
        jmp     #label0026

'     }
label0027

' 
'     if (i)
        jmp     #label0025
label0026
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4

'        errorexit(-40); // could not initialize card
        cmp     r4, #0  wz
 if_z   jmp     #label0028
        mov     r4, #40
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_errorexit
        setq    #3
        rdlong  r0, sp
        add     sp, #16

' 
'     return 0;
label0028
        mov     r4, #0
        mov     r0, r4
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int sdspi_start(basepin)
_sdspi_start global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return sdspi_start_explicit(basepin, basepin+1, basepin+2, basepin+3);

        mov     r1, r0
        mov     r2, r0
        mov     r3, #1
        add     r2, r3
        mov     r3, r0
        mov     r4, #2
        add     r3, r4
        mov     r4, r0
        mov     r5, #3
        add     r4, r5
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        mov     r3, r4
        calld   lr, #_sdspi_start_explicit
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
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
' //  Read a single block.  The "n" passed in is the
' //  block number (blocks are 512 bytes); the b passed
' //  in is the address of 512 blocks to fill with the
' //  data.
' //
' int readblock(int n, char *b)
_readblock global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     starttime = getcnt();

        sub     sp, #4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##starttime

'     cmd(17, n);
        mov     r2, #17
        mov     r3, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_cmd
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     readresp();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_readresp
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     for (i = 0; i < 512; i++)
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0029
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##512
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0031
        jmp     #label0032
label0030
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'         *b++ = read();
        jmp     #label0029
label0031
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, r1
        mov     r4, r3
        add     r4, #1
        mov     r1, r4
        wrbyte  r2, r3

'     read();
        jmp     #label0030
label0032
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     read();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return endcmd();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_endcmd
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Read the CSD register.  Passed in is a 16-byte
' //  buffer.
' //
' int getCSD(char *b)
_getCSD  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     starttime = getcnt();

        sub     sp, #4
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##starttime

'     cmd(9, 0);
        mov     r1, #9
        mov     r2, #0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_cmd
        rdlong  r0, sp
        add     sp, #4

'     readresp();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_readresp
        rdlong  r0, sp
        add     sp, #4

'     for (i = 0; i < 16; i++)
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0033
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #16
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0035
        jmp     #label0036
label0034
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         *b++ = read();
        jmp     #label0033
label0035
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_read
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        wrbyte  r1, r2

'     read();
        jmp     #label0034
label0036
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_read
        rdlong  r0, sp
        add     sp, #4

'     read();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_read
        rdlong  r0, sp
        add     sp, #4

'     return endcmd();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_endcmd
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //  Write a single block.  Mirrors the read above.
' //
' int writeblock(int n, char *b)
_writeblock global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     starttime = getcnt();

        sub     sp, #4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getcnt
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##starttime

'     cmd(24, n);
        mov     r2, #24
        mov     r3, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_cmd
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     send(0xfe);
        mov     r2, #$fe
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     for (i = 0; i < 512; i++)
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0037
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##512
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0039
        jmp     #label0040
label0038
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'         send(*b++);
        jmp     #label0037
label0039
        mov     r2, r1
        mov     r3, r2
        add     r3, #1
        mov     r1, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_send
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     read();
        jmp     #label0038
label0040
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     read();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_read
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     if ((readresp() & 0x1f) != 5)
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_readresp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #$1f
        and     r2, r3
        mov     r3, #5
        sub     r2, r3  wz
 if_nz  mov     r2, #1

'         errorexit(-42);
        cmp     r2, #0  wz
 if_z   jmp     #label0041
        mov     r2, #42
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_errorexit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     busy();
label0041
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_busy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return endcmd();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_endcmd
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' // Permission is hereby granted, free of charge, to any person obtaining
' // a copy of this software and associated documentation files
' // (the "Software"), to deal in the Software without restriction,
' // including without limitation the rights to use, copy, modify, merge,
' // publish, distribute, sublicense, and/or sell copies of the Software,
' // and to permit persons to whom the Software is furnished to do so,
' // subject to the following conditions:
' //
' // The above copyright notice and this permission notice shall be included
' // in all copies or substantial portions of the Software.
' //
' // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
' // EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
' // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
' // IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
' // CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
' // TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
' // SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
' //
' EOF

CON
  main = 0
