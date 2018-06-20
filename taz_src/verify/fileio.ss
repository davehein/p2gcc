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


' int errno;
errno long 0

' int *stdin;
stdin long 0

' int *stdout;
stdout long 0

' int *stderr;
stderr long 0

' char dirbuf[16];
dirbuf byte 0[16]

' int filelist[10] = {1, 1, 1, 0, 0, 0, 0, 0, 0, 0};
        alignl
filelist long 1, 1, 1, 0, 0, 0, 0, 0, 0, 0

' char currentwd[100];
currentwd byte 0[100]

' 
' void sd_mount(int DO, int CLK, int DI, int CS)
        alignl
_sd_mount global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     filelist[0] = 0x100000;

        sub     sp, #4
        mov     r4, ##$100000
        mov     r5, ##filelist
        mov     r6, #0
        shl     r6, #2
        add     r5, r6
        wrlong  r4, r5

'     filelist[1] = 0x100000;
        mov     r4, ##$100000
        mov     r5, ##filelist
        mov     r6, #1
        shl     r6, #2
        add     r5, r6
        wrlong  r4, r5

'     filelist[2] = 0x100000;
        mov     r4, ##$100000
        mov     r5, ##filelist
        mov     r6, #2
        shl     r6, #2
        add     r5, r6
        wrlong  r4, r5

'     memset(&filelist[3], 0, 28);
        mov     r4, ##filelist
        mov     r5, #3
        shl     r5, #2
        add     r4, r5
        mov     r5, #0
        mov     r6, #28
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        calld   lr, #_memset
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     stdin = &filelist[0];
        mov     r4, ##filelist
        mov     r5, #0
        shl     r5, #2
        add     r4, r5
        wrlong  r4, ##stdin

'     stdout = &filelist[1];
        mov     r4, ##filelist
        mov     r5, #1
        shl     r5, #2
        add     r4, r5
        wrlong  r4, ##stdout

'     stderr = &filelist[2];
        mov     r4, ##filelist
        mov     r5, #2
        shl     r5, #2
        add     r4, r5
        wrlong  r4, ##stderr

'     strcpy(currentwd, "/");
        mov     r4, ##currentwd
        calld   lr, #label0002
        byte    "/", 0
        alignl
label0002
        mov     r5, lr
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_strcpy
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     mount_explicit(DO, CLK, DI, CS);
        mov     r4, r0
        mov     r5, r1
        mov     r6, r2
        mov     r7, r3
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        mov     r2, r6
        mov     r3, r7
        calld   lr, #_mount_explicit
        setq    #3
        rdlong  r0, sp
        add     sp, #16

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void sd_unmount(void)
_sd_unmount global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unmount();

        calld   lr, #_unmount

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int *allocfile(int size)
_allocfile global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     for (i = 0; i < 10; i++)

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0003
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #10
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

'         if (!filelist[i]) break;
        mov     r1, ##filelist
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0007
        jmp     #label0006

'     }
label0007

'     if (i == 10) return 0;
        jmp     #label0004
label0006
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #10
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0008
        mov     r1, #0
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     filelist[i] = malloc(size);
label0008
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_malloc
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, ##filelist
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     if (filelist[i]) return &filelist[i];
        mov     r1, ##filelist
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0009
        mov     r1, ##filelist
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return 0;
label0009
        mov     r1, #0
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
' void freefile(int *fd)
_freefile global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (fd && *fd)

        mov     r1, r0
        mov     r2, r0
        rdlong  r2, r2
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0010

'         if (!(*fd & 0xfff00000)) free(*fd);
        mov     r1, r0
        rdlong  r1, r1
        mov     r2, ##$fff00000
        and     r1, r2
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0011
        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_free
        rdlong  r0, sp
        add     sp, #4

'         *fd = 0;
label0011
        mov     r1, #0
        mov     r2, r0
        wrlong  r1, r2

'     }
' }
label0010
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' char *fopen(char *fname, char *mode)
_fopen   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int err;
'     int *fd;
'     int *handle;
'     if (*mode != 'r' && *mode != 'w' && *mode != 'a') return 0;

        sub     sp, #16
        mov     r2, r1
        rdbyte  r2, r2
        mov     r3, #114
        sub     r2, r3  wz
 if_nz  mov     r2, #1
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #119
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0
        mov     r3, r1
        rdbyte  r3, r3
        mov     r4, #97
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0012
        mov     r2, #0
        mov     r0, r2
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     fd = allocfile(44 + 512);
label0012
        mov     r2, #44
        mov     r3, ##512
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_allocfile
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'     if (!fd) return 0;
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0013
        mov     r2, #0
        mov     r0, r2
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     handle = *fd;
label0013
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        rdlong  r2, r2
        mov     r3, #12
        add     r3, sp
        wrlong  r2, r3

'     memset(handle, 0, 40);
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        mov     r4, #40
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_memset
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     handle[10] = &handle[11];
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        shl     r3, #2
        add     r2, r3
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #10
        shl     r4, #2
        add     r3, r4
        wrlong  r2, r3

'     loadhandle(handle);
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     err = popen(fname, *mode);
        mov     r2, r0
        mov     r3, r1
        rdbyte  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_popen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     if (err)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0014

'         //printf("popen returned %d\n", err);
'         loadhandle0();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_loadhandle0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         freefile(fd);
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_freefile
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     return fd;
label0014
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2
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
' int fclose(int *fd)
_fclose  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!fd) return -1;

        mov     r1, r0
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0015
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     loadhandle(*fd);
label0015
        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     pclose();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pclose
        rdlong  r0, sp
        add     sp, #4

'     loadhandle0();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_loadhandle0
        rdlong  r0, sp
        add     sp, #4

'     freefile(fd);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_freefile
        rdlong  r0, sp
        add     sp, #4

'     return 0;
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int fread(char *ptr, int size, int num, int *fd)
_fread   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     size *= num;

        mov     r4, r2
        mov     r6, r1
        qmul    r4, r6
        getqx   r4
        mov     r1, r4

'     if (*fd & 0xfff00000)
        mov     r4, r3
        rdlong  r4, r4
        mov     r5, ##$fff00000
        and     r4, r5

'     {
        cmp     r4, #0  wz
 if_z   jmp     #label0016

'         num = size;
        mov     r4, r1
        mov     r2, r4

'         while (size--) *ptr++ = getchar();
label0017
        mov     r4, r1
        mov     r5, r4
        sub     r5, #1
        mov     r1, r5
        cmp     r4, #0  wz
 if_z   jmp     #label0018
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_getchar
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, r0
        mov     r6, r5
        add     r6, #1
        mov     r0, r6
        wrbyte  r4, r5

'     }
        jmp     #label0017
label0018

'     else
'     {
        jmp     #label0019
label0016

'         loadhandle(*fd);
        mov     r4, r3
        rdlong  r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_loadhandle
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'         num = pread(ptr, size);
        mov     r4, r0
        mov     r5, r1
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_pread
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r2, r4

'     }
'     if (num < 0) num = 0;
label0019
        mov     r4, r2
        mov     r5, #0
        cmps    r4, r5  wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        cmp     r4, #0  wz
 if_z   jmp     #label0020
        mov     r4, #0
        mov     r2, r4

'     return num;
label0020
        mov     r4, r2
        mov     r0, r4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int fwrite(char *ptr, int size, int num, int *fd)
_fwrite  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     size *= num;

        mov     r4, r2
        mov     r6, r1
        qmul    r4, r6
        getqx   r4
        mov     r1, r4

'     if (*fd & 0xfff00000)
        mov     r4, r3
        rdlong  r4, r4
        mov     r5, ##$fff00000
        and     r4, r5

'     {
        cmp     r4, #0  wz
 if_z   jmp     #label0021

'         while (size--) putchar(*ptr++);
label0022
        mov     r4, r1
        mov     r5, r4
        sub     r5, #1
        mov     r1, r5
        cmp     r4, #0  wz
 if_z   jmp     #label0023
        mov     r4, r0
        mov     r5, r4
        add     r5, #1
        mov     r0, r5
        rdbyte  r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_putchar
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     }
        jmp     #label0022
label0023

'     else
'     {
        jmp     #label0024
label0021

'         loadhandle(*fd);
        mov     r4, r3
        rdlong  r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_loadhandle
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'         pwrite(ptr, size);
        mov     r4, r0
        mov     r5, r1
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_pwrite
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     }
' }
label0024
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int remove(char *fname)
_remove  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     loadhandle0();

        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_loadhandle0
        rdlong  r0, sp
        add     sp, #4

'     popen(fname, 'd');
        mov     r1, r0
        mov     r2, #100
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_popen
        rdlong  r0, sp
        add     sp, #4

'     return 0;
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int fgetc(int *fd)
_fgetc   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int val;
'     if (*fd & 0xfff00000) return getchar();

        sub     sp, #4
        mov     r1, r0
        rdlong  r1, r1
        mov     r2, ##$fff00000
        and     r1, r2
        cmp     r1, #0  wz
 if_z   jmp     #label0025
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_getchar
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     loadhandle(*fd);
label0025
        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     val = pgetc();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pgetc
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     return val;
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
' void fputc(int val, int *fd)
_fputc   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (*fd & 0xfff00000)

        mov     r2, r1
        rdlong  r2, r2
        mov     r3, ##$fff00000
        and     r2, r3

'         putchar(val);
        cmp     r2, #0  wz
 if_z   jmp     #label0026
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_putchar
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else
'     {
        jmp     #label0027
label0026

'         loadhandle(*fd);
        mov     r2, r1
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         pputc(val);
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_pputc
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
' }
label0027
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int chdir(char *path)
_chdir   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!pchdir(path))

        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_pchdir
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0028

'         if (*path == '/')
        mov     r1, r0
        rdbyte  r1, r1
        mov     r2, #47
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             strcpy(currentwd, path);
        cmp     r1, #0  wz
 if_z   jmp     #label0029
        mov     r1, ##currentwd
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_strcpy
        rdlong  r0, sp
        add     sp, #4

'         else
'         {
        jmp     #label0030
label0029

'             if (strcmp(currentwd, "/"))
        mov     r1, ##currentwd
        calld   lr, #label0033
        byte    "/", 0
        alignl
label0033
        mov     r2, lr
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_strcmp
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'                 strcat(currentwd, "/");
        cmp     r1, #0  wz
 if_z   jmp     #label0031
        mov     r1, ##currentwd
        calld   lr, #label0035
        byte    "/", 0
        alignl
label0035
        mov     r2, lr
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_strcat
        rdlong  r0, sp
        add     sp, #4

'             strcat(currentwd, path);
label0031
        mov     r1, ##currentwd
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_strcat
        rdlong  r0, sp
        add     sp, #4

'         }
'         return 0;
label0030
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     if (pchdir(currentwd)) strcpy(currentwd, "/");
label0028
        mov     r1, ##currentwd
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_pchdir
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0036
        mov     r1, ##currentwd
        calld   lr, #label0038
        byte    "/", 0
        alignl
label0038
        mov     r2, lr
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_strcpy
        rdlong  r0, sp
        add     sp, #4

'     return -1;
label0036
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void perror(char *str)
_perror  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (str) printf("%s: ", str);

        mov     r1, r0
        cmp     r1, #0  wz
 if_z   jmp     #label0039
        calld   lr, #label0041
        byte    "%s: ", 0
        alignl
label0041
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

'     printf("error %d\n", errno);
label0039
        calld   lr, #label0043
        byte    "error %d", 10, 0
        alignl
label0043
        mov     r1, lr
        rdlong  r2, ##errno
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

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' char *getcwd(char *ptr, int size)
_getcwd  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     strncpy(ptr, currentwd, size);

        mov     r2, r0
        mov     r3, ##currentwd
        mov     r4, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_strncpy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return ptr;
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
' void fputs(char *str, int *fd)
_fputs   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (*fd & 0xfff00000)

        mov     r2, r1
        rdlong  r2, r2
        mov     r3, ##$fff00000
        and     r2, r3

'         puts(str);
        cmp     r2, #0  wz
 if_z   jmp     #label0044
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_puts
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else
'     {
        jmp     #label0045
label0044

'         loadhandle(*fd);
        mov     r2, r1
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         pputs(str);
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_pputs
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
' }
label0045
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void fprintf(int *fd, char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10)
_fprintf global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, index;
'     int arglist[10];
'     char outstr[200];
' 
'     va_start(index, fmt);

        sub     sp, #248
        mov     r12, #1
        mov     r13, #4
        add     r13, sp
        wrlong  r12, r13

'     for (i = 0; i < 10; i++)
        mov     r12, #0
        mov     r13, #0
        add     r13, sp
        wrlong  r12, r13
label0046
        mov     r12, #0
        add     r12, sp
        rdlong  r12, r12
        mov     r13, #10
        cmps    r12, r13  wc
 if_c   mov     r12, #1
 if_nc  mov     r12, #0
        cmp     r12, #0  wz
 if_nz  jmp     #label0048
        jmp     #label0049
label0047
        mov     r14, #0
        add     r14, sp
        rdlong  r12, r14
        add     r12, #1
        wrlong  r12, r14

'         arglist[i] = va_arg(index, int);
        jmp     #label0046
label0048
        mov     r14, #4
        add     r14, sp
        rdlong  r12, r14
        add     r12, #1
        wrlong  r12, r14
        alts    r12, #r0
        mov     r12, 0-0
        mov     r13, #8
        add     r13, sp
        mov     r14, #0
        add     r14, sp
        rdlong  r14, r14
        shl     r14, #2
        add     r13, r14
        wrlong  r12, r13

'     va_end(index);
        jmp     #label0047
label0049


'     vsprintf(outstr, fmt, arglist);
        mov     r12, #48
        add     r12, sp
        mov     r13, r1
        mov     r14, #8
        add     r14, sp
        sub     sp, #48
        setq    #11
        wrlong  r0, sp
        mov     r0, r12
        mov     r1, r13
        mov     r2, r14
        calld   lr, #_vsprintf
        setq    #11
        rdlong  r0, sp
        add     sp, #48

'     fputs(outstr, fd);
        mov     r12, #48
        add     r12, sp
        mov     r13, r0
        sub     sp, #48
        setq    #11
        wrlong  r0, sp
        mov     r0, r12
        mov     r1, r13
        calld   lr, #_fputs
        setq    #11
        rdlong  r0, sp
        add     sp, #48

' }
        add     sp, #248
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int fflush(int *fd)
_fflush  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return 0;

        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (!fd) return -1;
        mov     r1, r0
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0050
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (*fd & 0xfff00000) return 0;
label0050
        mov     r1, r0
        rdlong  r1, r1
        mov     r2, ##$fff00000
        and     r1, r2
        cmp     r1, #0  wz
 if_z   jmp     #label0051
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     loadhandle(*fd);
label0051
        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     pflush();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pflush
        rdlong  r0, sp
        add     sp, #4

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int *opendir(char *path)
_opendir global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     int err;
'     int *fd;
'     int *handle;
'     if (path[0] && strcmp(path, ".") && strcmp(path, "/") && strcmp(path,"./"))

        sub     sp, #16
        mov     r1, r0
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        calld   lr, #label0054
        byte    ".", 0
        alignl
label0054
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
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0
        mov     r2, r0
        calld   lr, #label0056
        byte    "/", 0
        alignl
label0056
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
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0
        mov     r2, r0
        calld   lr, #label0058
        byte    "./", 0
        alignl
label0058
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
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'         return 0;
        cmp     r1, #0  wz
 if_z   jmp     #label0052
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     fd = allocfile(44 + 512);
label0052
        mov     r1, #44
        mov     r2, ##512
        add     r1, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_allocfile
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     if (!fd) return 0;
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0059
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     handle = *fd;
label0059
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     memset(handle, 0, 40);
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        mov     r3, #40
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     handle[10] = &handle[11];
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #11
        shl     r2, #2
        add     r1, r2
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #10
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     loadhandle(handle);
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     err = popendir();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_popendir
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (err)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0060

'         loadhandle0();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_loadhandle0
        rdlong  r0, sp
        add     sp, #4

'         freefile(fd);
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_freefile
        rdlong  r0, sp
        add     sp, #4

'         return 0;
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     return fd;
label0060
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
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
' int *readdir(int *fd)
_readdir global
        sub     sp, #4
        wrlong  lr, sp

' {
'     loadhandle(*fd);

        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     if (!nextfile(dirbuf))
        mov     r1, ##dirbuf
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_nextfile
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         return dirbuf;
        cmp     r1, #0  wz
 if_z   jmp     #label0061
        mov     r1, ##dirbuf
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return 0;
label0061
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int closedir(int *fd)
_closedir global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return fclose(fd);

        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_fclose
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
' int fseek(int *fd, int offset, int origin)
_fseek   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!fd || origin < 0 || origin > 2) return -1;

        mov     r3, r0
        cmp     r3, #0  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        mov     r4, r2
        mov     r5, #0
        cmps    r4, r5  wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1
        mov     r4, r2
        mov     r5, #2
        cmps    r5, r4 wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r3, #0  wz
 if_z   jmp     #label0062
        mov     r3, #1
        neg     r3, r3
        mov     r0, r3
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     loadhandle(*fd);
label0062
        mov     r3, r0
        rdlong  r3, r3
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_loadhandle
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     if (origin == 1)
        mov     r3, r2
        mov     r4, #1
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         offset += tell();
        cmp     r3, #0  wz
 if_z   jmp     #label0063
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        calld   lr, #_tell
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r5, r1
        add     r3, r5
        mov     r1, r3

'     else if (origin == 2)
        jmp     #label0064
label0063
        mov     r3, r2
        mov     r4, #2
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'         offset += get_filesize();
        cmp     r3, #0  wz
 if_z   jmp     #label0065
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        calld   lr, #_get_filesize
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r5, r1
        add     r3, r5
        mov     r1, r3

'     return seek(offset);
label0065
label0064
        mov     r3, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_seek
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r0, r3
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int ftell(int *fd)
_ftell   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     loadhandle(*fd);

        mov     r1, r0
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     return tell();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_tell
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
' int fstat(int *fd, int *filestat)
_fstat   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     loadhandle(*fd);

        mov     r2, r0
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     pstat(filestat);
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_pstat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return 0;
        mov     r2, #0
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int stat(char *fname, int *filestat)
_stat    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int retval;
'     loadhandle0();

        sub     sp, #4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_loadhandle0
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     retval = popen(fname, 'r');
        mov     r2, r0
        mov     r3, #114
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_popen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (retval) return -1;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   jmp     #label0066
        mov     r2, #1
        neg     r2, r2
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     pstat(filestat);
label0066
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_pstat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     pclose();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return 0;
        mov     r2, #0
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
' void mkdir(char *path, int mode)
_mkdir   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return pmkdir(path);

        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_pmkdir
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
' void rmdir(void)
_rmdir   global
        sub     sp, #4
        wrlong  lr, sp

' {
' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF

CON
  main = 0
