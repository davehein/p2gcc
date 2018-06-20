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


' int malloclist;
malloclist long 0

' int memfreelist;
memfreelist long 0

' int heapaddrlast;
heapaddrlast long 0

' 
' void PrintMallocSpace(int parm)
_PrintMallocSpace global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int *ptr;
'     int ival;
' 
'     printf("Malloc list\n");

        sub     sp, #8
        calld   lr, #label0002
        byte    "Malloc list", 10, 0
        alignl
label0002
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     inline("cogid reg0");
cogid reg0

'     printf("cognum %d\n", parm);
        calld   lr, #label0004
        byte    "cognum %d", 10, 0
        alignl
label0004
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

'     inline("mov reg0, ptra");
mov reg0, ptra

'     printf("ptra = %x\n", parm);
        calld   lr, #label0006
        byte    "ptra = %x", 10, 0
        alignl
label0006
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

'     inline("mov reg0, ptrb");
mov reg0, ptrb

'     printf("ptrb = %x\n", parm);
        calld   lr, #label0008
        byte    "ptrb = %x", 10, 0
        alignl
label0008
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

'     printf("&ival = %x\n", &ival);
        calld   lr, #label0010
        byte    "&ival = %x", 10, 0
        alignl
label0010
        mov     r1, lr
        mov     r2, #4
        add     r2, sp
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

'     printf("heapaddrlast = %x\n", heapaddrlast);
        calld   lr, #label0012
        byte    "heapaddrlast = %x", 10, 0
        alignl
label0012
        mov     r1, lr
        rdlong  r2, ##heapaddrlast
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

'     inline("mov reg0, $58");
mov reg0, $58

'     printf("$58 = %x\n", parm);
        calld   lr, #label0014
        byte    "$58 = %x", 10, 0
        alignl
label0014
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

'     inline("mov reg0, $59");
mov reg0, $59

'     printf("$59 = %x\n", parm);
        calld   lr, #label0016
        byte    "$59 = %x", 10, 0
        alignl
label0016
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

'     inline("mov reg0, $5a");
mov reg0, $5a

'     printf("$5a = %x\n", parm);
        calld   lr, #label0018
        byte    "$5a = %x", 10, 0
        alignl
label0018
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

'     inline("mov reg0, $5b");
mov reg0, $5b

'     printf("$5b = %x\n", parm);
        calld   lr, #label0020
        byte    "$5b = %x", 10, 0
        alignl
label0020
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

'     ptr = malloclist;
        rdlong  r1, ##malloclist
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     while (ptr)
label0021
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0022

'         printf("%x %x\n", ptr, ptr[1]);
        calld   lr, #label0024
        byte    "%x %x", 10, 0
        alignl
label0024
        mov     r1, lr
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        shl     r4, #2
        add     r3, r4
        rdlong  r3, r3
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r3, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #12
        rdlong  r0, sp
        add     sp, #4

'         ptr = ptr[0];
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     }
' 
'     printf("Free list\n");
        jmp     #label0021
label0022
        calld   lr, #label0026
        byte    "Free list", 10, 0
        alignl
label0026
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     ptr = memfreelist;
        rdlong  r1, ##memfreelist
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     while (ptr)
label0027
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0028

'         printf("%x %x\n", ptr, ptr[1]);
        calld   lr, #label0030
        byte    "%x %x", 10, 0
        alignl
label0030
        mov     r1, lr
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        shl     r4, #2
        add     r3, r4
        rdlong  r3, r3
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r3, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #12
        rdlong  r0, sp
        add     sp, #4

'         ptr = ptr[0];
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     }
' 
'     printf("Stack space\n");
        jmp     #label0027
label0028
        calld   lr, #label0032
        byte    "Stack space", 10, 0
        alignl
label0032
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     ival = &ptr;
        mov     r1, #0
        add     r1, sp
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     printf("%x %x\n", heapaddrlast, ival - heapaddrlast);
        calld   lr, #label0034
        byte    "%x %x", 10, 0
        alignl
label0034
        mov     r1, lr
        rdlong  r2, ##heapaddrlast
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        rdlong  r4, ##heapaddrlast
        sub     r3, r4
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r3, sp
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #12
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     
' void main(void)
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int size;
'     char *ptr;
'     char buffer[80];
' 
'     PrintMallocSpace();

        sub     sp, #88
        calld   lr, #_PrintMallocSpace

'     while (1)
label0035
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0036

'         printf("Enter command: ");
        calld   lr, #label0038
        byte    "Enter command: ", 0
        alignl
label0038
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'         gets(buffer);
        mov     r0, #8
        add     r0, sp
        calld   lr, #_gets

'         if (!strcmp(buffer, "malloc"))
        mov     r0, #8
        add     r0, sp
        calld   lr, #label0041
        byte    "malloc", 0
        alignl
label0041
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0039

'             printf("Enter size: ");
        calld   lr, #label0043
        byte    "Enter size: ", 0
        alignl
label0043
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'             scanf("%x", &size);
        calld   lr, #label0045
        byte    "%x", 0
        alignl
label0045
        mov     r0, lr
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_scanf
        add     sp, #8

'             ptr = malloc(size);
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_malloc
        mov     r0, r0
        mov     r1, #4
        add     r1, sp
        wrlong  r0, r1

'             printf("Return value = %x\n", ptr);
        calld   lr, #label0047
        byte    "Return value = %x", 10, 0
        alignl
label0047
        mov     r0, lr
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'         }
'         else if (!strcmp(buffer, "free"))
        jmp     #label0048
label0039
        mov     r0, #8
        add     r0, sp
        calld   lr, #label0051
        byte    "free", 0
        alignl
label0051
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0049

'             printf("Enter address: ");
        calld   lr, #label0053
        byte    "Enter address: ", 0
        alignl
label0053
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'             scanf("%x", &ptr);
        calld   lr, #label0055
        byte    "%x", 0
        alignl
label0055
        mov     r0, lr
        mov     r1, #4
        add     r1, sp
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_scanf
        add     sp, #8

'             size = free(ptr);
        mov     r0, #4
        add     r0, sp
        rdlong  r0, r0
        calld   lr, #_free
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'             printf("Return value = %x\n", size);
        calld   lr, #label0057
        byte    "Return value = %x", 10, 0
        alignl
label0057
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

'         }
'         else if (!strcmp(buffer, "dump"))
        jmp     #label0058
label0049
        mov     r0, #8
        add     r0, sp
        calld   lr, #label0061
        byte    "dump", 0
        alignl
label0061
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0059

'             PrintMallocSpace();
        calld   lr, #_PrintMallocSpace

'         }
'         else if (!strcmp(buffer, "trim"))
        jmp     #label0062
label0059
        mov     r0, #8
        add     r0, sp
        calld   lr, #label0065
        byte    "trim", 0
        alignl
label0065
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0063

'             trimfreelist();
        calld   lr, #_trimfreelist

'         }
'         else if (!strcmp(buffer, "exit"))
        jmp     #label0066
label0063
        mov     r0, #8
        add     r0, sp
        calld   lr, #label0069
        byte    "exit", 0
        alignl
label0069
        mov     r1, lr
        calld   lr, #_strcmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'             break;
        cmp     r0, #0  wz
 if_z   jmp     #label0067
        jmp     #label0036

'         else
'             printf("Commands are malloc, free, dump, trim and exit\n");
        jmp     #label0070
label0067
        calld   lr, #label0072
        byte    "Commands are malloc, free, dump, trim and exit", 10, 0
        alignl
label0072
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     }
label0070
label0066
label0062
label0058
label0048

' }
        jmp     #label0035
label0036
        add     sp, #88
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' EOF
