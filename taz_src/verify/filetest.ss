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


' //############################################################################
' //# This program is used to test the basic functions of the SD file system.
' //# It implements simple versions of the cat, rm, ls, echo, cd, pwd, mkdir and
' //# rmdir commands plus the <, > and >> file redirection operators.
' //# The program starts up the file driver and then prompts for a command.
' //#
' //# Written by Dave Hein
' //# Copyright (c) 2011 Parallax, Inc.
' //# MIT Licensed
' //############################################################################
' 
' 
' 
' 
' 
' 
' int *stdin;
stdin long 0

' int *stdout;
stdout long 0

' int *stdinfile;
stdinfile long 0

' int *stdoutfile;
stdoutfile long 0

' 
' // Print help information
' void Help()
_Help    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("Commands are help, cat, rm, ls, ll, echo, cd, pwd, mkdir, run and exit\n");

        calld   lr, #label0002
        byte    "Commands are help, cat, rm, ls, ll, echo, cd, pwd, mkdir, run and exit", 10, 0
        alignl
label0002
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Run(int argc, char **argv)
_Run     global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int *infile;
'     char *ptr;
'     int filestat[2];
'     int *proctable;
'     int val, cognum;
'     int heap;
'     char save_cwd[80];
' 
'     proctable = 0x7ff80;

        sub     sp, #112
        mov     r2, ##$7ff80
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

' 
'     if (argc != 2)
        mov     r2, r0
        mov     r3, #2
        sub     r2, r3  wz
 if_nz  mov     r2, #1

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0003

'         printf("usage: run file\n");
        calld   lr, #label0005
        byte    "usage: run file", 10, 0
        alignl
label0005
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

'         return;
        add     sp, #112
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
' 
'     infile = fopen(argv[1], "r");
label0003
        mov     r2, r1
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0007
        byte    "r", 0
        alignl
label0007
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fopen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (!infile)
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0008

'         printf("Couldn't open %s\n", argv[1]);
        calld   lr, #label0010
        byte    "Couldn't open %s", 10, 0
        alignl
label0010
        mov     r2, lr
        mov     r3, r1
        mov     r4, #1
        shl     r4, #2
        add     r3, r4
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

'         return;
        add     sp, #112
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     fstat(infile, filestat);
label0008
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fstat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     for (heap = 450000; heap >= 50000; heap -= 50000)
        mov     r2, ##450000
        mov     r3, #28
        add     r3, sp
        wrlong  r2, r3
label0011
        mov     r2, #28
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##50000
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0013
        jmp     #label0014
label0012
        mov     r2, ##50000
        mov     r3, #28
        add     r3, sp
        rdlong  r4, r3
        sub     r4, r2
        wrlong  r4, r3

'     {
        jmp     #label0011
label0013

'         ptr = malloc(filestat[1] + heap);
        mov     r2, #8
        add     r2, sp
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #28
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_malloc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         if (ptr) break;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   jmp     #label0015
        jmp     #label0014

'     }
label0015

'     if (!ptr)
        jmp     #label0012
label0014
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0016

'         printf("Couldn't allocate memory\n");
        calld   lr, #label0018
        byte    "Couldn't allocate memory", 10, 0
        alignl
label0018
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

'         fclose(infile);
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         return;
        add     sp, #112
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     //printf("Allocated %d bytes of memory\n", filestat[1] + heap);
'     val = fread(ptr, 1, 1000000, infile);
label0016
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        mov     r4, ##1000000
        mov     r5, #0
        add     r5, sp
        rdlong  r5, r5
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        calld   lr, #_fread
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #20
        add     r3, sp
        wrlong  r2, r3

'     fclose(infile);
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     //printf("Read %d bytes from %s\n", val, argv[1]);
'     getcwd(save_cwd, 80);
        mov     r2, #32
        add     r2, sp
        mov     r3, #80
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_getcwd
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     sd_unmount();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_sd_unmount
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     dira = 0;
        mov     r2, #0
        mov     dira, r2

'     dirb = 0;
        mov     r2, #0
        mov     dirb, r2

'     waitx(5000000);
        mov     r2, ##5000000
        waitx   r2

'     cognum = CogInit(16, ptr, ptr + filestat[1] + heap);
        mov     r2, #16
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #8
        add     r5, sp
        mov     r6, #1
        shl     r6, #2
        add     r5, r6
        rdlong  r5, r5
        add     r4, r5
        mov     r5, #28
        add     r5, sp
        rdlong  r5, r5
        add     r4, r5
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_CogInit
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #24
        add     r3, sp
        wrlong  r2, r3

'     if (cognum & ~15)
        mov     r2, #24
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #15
        xor     r3, ##$ffffffff
        and     r2, r3

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0019

'         dirb &= ~0x40000000;
        mov     r2, ##$40000000
        xor     r2, ##$ffffffff
        mov     r4, dirb
        and     r2, r4
        mov     dirb, r2

'         //printf("CogInit returned %d\n", cognum);
'         free(ptr);
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_free
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         return;
        add     sp, #112
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     proctable[cognum] = 1;
label0019
        mov     r2, #1
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #24
        add     r4, sp
        rdlong  r4, r4
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'     //dirb &= ~0x40000000;
'     while (proctable[cognum])
label0020
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #24
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0021

'         if (!(inb & 0x80000000))
        mov     r2, inb
        mov     r3, ##$80000000
        and     r2, r3
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0022

'             val = getch();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_getch
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #20
        add     r3, sp
        wrlong  r2, r3

'             if (val == 3)
        mov     r2, #20
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0023

'                 CogStop(cognum);
        mov     r2, #24
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_CogStop
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 dirb |= 0x40000000;
        mov     r2, ##$40000000
        mov     r4, dirb
        or      r2, r4
        mov     dirb, r2

'                 printf("\n^C");
        calld   lr, #label0025
        byte    10, "^C", 0
        alignl
label0025
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

'                 break;
        jmp     #label0021

'             }
'         }
label0023

'     }
label0022

'     dirb |= 0x40000000;
        jmp     #label0020
label0021
        mov     r2, ##$40000000
        mov     r4, dirb
        or      r2, r4
        mov     dirb, r2

'     free(ptr);
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_free
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     //printf("CogInit returned %d\n", cognum);
'     sd_mount(0, 1, 2, 3);
        mov     r2, #0
        mov     r3, #1
        mov     r4, #2
        mov     r5, #3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        calld   lr, #_sd_mount
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     chdir(save_cwd);
        mov     r2, #32
        add     r2, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_chdir
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
        add     sp, #112
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void CogStop(int cognum)
_CogStop global
        sub     sp, #4
        wrlong  lr, sp

' {
'     inline("cogstop reg0");

cogstop reg0

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void CogInit(int cognum, int addr, int parm)
_CogInit global
        sub     sp, #4
        wrlong  lr, sp

' {
'     inline("setq reg2");

setq reg2

'     inline("coginit reg0, reg1 wc");
coginit reg0, reg1 wc

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Cd(int argc, char **argv)
_Cd      global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (argc < 2) return;

        mov     r2, r0
        mov     r3, #2
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0026
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     if (chdir(argv[1]))
label0026
        mov     r2, r1
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_chdir
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         perror(argv[1]);
        cmp     r2, #0  wz
 if_z   jmp     #label0027
        mov     r2, r1
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
label0027
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Pwd(int argc, char **argv)
_Pwd     global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char buffer[64];
'     char *ptr;
'     ptr = getcwd(buffer, 64);

        sub     sp, #68
        mov     r2, #0
        add     r2, sp
        mov     r3, #64
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_getcwd
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #64
        add     r3, sp
        wrlong  r2, r3

'     if (!ptr)
        mov     r2, #64
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         perror(0);
        cmp     r2, #0  wz
 if_z   jmp     #label0028
        mov     r2, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else
'         fprintf(stdoutfile, "%s\n", ptr);
        jmp     #label0029
label0028
        rdlong  r2, ##stdoutfile
        calld   lr, #label0031
        byte    "%s", 10, 0
        alignl
label0031
        mov     r3, lr
        mov     r4, #64
        add     r4, sp
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
label0029
        add     sp, #68
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Mkdir(int argc, char **argv)
_Mkdir   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     for (i = 1; i < argc; i++)

        sub     sp, #4
        mov     r2, #1
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0032
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0034
        jmp     #label0035
label0033
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0032
label0034

'         if (mkdir(argv[i], 0))
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_mkdir
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             perror(argv[i]);
        cmp     r2, #0  wz
 if_z   jmp     #label0036
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0036

' }
        jmp     #label0033
label0035
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Rmdir(int argc, char **argv)
_Rmdir   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     for (i = 1; i < argc; i++)

        sub     sp, #4
        mov     r2, #1
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0037
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
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

'     {
        jmp     #label0037
label0039

'         if (rmdir(argv[i]))
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_rmdir
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             perror(argv[i]);
        cmp     r2, #0  wz
 if_z   jmp     #label0041
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0041

' }
        jmp     #label0038
label0040
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine implements the file cat function
' void Cat(int argc, char **argv)
_Cat     global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int num;
'     void *infile;
'     char buffer[40];
' 
'     for (i = 0; i < argc; i++)

        sub     sp, #52
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0042
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0044
        jmp     #label0045
label0043
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0042
label0044

'         if (i == 0)
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0046

'             if (argc == 1 || stdinfile != stdin)
        mov     r2, r0
        mov     r3, #1
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        rdlong  r3, ##stdinfile
        rdlong  r4, ##stdin
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        or      r2, r3  wz
 if_nz  mov     r2, #1

'                 infile = stdinfile;
        cmp     r2, #0  wz
 if_z   jmp     #label0047
        rdlong  r2, ##stdinfile
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'             else
'                 continue;
        jmp     #label0048
label0047
        jmp     #label0043

'         }
label0048

'         else
'         {
        jmp     #label0049
label0046

'             infile = fopen(argv[i], "r");
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0051
        byte    "r", 0
        alignl
label0051
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fopen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'             if (infile == 0)
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0052

'                 perror(argv[i]);
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 continue;
        jmp     #label0043

'             }
'         }
label0052

'         if (infile == stdin)
label0049
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##stdin
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0053

'             while (gets(buffer))
label0054
        mov     r2, #12
        add     r2, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_gets
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0055

'                 if (buffer[0] == 4) break;
        mov     r2, #12
        add     r2, sp
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0056
        jmp     #label0055

'                 fprintf(stdoutfile, "%s\n", buffer);
label0056
        rdlong  r2, ##stdoutfile
        calld   lr, #label0058
        byte    "%s", 10, 0
        alignl
label0058
        mov     r3, lr
        mov     r4, #12
        add     r4, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             }
'         }
        jmp     #label0054
label0055

'         else
'         {
        jmp     #label0059
label0053

'             while ((num = fread(buffer, 1, 40, infile)))
label0060
        mov     r2, #12
        add     r2, sp
        mov     r3, #1
        mov     r4, #40
        mov     r5, #8
        add     r5, sp
        rdlong  r5, r5
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        calld   lr, #_fread
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'                 fwrite(buffer, 1, num, stdoutfile);
        cmp     r2, #0  wz
 if_z   jmp     #label0061
        mov     r2, #12
        add     r2, sp
        mov     r3, #1
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        rdlong  r5, ##stdoutfile
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        calld   lr, #_fwrite
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         }
        jmp     #label0060
label0061

'         if (i)
label0059
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2

'             fclose(infile);
        cmp     r2, #0  wz
 if_z   jmp     #label0062
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0062

'     fflush(stdout);
        jmp     #label0043
label0045
        rdlong  r2, ##stdout
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fflush
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
        add     sp, #52
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine deletes the files specified by the command line arguments
' void Remove(int argc, char **argv)
_Remove  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     for (i = 1; i < argc; i++)

        sub     sp, #4
        mov     r2, #1
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0063
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0065
        jmp     #label0066
label0064
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0063
label0065

'         if (remove(argv[i]))
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_remove
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             perror(argv[i]);
        cmp     r2, #0  wz
 if_z   jmp     #label0067
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0067

' }
        jmp     #label0064
label0066
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine echos the command line arguments
' void Echo(int argc, char **argv)
_Echo    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     for (i = 1; i < argc; i++)

        sub     sp, #4
        mov     r2, #1
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0068
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0070
        jmp     #label0071
label0069
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0068
label0070

'         if (i != argc - 1)
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #1
        sub     r3, r4
        sub     r2, r3  wz
 if_nz  mov     r2, #1

'             fprintf(stdoutfile, "%s ", argv[i]);
        cmp     r2, #0  wz
 if_z   jmp     #label0072
        rdlong  r2, ##stdoutfile
        calld   lr, #label0074
        byte    "%s ", 0
        alignl
label0074
        mov     r3, lr
        mov     r4, r1
        mov     r5, #0
        add     r5, sp
        rdlong  r5, r5
        shl     r5, #2
        add     r4, r5
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else
'             fprintf(stdoutfile, "%s\n", argv[i]);
        jmp     #label0075
label0072
        rdlong  r2, ##stdoutfile
        calld   lr, #label0077
        byte    "%s", 10, 0
        alignl
label0077
        mov     r3, lr
        mov     r4, r1
        mov     r5, #0
        add     r5, sp
        rdlong  r5, r5
        shl     r5, #2
        add     r4, r5
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0075

' }
        jmp     #label0069
label0071
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine lists the root directory or any subdirectories specified
' // in the command line arguments.  If the "-l" option is specified, it
' // will print the file attributes and size.  Otherwise, it will just
' // print the file names.
' void List(int argc, char **argv)
_List    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, j;
'     char *ptr;
'     char fname[13];
'     int count;
'     unsigned int filesize;
'     unsigned int longflag;
'     char *path;
'     char drwx[5];
'     int column;
'     int prevlen;
'     int *dirp;
'     int *entry;
'     int filestat[2];
'     int attribute;
' 
'     count = 0;

        sub     sp, #80
        mov     r2, #0
        mov     r3, #28
        add     r3, sp
        wrlong  r2, r3

'     longflag = 0;
        mov     r2, #0
        mov     r3, #36
        add     r3, sp
        wrlong  r2, r3

' 
'     // Check flags
'     for (j = 1; j < argc; j++)
        mov     r2, #1
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3
label0078
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0080
        jmp     #label0081
label0079
        mov     r4, #4
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0078
label0080

'         if (*(argv[j]) == '-')
        mov     r2, r1
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #45
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        rdbyte  r2, r2

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0082

'             if (!strcmp(argv[j], "-l"))
        mov     r2, r1
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0085
        byte    "-l", 0
        alignl
label0085
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'                 longflag = 1;
        cmp     r2, #0  wz
 if_z   jmp     #label0083
        mov     r2, #1
        mov     r3, #36
        add     r3, sp
        wrlong  r2, r3

'             else
'                 printf("Unknown option '%s'\n", argv[j]);
        jmp     #label0086
label0083
        calld   lr, #label0088
        byte    "Unknown option '%s'", 10, 0
        alignl
label0088
        mov     r2, lr
        mov     r3, r1
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        shl     r4, #2
        add     r3, r4
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

'         }
label0086

'         else
'             count++;
        jmp     #label0089
label0082
        mov     r4, #28
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     }
label0089

' 
'     // List directories
'     for (j = 1; j < argc || count == 0; j++)
        jmp     #label0079
label0081
        mov     r2, #1
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3
label0090
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, #28
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        or      r2, r3  wz
 if_nz  mov     r2, #1
        cmp     r2, #0  wz
 if_nz  jmp     #label0092
        jmp     #label0093
label0091
        mov     r4, #4
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0090
label0092

'         if (count == 0)
        mov     r2, #28
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0094

'             count--;
        mov     r4, #28
        add     r4, sp
        rdlong  r2, r4
        sub     r2, #1
        wrlong  r2, r4

'             path = "./";
        calld   lr, #label0096
        byte    "./", 0
        alignl
label0096
        mov     r2, lr
        mov     r3, #40
        add     r3, sp
        wrlong  r2, r3

'         }
'         else if (*(argv[j]) == '-')
        jmp     #label0097
label0094
        mov     r2, r1
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #45
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        rdbyte  r2, r2

'             continue;
        cmp     r2, #0  wz
 if_z   jmp     #label0098
        jmp     #label0091

'         else
'             path = argv[j];
        jmp     #label0099
label0098
        mov     r2, r1
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #40
        add     r3, sp
        wrlong  r2, r3

' 
'         if (count >= 2)
label0099
label0097
        mov     r2, #28
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #2
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'             fprintf(stdoutfile, "\n%s:\n", path);
        cmp     r2, #0  wz
 if_z   jmp     #label0100
        rdlong  r2, ##stdoutfile
        calld   lr, #label0102
        byte    10, "%s:", 10, 0
        alignl
label0102
        mov     r3, lr
        mov     r4, #40
        add     r4, sp
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' 
'         dirp = opendir(path);
label0100
        mov     r2, #40
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_opendir
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #60
        add     r3, sp
        wrlong  r2, r3

' 
'         if (!dirp)
        mov     r2, #60
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0103

'             perror(path);
        mov     r2, #40
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             continue;
        jmp     #label0091

'         }
' 
'         column = 0;
label0103
        mov     r2, #0
        mov     r3, #52
        add     r3, sp
        wrlong  r2, r3

'         prevlen = 14;
        mov     r2, #14
        mov     r3, #56
        add     r3, sp
        wrlong  r2, r3

'         while (entry = readdir(dirp))
label0104
        mov     r2, #60
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readdir
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #64
        add     r3, sp
        wrlong  r2, r3

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0105

'             ptr = entry;
        mov     r2, #64
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'             for (i = 0; i < 13; i++)
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0106
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #13
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0108
        jmp     #label0109
label0107
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'             {
        jmp     #label0106
label0108

'                 fname[i] = tolower(*ptr);
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_tolower
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #12
        add     r3, sp
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        add     r3, r4
        wrbyte  r2, r3

'                 if (*ptr++ = 0) break;
        mov     r2, #0
        mov     r5, #8
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #1
        wrlong  r4, r5
        wrbyte  r2, r3
        cmp     r2, #0  wz
 if_z   jmp     #label0110
        jmp     #label0109

'             }
label0110

'             if (longflag)
        jmp     #label0107
label0109
        mov     r2, #36
        add     r2, sp
        rdlong  r2, r2

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0111

'                 stat(fname, filestat);
        mov     r2, #12
        add     r2, sp
        mov     r3, #68
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_stat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 filesize = filestat[1];
        mov     r2, #68
        add     r2, sp
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #32
        add     r3, sp
        wrlong  r2, r3

'                 attribute = filestat[0];
        mov     r2, #68
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #76
        add     r3, sp
        wrlong  r2, r3

'                 strcpy(drwx, "-rw-");
        mov     r2, #44
        add     r2, sp
        calld   lr, #label0113
        byte    "-rw-", 0
        alignl
label0113
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcpy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 if (attribute & 1)
        mov     r2, #76
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        and     r2, r3

'                     drwx[2] = '-';
        cmp     r2, #0  wz
 if_z   jmp     #label0114
        mov     r2, #45
        mov     r3, #44
        add     r3, sp
        mov     r4, #2
        add     r3, r4
        wrbyte  r2, r3

'                 if (attribute & 0x20)
label0114
        mov     r2, #76
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$20
        and     r2, r3

'                     drwx[3] = 'x';
        cmp     r2, #0  wz
 if_z   jmp     #label0115
        mov     r2, #120
        mov     r3, #44
        add     r3, sp
        mov     r4, #3
        add     r3, r4
        wrbyte  r2, r3

'                 if (attribute & 0x10)
label0115
        mov     r2, #76
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$10
        and     r2, r3

'                 {
        cmp     r2, #0  wz
 if_z   jmp     #label0116

'                     drwx[0] = 'd';
        mov     r2, #100
        mov     r3, #44
        add     r3, sp
        mov     r4, #0
        add     r3, r4
        wrbyte  r2, r3

'                     drwx[3] = 'x';
        mov     r2, #120
        mov     r3, #44
        add     r3, sp
        mov     r4, #3
        add     r3, r4
        wrbyte  r2, r3

'                 }
'                 fprintf(stdoutfile, "%s %8d %s\n", drwx, filesize, fname);
label0116
        rdlong  r2, ##stdoutfile
        calld   lr, #label0118
        byte    "%s %8d %s", 10, 0
        alignl
label0118
        mov     r3, lr
        mov     r4, #44
        add     r4, sp
        mov     r5, #32
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #12
        add     r6, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        mov     r4, r6
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             }
'             else if (++column == 5)
        jmp     #label0119
label0111
        mov     r4, #52
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4
        mov     r3, #5
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0120

'                 for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
        mov     r2, #56
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0121
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #14
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0123
        jmp     #label0124
label0122
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4
        jmp     #label0121
label0123
        rdlong  r2, ##stdoutfile
        calld   lr, #label0126
        byte    " ", 0
        alignl
label0126
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 fprintf(stdoutfile, "%s\n", fname);
        jmp     #label0122
label0124
        rdlong  r2, ##stdoutfile
        calld   lr, #label0128
        byte    "%s", 10, 0
        alignl
label0128
        mov     r3, lr
        mov     r4, #12
        add     r4, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 column = 0;
        mov     r2, #0
        mov     r3, #52
        add     r3, sp
        wrlong  r2, r3

'                 prevlen = 14;
        mov     r2, #14
        mov     r3, #56
        add     r3, sp
        wrlong  r2, r3

'             }
'             else
'             {
        jmp     #label0129
label0120

'                 for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
        mov     r2, #56
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0130
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #14
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0132
        jmp     #label0133
label0131
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4
        jmp     #label0130
label0132
        rdlong  r2, ##stdoutfile
        calld   lr, #label0135
        byte    " ", 0
        alignl
label0135
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 prevlen = strlen(fname);
        jmp     #label0131
label0133
        mov     r2, #12
        add     r2, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_strlen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #56
        add     r3, sp
        wrlong  r2, r3

'                 fprintf(stdoutfile, "%s", fname);
        rdlong  r2, ##stdoutfile
        calld   lr, #label0137
        byte    "%s", 0
        alignl
label0137
        mov     r3, lr
        mov     r4, #12
        add     r4, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             }
'         }
label0129
label0119

'         closedir(dirp);
        jmp     #label0104
label0105
        mov     r2, #60
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_closedir
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         if (!longflag && column)
        mov     r2, #36
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        mov     r3, #52
        add     r3, sp
        rdlong  r3, r3
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'             fprintf(stdoutfile, "\n");
        cmp     r2, #0  wz
 if_z   jmp     #label0138
        rdlong  r2, ##stdoutfile
        calld   lr, #label0140
        byte    10, 0
        alignl
label0140
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fprintf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
label0138

' }
        jmp     #label0091
label0093
        add     sp, #80
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine returns a pointer to the first character that doesn't
' // match val.
' char *SkipChar(char *ptr, int val)
_SkipChar global
        sub     sp, #4
        wrlong  lr, sp

' {
'     while (*ptr)

label0141
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0142

'         if (*ptr != val) break;
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, r1
        sub     r2, r3  wz
 if_nz  mov     r2, #1
        cmp     r2, #0  wz
 if_z   jmp     #label0143
        jmp     #label0142

'         ptr++;
label0143
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     }
'     return ptr;
        jmp     #label0141
label0142
        mov     r2, r0
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine returns a pointer to the first character that matches val.
' char *FindChar(char *ptr, int val)
_FindChar global
        sub     sp, #4
        wrlong  lr, sp

' {
'     while (*ptr)

label0144
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0145

'         if (*ptr == val) break;
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, r1
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0146
        jmp     #label0145

'         ptr++;
label0146
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     }
'     return ptr;
        jmp     #label0144
label0145
        mov     r2, r0
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine extracts tokens from a string that are separated by one or
' // more spaces.  It returns the number of tokens found.
' int tokenize(char *ptr, char **tokens)
_tokenize global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int num;
'     num = 0;

        sub     sp, #4
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

' 
'     while (*ptr)
label0147
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0148

'         ptr = SkipChar(ptr, ' ');
        mov     r2, r0
        mov     r3, #32
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_SkipChar
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2

'         if (*ptr == 0) break;
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0149
        jmp     #label0148

'         if (ptr[0] == '>')
label0149
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #62
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0150

'             ptr++;
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'             if (ptr[0] == '>')
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #62
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0151

'                 tokens[num++] = ">>";
        calld   lr, #label0153
        byte    ">>", 0
        alignl
label0153
        mov     r2, lr
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'                 ptr++;
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'             }
'             else
'                 tokens[num++] = ">";
        jmp     #label0154
label0151
        calld   lr, #label0156
        byte    ">", 0
        alignl
label0156
        mov     r2, lr
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'             continue;
label0154
        jmp     #label0147

'         }
'         if (ptr[0] == '<')
label0150
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #60
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0157

'             ptr++;
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'             tokens[num++] = "<";
        calld   lr, #label0159
        byte    "<", 0
        alignl
label0159
        mov     r2, lr
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'             continue;
        jmp     #label0147

'         }
'         tokens[num++] = ptr;
label0157
        mov     r2, r0
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'         ptr = FindChar(ptr, ' ');
        mov     r2, r0
        mov     r3, #32
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_FindChar
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2

'         if (*ptr) *ptr++ = 0;
        mov     r2, r0
        rdbyte  r2, r2
        cmp     r2, #0  wz
 if_z   jmp     #label0160
        mov     r2, #0
        mov     r3, r0
        mov     r4, r3
        add     r4, #1
        mov     r0, r4
        wrbyte  r2, r3

'     }
label0160

'     return num;
        jmp     #label0147
label0148
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
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
' // This routine searches the list of tokens for the redirection operators
' // and opens the files for input, output or append depending on the 
' // operator.
' int CheckRedirection(char **tokens, int num)
_CheckRedirection global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, j;
' 
'     for (i = 0; i < num-1; i++)

        sub     sp, #8
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3
label0161
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        mov     r4, #1
        sub     r3, r4
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0163
        jmp     #label0164
label0162
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'     {
        jmp     #label0161
label0163

'         if (!strcmp(tokens[i], ">"))
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0167
        byte    ">", 0
        alignl
label0167
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0165

'             stdoutfile = fopen(tokens[i+1], "w");
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0169
        byte    "w", 0
        alignl
label0169
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fopen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##stdoutfile

'             if (!stdoutfile)
        rdlong  r2, ##stdoutfile
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0170

'                 perror(tokens[i+1]);
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 stdoutfile = stdout;
        rdlong  r2, ##stdout
        wrlong  r2, ##stdoutfile

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0170

'         else if (!strcmp(tokens[i], ">>"))
        jmp     #label0171
label0165
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0174
        byte    ">>", 0
        alignl
label0174
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0172

'             stdoutfile = fopen(tokens[i+1], "a");
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0176
        byte    "a", 0
        alignl
label0176
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fopen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##stdoutfile

'             if (!stdoutfile)
        rdlong  r2, ##stdoutfile
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0177

'                 perror(tokens[i+1]);
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 stdoutfile = stdout;
        rdlong  r2, ##stdout
        wrlong  r2, ##stdoutfile

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0177

'         else if (!strcmp(tokens[i], "<"))
        jmp     #label0178
label0172
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0181
        byte    "<", 0
        alignl
label0181
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0179

'             stdinfile = fopen(tokens[i+1], "r");
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0183
        byte    "r", 0
        alignl
label0183
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_fopen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##stdinfile

'             if (!stdinfile)
        rdlong  r2, ##stdinfile
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0184

'                 perror(tokens[i+1]);
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_perror
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 stdinfile = stdin;
        rdlong  r2, ##stdin
        wrlong  r2, ##stdinfile

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0184

'         else
'             continue;
        jmp     #label0185
label0179
        jmp     #label0162

'         for (j = i + 2; j < num; j++) tokens[j-2] = tokens[j];
label0185
label0178
label0171
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #2
        add     r2, r3
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3
label0186
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0188
        jmp     #label0189
label0187
        mov     r4, #4
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4
        jmp     #label0186
label0188
        mov     r2, r0
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #2
        sub     r4, r5
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'         i--;
        jmp     #label0187
label0189
        mov     r4, #0
        add     r4, sp
        rdlong  r2, r4
        sub     r2, #1
        wrlong  r2, r4

'         num -= 2;
        mov     r2, #2
        mov     r4, r1
        sub     r4, r2
        mov     r1, r4

'     }
'     return num;
        jmp     #label0162
label0164
        mov     r2, r1
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
' // This routine closes files that were open for redirection
' void CloseRedirection()
_CloseRedirection global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (stdinfile != stdin)

        rdlong  r0, ##stdinfile
        rdlong  r1, ##stdin
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0190

'         fclose(stdinfile);
        rdlong  r0, ##stdinfile
        calld   lr, #_fclose

'         stdinfile = stdin;
        rdlong  r0, ##stdin
        wrlong  r0, ##stdinfile

'     }
'     if (stdoutfile != stdout)
label0190
        rdlong  r0, ##stdoutfile
        rdlong  r1, ##stdout
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0191

'         fclose(stdoutfile);
        rdlong  r0, ##stdoutfile
        calld   lr, #_fclose

'         stdoutfile = stdout;
        rdlong  r0, ##stdout
        wrlong  r0, ##stdoutfile

'     }
' }
label0191
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getdec(char *ptr)
_getdec  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int val;
'     val = 0;

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     while (*ptr) val = (val * 10) + *ptr++ - '0';
label0192
        mov     r1, r0
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0193
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #10
        qmul    r1, r2
        getqx   r1
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        rdbyte  r2, r2
        add     r1, r2
        mov     r2, #48
        sub     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     return val;
        jmp     #label0192
label0193
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
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
' // The program starts the file system.  It then loops reading commands
' // and calling the appropriate routine to process it.
' int main(int argc, char **argv)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int num;
'     char *tokens[20];
'     char buffer[80];
' 
'     sd_mount(0, 1, 2, 3);

        sub     sp, #168
        mov     r2, #0
        mov     r3, #1
        mov     r4, #2
        mov     r5, #3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        mov     r3, r5
        calld   lr, #_sd_mount
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' 
'     stdinfile = stdin;
        rdlong  r2, ##stdin
        wrlong  r2, ##stdinfile

'     stdoutfile = stdout;
        rdlong  r2, ##stdout
        wrlong  r2, ##stdoutfile

' 
'     printf("\n");
        calld   lr, #label0195
        byte    10, 0
        alignl
label0195
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

'     Help();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_Help
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' 
'     while (1)
label0196
        mov     r2, #1

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0197

'         printf("\n> ");
        calld   lr, #label0199
        byte    10, "> ", 0
        alignl
label0199
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

'         fflush(stdout);
        rdlong  r2, ##stdout
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_fflush
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         gets(buffer);
        mov     r2, #88
        add     r2, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_gets
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         num = tokenize(buffer, tokens);
        mov     r2, #88
        add     r2, sp
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_tokenize
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         num = CheckRedirection(tokens, num);
        mov     r2, #8
        add     r2, sp
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_CheckRedirection
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         if (num == 0) continue;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0200
        jmp     #label0196

'         if (!strcmp(tokens[0], "help"))
label0200
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0203
        byte    "help", 0
        alignl
label0203
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Help();
        cmp     r2, #0  wz
 if_z   jmp     #label0201
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_Help
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "cat"))
        jmp     #label0204
label0201
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0207
        byte    "cat", 0
        alignl
label0207
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Cat(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0205
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Cat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "ls"))
        jmp     #label0208
label0205
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0211
        byte    "ls", 0
        alignl
label0211
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             List(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0209
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_List
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "ll"))
        jmp     #label0212
label0209
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0215
        byte    "ll", 0
        alignl
label0215
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0213

'             tokens[num++] = "-l";
        calld   lr, #label0217
        byte    "-l", 0
        alignl
label0217
        mov     r2, lr
        mov     r3, #8
        add     r3, sp
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'             List(num, tokens);
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_List
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         }
'         else if (!strcmp(tokens[0], "rm"))
        jmp     #label0218
label0213
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0221
        byte    "rm", 0
        alignl
label0221
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Remove(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0219
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Remove
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "echo"))
        jmp     #label0222
label0219
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0225
        byte    "echo", 0
        alignl
label0225
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Echo(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0223
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Echo
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "cd"))
        jmp     #label0226
label0223
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0229
        byte    "cd", 0
        alignl
label0229
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Cd(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0227
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Cd
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "pwd"))
        jmp     #label0230
label0227
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0233
        byte    "pwd", 0
        alignl
label0233
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Pwd(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0231
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Pwd
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "mkdir"))
        jmp     #label0234
label0231
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0237
        byte    "mkdir", 0
        alignl
label0237
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Mkdir(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0235
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Mkdir
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "rmdir"))
        jmp     #label0238
label0235
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0241
        byte    "rmdir", 0
        alignl
label0241
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Rmdir(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0239
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Rmdir
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "exit"))
        jmp     #label0242
label0239
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0245
        byte    "exit", 0
        alignl
label0245
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             exit(0);
        cmp     r2, #0  wz
 if_z   jmp     #label0243
        mov     r2, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_exit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else if (!strcmp(tokens[0], "run"))
        jmp     #label0246
label0243
        mov     r2, #8
        add     r2, sp
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        calld   lr, #label0249
        byte    "run", 0
        alignl
label0249
        mov     r3, lr
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_strcmp
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             Run(num, tokens);
        cmp     r2, #0  wz
 if_z   jmp     #label0247
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_Run
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         else
'         {
        jmp     #label0250
label0247

'             printf("Invalid command\n");
        calld   lr, #label0252
        byte    "Invalid command", 10, 0
        alignl
label0252
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

'             Help();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_Help
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         }
'         CloseRedirection();
label0250
label0246
label0242
label0238
label0234
label0230
label0226
label0222
label0218
label0212
label0208
label0204
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_CloseRedirection
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
' }
        jmp     #label0196
label0197
        add     sp, #168
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' //+--------------------------------------------------------------------
' //|  TERMS OF USE: MIT License
' //+--------------------------------------------------------------------
' //Permission is hereby granted, free of charge, to any person obtaining
' //a copy of this software and associated documentation files
' //(the "Software"), to deal in the Software without restriction,
' //including without limitation the rights to use, copy, modify, merge,
' //publish, distribute, sublicense, and/or sell copies of the Software,
' //and to permit persons to whom the Software is furnished to do so,
' //subject to the following conditions:
' //
' //The above copyright notice and this permission notice shall be
' //included in all copies or substantial portions of the Software.
' //
' //THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
' //EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
' //MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
' //IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
' //CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
' //TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
' //SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
' //+------------------------------------------------------------------
' 
' EOF
