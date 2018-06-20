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


' int main(void)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char fbuf[13];
'     int c;
'     int dummy;
'     char inbuf[80];
'     char *mode;
'     char *name;
'     char *tokens[10];
'     int num, err, i;
' 
'     mount_explicit(0, 1, 2, 3);

        sub     sp, #164
        mov     r0, #0
        mov     r1, #1
        mov     r2, #2
        mov     r3, #3
        calld   lr, #_mount_explicit

' 
'     printf("FSRWTEST\n");
        calld   lr, #label0002
        byte    "FSRWTEST", 10, 0
        alignl
label0002
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     Help();
        calld   lr, #_Help

'     while (1)
label0003
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0004

'         puts("\n> ");
        calld   lr, #label0006
        byte    10, "> ", 0
        alignl
label0006
        mov     r0, lr
        calld   lr, #_puts

'         gets(inbuf);
        mov     r0, #24
        add     r0, sp
        calld   lr, #_gets

'         num = Tokenize(inbuf, tokens);
        mov     r0, #24
        add     r0, sp
        mov     r1, #112
        add     r1, sp
        calld   lr, #_Tokenize
        mov     r0, r0
        mov     r1, #152
        add     r1, sp
        wrlong  r0, r1

'         if (!num) continue;
        mov     r0, #152
        add     r0, sp
        rdlong  r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0007
        jmp     #label0003

' 
'         if (!strcmp(tokens[0], "type"))
label0007
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0010
        byte    "type", 0
        alignl
label0010
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0008

'             if (num != 2)
        mov     r0, #152
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0011

'                 printf("usage: type file\n");
        calld   lr, #label0013
        byte    "usage: type file", 10, 0
        alignl
label0013
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'                 continue;
        jmp     #label0003

'             }
'             if (OpenFile(tokens[1], 'r')) continue;
label0011
        mov     r0, #112
        add     r0, sp
        mov     r1, #1
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        mov     r1, #114
        calld   lr, #_OpenFile
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0014
        jmp     #label0003

'             while ((c = pgetc()) >= 0) putchar(c);
label0014
label0015
        calld   lr, #_pgetc
        mov     r0, r0
        mov     r1, #16
        add     r1, sp
        wrlong  r0, r1
        mov     r1, #0
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0016
        mov     r0, #16
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_putchar

'             CloseFile();
        jmp     #label0015
label0016
        calld   lr, #_CloseFile

'         }
'         else if (!strcmp(tokens[0], "write"))
        jmp     #label0017
label0008
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0020
        byte    "write", 0
        alignl
label0020
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0018

'             if (num != 2)
        mov     r0, #152
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0021

'                 printf("usage: write file\n");
        calld   lr, #label0023
        byte    "usage: write file", 10, 0
        alignl
label0023
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'                 continue;
        jmp     #label0003

'             }
'             if (OpenFile(tokens[1], 'w')) continue;
label0021
        mov     r0, #112
        add     r0, sp
        mov     r1, #1
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        mov     r1, #119
        calld   lr, #_OpenFile
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0024
        jmp     #label0003

'             while ((c = getchar()) >= 0)
label0024
label0025
        calld   lr, #_getchar
        mov     r0, r0
        mov     r1, #16
        add     r1, sp
        wrlong  r0, r1
        mov     r1, #0
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0026

'                 if (c == 27) break;
        mov     r0, #16
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #27
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0027
        jmp     #label0026

'                 err = pputc(c);
label0027
        mov     r0, #16
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_pputc
        mov     r0, r0
        mov     r1, #156
        add     r1, sp
        wrlong  r0, r1

'                 if (err < 0)
        mov     r0, #156
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'                 {
        cmp     r0, #0  wz
 if_z   jmp     #label0028

'                     printf("Writing returned %d\n", err);
        calld   lr, #label0030
        byte    "Writing returned %d", 10, 0
        alignl
label0030
        mov     r0, lr
        mov     r1, #156
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'                     break;
        jmp     #label0026

'                 }
'             }
label0028

'             CloseFile();
        jmp     #label0025
label0026
        calld   lr, #_CloseFile

'         }
'         else if (!strcmp(tokens[0], "append"))
        jmp     #label0031
label0018
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0034
        byte    "append", 0
        alignl
label0034
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0032

'             if (num != 2)
        mov     r0, #152
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0035

'                 printf("usage: write file\n");
        calld   lr, #label0037
        byte    "usage: write file", 10, 0
        alignl
label0037
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'                 continue;
        jmp     #label0003

'             }
'             if (OpenFile(tokens[1], 'a')) continue;
label0035
        mov     r0, #112
        add     r0, sp
        mov     r1, #1
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        mov     r1, #97
        calld   lr, #_OpenFile
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0038
        jmp     #label0003

'             while ((c = getchar()) >= 0)
label0038
label0039
        calld   lr, #_getchar
        mov     r0, r0
        mov     r1, #16
        add     r1, sp
        wrlong  r0, r1
        mov     r1, #0
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0040

'                 if (c == 27) break;
        mov     r0, #16
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #27
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0041
        jmp     #label0040

'                 err = pputc(c);
label0041
        mov     r0, #16
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_pputc
        mov     r0, r0
        mov     r1, #156
        add     r1, sp
        wrlong  r0, r1

'                 if (err < 0)
        mov     r0, #156
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0

'                 {
        cmp     r0, #0  wz
 if_z   jmp     #label0042

'                     printf("Writing returned %d\n", err);
        calld   lr, #label0044
        byte    "Writing returned %d", 10, 0
        alignl
label0044
        mov     r0, lr
        mov     r1, #156
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'                     break;
        jmp     #label0040

'                 }
'             }
label0042

'             CloseFile();
        jmp     #label0039
label0040
        calld   lr, #_CloseFile

'         }
'         else if (!strcmp(tokens[0], "delete"))
        jmp     #label0045
label0032
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0048
        byte    "delete", 0
        alignl
label0048
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0046

'             if (num != 2)
        mov     r0, #152
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        sub     r0, r1  wz
 if_nz  mov     r0, #1

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0049

'                 printf("usage: delete file\n");
        calld   lr, #label0051
        byte    "usage: delete file", 10, 0
        alignl
label0051
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'                 continue;
        jmp     #label0003

'             }
'             if (OpenFile(tokens[1], 'd')) continue;
label0049
        mov     r0, #112
        add     r0, sp
        mov     r1, #1
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        mov     r1, #100
        calld   lr, #_OpenFile
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0052
        jmp     #label0003

'         }
label0052

'         else if (!strcmp(tokens[0], "list"))
        jmp     #label0053
label0046
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0056
        byte    "list", 0
        alignl
label0056
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0054

'             popendir();
        calld   lr, #_popendir

'             i = 0;
        mov     r0, #0
        mov     r1, #160
        add     r1, sp
        wrlong  r0, r1

'             while (nextfile(fbuf) == 0)
label0057
        mov     r0, #0
        add     r0, sp
        calld   lr, #_nextfile
        mov     r0, r0
        mov     r1, #0
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'             {
        cmp     r0, #0  wz
 if_z   jmp     #label0058

'                 i++;
        mov     r2, #160
        add     r2, sp
        rdlong  r0, r2
        add     r0, #1
        wrlong  r0, r2

'                 printf("%s", fbuf);
        calld   lr, #label0060
        byte    "%s", 0
        alignl
label0060
        mov     r0, lr
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'                 num = strlen(fbuf);
        mov     r0, #0
        add     r0, sp
        calld   lr, #_strlen
        mov     r0, r0
        mov     r1, #152
        add     r1, sp
        wrlong  r0, r1

'                 while (num++ < 14) putchar(' ');
label0061
        mov     r2, #152
        add     r2, sp
        rdlong  r0, r2
        mov     r1, r0
        add     r1, #1
        wrlong  r1, r2
        mov     r1, #14
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0062
        mov     r0, #32
        calld   lr, #_putchar

'                 if (!(i%5)) printf("\n");
        jmp     #label0061
label0062
        mov     r0, #160
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #5
        sub     sp, #4
        wrlong  r1, sp
        call    #__DIVSI
        mov     r0, r1
        rdlong  r1, sp
        add     sp, #4
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0063
        calld   lr, #label0065
        byte    10, 0
        alignl
label0065
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'             }
label0063

'             printf("\n");
        jmp     #label0057
label0058
        calld   lr, #label0067
        byte    10, 0
        alignl
label0067
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'             CloseFile();
        calld   lr, #_CloseFile

'         }
'         else if (!strcmp(tokens[0], "help"))
        jmp     #label0068
label0054
        mov     r0, #112
        add     r0, sp
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        calld   lr, #label0071
        byte    "help", 0
        alignl
label0071
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'             Help();
        cmp     r0, #0  wz
 if_z   jmp     #label0069
        calld   lr, #_Help

'         else
'         {
        jmp     #label0072
label0069

'             printf("Invalid command\n");
        calld   lr, #label0074
        byte    "Invalid command", 10, 0
        alignl
label0074
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'             printf("Commands are type, write, append, list, delete and help\n");
        calld   lr, #label0076
        byte    "Commands are type, write, append, list, delete and help", 10, 0
        alignl
label0076
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'         }
'     }
label0072
label0068
label0053
label0045
label0031
label0017

' }
        jmp     #label0003
label0004
        add     sp, #164
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Help(void)
_Help    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("Commands\n");

        calld   lr, #label0078
        byte    "Commands", 10, 0
        alignl
label0078
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  list        - List the files in the directory\n");
        calld   lr, #label0080
        byte    "  list        - List the files in the directory", 10, 0
        alignl
label0080
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  type file   - Type the contents of a file\n");
        calld   lr, #label0082
        byte    "  type file   - Type the contents of a file", 10, 0
        alignl
label0082
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  write file  - Create a file and write text to it\n");
        calld   lr, #label0084
        byte    "  write file  - Create a file and write text to it", 10, 0
        alignl
label0084
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  append file - Append text to a file\n");
        calld   lr, #label0086
        byte    "  append file - Append text to a file", 10, 0
        alignl
label0086
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  delete file - Delete a file\n");
        calld   lr, #label0088
        byte    "  delete file - Delete a file", 10, 0
        alignl
label0088
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     printf("  help        - Print this help information\n");
        calld   lr, #label0090
        byte    "  help        - Print this help information", 10, 0
        alignl
label0090
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
' int OpenFile(char *fname, int mode)
_OpenFile global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int err;
'     err = popen(fname, mode);

        sub     sp, #4
        mov     r2, r0
        mov     r3, r1
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

'     if (err) printf("File open failed with error code %d\n", err);
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   jmp     #label0091
        calld   lr, #label0093
        byte    "File open failed with error code %d", 10, 0
        alignl
label0093
        mov     r2, lr
        mov     r3, #0
        add     r3, sp
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

'     return err;
label0091
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
' void CloseFile(void)
_CloseFile global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int err;
'     err = pclose();

        sub     sp, #4
        calld   lr, #_pclose
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (err < 0) printf("Error closing:  %d\n", err);
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0094
        calld   lr, #label0096
        byte    "Error closing:  %d", 10, 0
        alignl
label0096
        mov     r0, lr
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

' }
label0094
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int Tokenize(char *ptr, char **tokens)
_Tokenize global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int num;
'     char *ptr1;
' 
'     num = 0;

        sub     sp, #8
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     while (*ptr)
label0097
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0098

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
 if_z   jmp     #label0099
        jmp     #label0098

'         ptr1 = FindChar(ptr, ' ');
label0099
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
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         if (*ptr1) *ptr1++ = 0;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        rdbyte  r2, r2
        cmp     r2, #0  wz
 if_z   jmp     #label0100
        mov     r2, #0
        mov     r5, #4
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #1
        wrlong  r4, r5
        wrbyte  r2, r3

'         tokens[num++] = ptr;
label0100
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

'         ptr = ptr1;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2

'     }
' 
'     return num;
        jmp     #label0097
label0098
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
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
' char *SkipChar(char *ptr, int val)
_SkipChar global
        sub     sp, #4
        wrlong  lr, sp

' {
'     while (*ptr)

label0101
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0102

'         if (*ptr != val) break;
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, r1
        sub     r2, r3  wz
 if_nz  mov     r2, #1
        cmp     r2, #0  wz
 if_z   jmp     #label0103
        jmp     #label0102

'         ptr++;
label0103
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     }
'     return ptr;
        jmp     #label0101
label0102
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
' char *FindChar(char *ptr, int val)
_FindChar global
        sub     sp, #4
        wrlong  lr, sp

' {
'     while (*ptr)

label0104
        mov     r2, r0
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0105

'         if (*ptr == val) break;
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, r1
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0106
        jmp     #label0105

'         ptr++;
label0106
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     }
'     return ptr;
        jmp     #label0104
label0105
        mov     r2, r0
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF
