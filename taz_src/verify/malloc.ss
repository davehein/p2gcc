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


' //'******************************************************************************
' //' C malloc functions
' //' Copyright (c) 2010-2015 Dave Hein
' //' See end of file for terms of use.
' //'******************************************************************************
' int memfreelist = 0;
memfreelist long 0

' int malloclist = 0;
malloclist long 0

' char *heapaddr = 0;
heapaddr long 0

' char *heapaddrlast = 0;
heapaddrlast long 0

' 
' void mallocinit(char *addr)
_mallocinit global
        sub     sp, #4
        wrlong  lr, sp

' {
'     malloclist = 0;

        mov     r1, #0
        wrlong  r1, ##malloclist

'     memfreelist = 0;
        mov     r1, #0
        wrlong  r1, ##memfreelist

'     heapaddr = addr;
        mov     r1, r0
        wrlong  r1, ##heapaddr

'     heapaddrlast = addr;
        mov     r1, r0
        wrlong  r1, ##heapaddrlast

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' char *malloc(int size)
_malloc  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int size1;
'     int *prevblk;
'     int *currblk;
'     int stackptr;
' 
'     // Return 0 if size less than 1
'     if (size < 1) return 0;

        sub     sp, #16
        mov     r1, r0
        mov     r2, #1
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0001
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     // Adjust size to nearest int plus the header size
'     size = ((size + 3) & (~3)) + 8;
label0001
        mov     r1, r0
        mov     r2, #3
        add     r1, r2
        mov     r2, #3
        xor     r2, ##$ffffffff
        and     r1, r2
        mov     r2, #8
        add     r1, r2
        mov     r0, r1

'     size1 = size >> 2;
        mov     r1, r0
        mov     r2, #2
        sar     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

' 
'     // Attempt to allocate from the free list
'     prevblk = 0;
        mov     r1, #0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     currblk = memfreelist;
        rdlong  r1, ##memfreelist
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     while (currblk)
label0002
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0003

'         if (currblk[1] >= size)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0004

'             // Split block if it's big enough
'             if (currblk[1] >= size + 12)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #12
        add     r2, r3
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0005

'                 currblk[size1] = currblk[0];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'                 currblk[size1+1] = currblk[1] - size;
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        sub     r1, r2
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        add     r3, r4
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'                 currblk[0] = &currblk[size1];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'                 currblk[1] = size;
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             }
'             // Remove block from free list
'             if (prevblk)
label0005
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1

'                 prevblk[0] = currblk[0];
        cmp     r1, #0  wz
 if_z   jmp     #label0006
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             else
'                 memfreelist = currblk[0];
        jmp     #label0007
label0006
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##memfreelist

'             AddToMallocList(currblk);
label0007
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_AddToMallocList
        rdlong  r0, sp
        add     sp, #4

'             return &currblk[2];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #2
        shl     r2, #2
        add     r1, r2
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         }
'         prevblk = currblk;
label0004
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'         currblk = currblk[0];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     }
' 
'     // Attempt to allocate heapaddrlast
'     stackptr = &stackptr;
        jmp     #label0002
label0003
        mov     r1, #12
        add     r1, sp
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     if (stackptr - heapaddrlast < size + 100) return 0;
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        rdlong  r2, ##heapaddrlast
        sub     r1, r2
        mov     r2, r0
        mov     r3, #100
        add     r2, r3
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0008
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     currblk = heapaddrlast;
label0008
        rdlong  r1, ##heapaddrlast
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     currblk[0] = 0;
        mov     r1, #0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     currblk[1] = size;
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     AddToMallocList(currblk);
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_AddToMallocList
        rdlong  r0, sp
        add     sp, #4

'     heapaddrlast += size;
        mov     r1, r0
        rdlong  r3, ##heapaddrlast
        add     r1, r3
        wrlong  r1, ##heapaddrlast

'     return &currblk[2];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #2
        shl     r2, #2
        add     r1, r2
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
' void AddToMallocList(int *newblk)
_AddToMallocList global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int *currblk;
' 
'     newblk[0] = 0;

        sub     sp, #4
        mov     r1, #0
        mov     r2, r0
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     if (malloclist)
        rdlong  r1, ##malloclist

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0009

'         currblk = malloclist;
        rdlong  r1, ##malloclist
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         while (currblk[0]) currblk = currblk[0];
label0010
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0011
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

'         currblk[0] = newblk;
        jmp     #label0010
label0011
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     }
'     else
'         malloclist = newblk;
        jmp     #label0012
label0009
        mov     r1, r0
        wrlong  r1, ##malloclist

' }
label0012
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Return the memory block at "ptr" to the free list.  Return a value of one
' // if successful, or zero if the memory block was not on the allocate list.
' int free(int *ptr)
_free    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int *prevblk;
'     int *currblk;
'     int *nextblk;
' 
'     prevblk = 0;

        sub     sp, #12
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     nextblk = malloclist;
        rdlong  r1, ##malloclist
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     currblk = &ptr[-2];
        mov     r1, r0
        mov     r2, #2
        neg     r2, r2
        shl     r2, #2
        add     r1, r2
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

' 
'     // Search the malloclist for the currblk pointer
'     while (nextblk)
label0013
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0014

'         if (currblk == nextblk)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0015

'             // Remove from the malloc list
'             if (prevblk)
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1

'                 prevblk[0] = nextblk[0];
        cmp     r1, #0  wz
 if_z   jmp     #label0016
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             else
'                 malloclist = nextblk[0];
        jmp     #label0017
label0016
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##malloclist

'             // Add to the free list
'             meminsert(nextblk);
label0017
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_meminsert
        rdlong  r0, sp
        add     sp, #4

'             trimfreelist();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_trimfreelist
        rdlong  r0, sp
        add     sp, #4

'             return 1;
        mov     r1, #1
        mov     r0, r1
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         }
'         prevblk = nextblk;
label0015
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         nextblk = nextblk[0];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     }
' 
'     // Return a NULL value if not found
'     return 0;
        jmp     #label0013
label0014
        mov     r1, #0
        mov     r0, r1
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
' void trimfreelist(void)
_trimfreelist global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int *currblk;
'     int *prevblk;
'     int ival;
' 
'     if (!memfreelist) return;

        sub     sp, #12
        rdlong  r0, ##memfreelist
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0018
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     prevblk = 0;
label0018
        mov     r0, #0
        mov     r1, #4
        add     r1, sp
        wrlong  r0, r1

'     currblk = memfreelist;
        rdlong  r0, ##memfreelist
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     while (currblk[0])
label0019
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0020

'         prevblk = currblk;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #4
        add     r1, sp
        wrlong  r0, r1

'         currblk = currblk[0];
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        shl     r1, #2
        add     r0, r1
        rdlong  r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     }
'     ival = currblk;
        jmp     #label0019
label0020
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #8
        add     r1, sp
        wrlong  r0, r1

'     if (ival + currblk[1] == heapaddrlast)
        mov     r0, #8
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        add     r0, r1
        rdlong  r1, ##heapaddrlast
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0021

'         heapaddrlast = currblk;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        wrlong  r0, ##heapaddrlast

'         if (prevblk)
        mov     r0, #4
        add     r0, sp
        rdlong  r0, r0

'             prevblk[0] = 0;
        cmp     r0, #0  wz
 if_z   jmp     #label0022
        mov     r0, #0
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'         else
'             memfreelist = 0;
        jmp     #label0023
label0022
        mov     r0, #0
        wrlong  r0, ##memfreelist

'     }
label0023

' }
label0021
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Insert a memory block back into the free list.  Merge blocks together if
' // the memory block is contiguous with other blocks on the list.
' void meminsert(int *currblk)
_meminsert global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int icurrblk;
'     int iprevblk;
'     int *prevblk;
'     int *nextblk;
' 
'     prevblk = 0;

        sub     sp, #16
        mov     r1, #0
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     nextblk = memfreelist;
        rdlong  r1, ##memfreelist
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     icurrblk = currblk;
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

' 
'     // Find Insertion Point
'     while (nextblk)
label0024
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0025

'         if (currblk >= prevblk && currblk <= nextblk) break;
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        mov     r2, r0
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0026
        jmp     #label0025

'         prevblk = nextblk;
label0026
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'         nextblk = nextblk[0];
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     }
'     iprevblk = prevblk;
        jmp     #label0024
label0025
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

' 
'     // Merge with the previous block if contiguous
'     if (prevblk && (iprevblk + prevblk[1] == icurrblk))
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #1
        shl     r4, #2
        add     r3, r4
        rdlong  r3, r3
        add     r2, r3
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0027

'         prevblk[1] = prevblk[1] + currblk[1];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         // Also merge with next block if contiguous
'         if (iprevblk + prevblk[1] == nextblk)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0028

'             prevblk[1] = prevblk[1] + nextblk[1];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             prevblk[0] = nextblk[0];
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         }
'     }
label0028

' 
'     // Merge with the next block if contiguous
'     else if (nextblk && icurrblk + currblk[1] == nextblk)
        jmp     #label0029
label0027
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #1
        shl     r4, #2
        add     r3, r4
        rdlong  r3, r3
        add     r2, r3
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0030

'         currblk[1] = currblk[1] + nextblk[1];
        mov     r1, r0
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         currblk[0] = nextblk[0];
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         if (prevblk)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1

'           prevblk[0] = currblk;
        cmp     r1, #0  wz
 if_z   jmp     #label0031
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         else
'           memfreelist = currblk;
        jmp     #label0032
label0031
        mov     r1, r0
        wrlong  r1, ##memfreelist

'     }
label0032

' 
'     // Insert in the middle of the free list if not contiguous
'     else if (prevblk)
        jmp     #label0033
label0030
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0034

'         prevblk[0] = currblk;
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         currblk[0] = nextblk;
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     }
' 
'     // Otherwise, insert at beginning of the free list
'     else
'     {
        jmp     #label0035
label0034

'         memfreelist = currblk;
        mov     r1, r0
        wrlong  r1, ##memfreelist

'         currblk[0] = nextblk;
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     }
' }
label0035
label0033
label0029
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Allocate a memory block of num*size bytes and initialize to zero.  Return
' // a pointer to the memory block if successful, or zero if a large enough
' // memory block could not be found.
' int *calloc(int num, int size)
_calloc  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     int *ptr1;
'     size *= num;

        sub     sp, #8
        mov     r2, r0
        mov     r4, r1
        qmul    r2, r4
        getqx   r2
        mov     r1, r2

'     ptr = malloc(size);
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_malloc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (ptr)
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0036

'         ptr1 = ptr;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         size = (size + 3) >> 2;
        mov     r2, r1
        mov     r3, #3
        add     r2, r3
        mov     r3, #2
        sar     r2, r3
        mov     r1, r2

'         while (size--) *ptr1++ = 0;
label0037
        mov     r2, r1
        mov     r3, r2
        sub     r3, #1
        mov     r1, r3
        cmp     r2, #0  wz
 if_z   jmp     #label0038
        mov     r2, #0
        mov     r5, #4
        add     r5, sp
        rdlong  r3, r5
        mov     r4, r3
        add     r4, #4
        wrlong  r4, r5
        wrlong  r2, r3

'     }
        jmp     #label0037
label0038

'     return ptr;
label0036
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

' EOF

CON
  main = 0
