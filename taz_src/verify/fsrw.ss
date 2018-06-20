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


' //{
' //   fsrw 2.6 Copyright 2009  Tomas Rokicki and Jonathan Dummer
' //
' //   See end of file for terms of use.
' //
' //   This object provides FAT16/32 file read/write access on a block device.
' //   Only one file open at a time.  Open modes are 'r' (read), 'a' (append),
' //   'w' (write), and 'd' (delete).  Only the root directory is supported.
' //   No long filenames are supported.  We also support traversing the
' //   root directory.
' //
' //   In general, negative return values are errors; positive return
' //   values are success.  Other than -1 on _popen when the file does not
' //   exist, all negative return values will be "aborted" rather than
' //   returned.
' //
' //   Changes:
' //       v1.1  28 December 2006  Fixed offset for ctime
' //       v1.2  29 December 2006  Made default block driver be fast one
' //       v1.3  6 January 2007    Added some docs, and a faster asm
' //       v1.4  4 February 2007   Rearranged vars to save memory;
' //                               eliminated need for adjacent pins;
' //                               reduced idle current consumption; added
' //                               sample code with abort code data
' //       v1.5  7 April 2007      Fixed problem when directory is larger
' //                               than a cluster.
' //       v1.6  23 September 2008 Fixed a bug found when mixing _pputc
' //                               with pwrite.  Also made the assembly
' //                               routines a bit more cautious.
' //       v2.1  12 July 2009      FAT32, SDHC, multiblock, bug fixes
' //       v2.4  26 September 2009 Added seek support.  Added clustersize.
' //       v2.4a   6 October 2009 modified setdate to explicitly set year/month/etc.
' //       v2.5  13 November 2009 fixed a bug on releasing the pins, added a "release" pass through function
' //       v2.6  11 December 2009: faster transfer hub <=> cog, safe_spi.spin uses 1/2 speed reads, is default
' //}
' //
' //   Constants describing FAT volumes.
' //
' 
' 
' 
' 
' 
' 
' //
' //
' //   Variables concerning the open file.
' //
' int fclust;        // the current cluster number
fclust long 0

' int filesize;      // the total current size of the file
filesize long 0

' int floc;          // the seek position of the file
floc long 0

' int frem;          // how many bytes remain in this cluster from this file
frem long 0

' int bufat;         // where in the buffer our current character is
bufat long 0

' int bufend;        // the last valid character (read) or free position (write)
bufend long 0

' int direntry;      // the byte address of the directory entry (if open for write)
direntry long 0

' int writelink;     // the byte offset of the disk location to store a new cluster
writelink long 0

' int fatptr;        // the byte address of the most recently written fat entry
fatptr long 0

' int firstcluster;  // the first cluster of this file
firstcluster long 0

' char *buf;         // pointer to the data buffer
buf long 0

' 
' //
' //   Variables used when mounting to describe the FAT layout of the card
' //   (moved to the end of the file in the Spin version).
' //
' int filesystem;    // 0 = unmounted, 1 = fat16, 2 = fat32
filesystem long 0

' int rootdir;       // the byte address of the start of the root directory
rootdir long 0

' int rootdirend;    // the byte immediately following the root directory.
rootdirend long 0

' int dataregion;    // the start of the data region, offset by two sectors
dataregion long 0

' int clustershift;  // log base 2 of blocks per cluster
clustershift long 0

' int clustersize;   // total size of cluster in bytes
clustersize long 0

' int fat1;          // the block address of the fat1 space
fat1 long 0

' int totclusters;   // how many clusters in the volume
totclusters long 0

' int sectorsperfat; // how many sectors per fat
sectorsperfat long 0

' int endofchain;    // end of chain marker (with a 0 at the end)
endofchain long 0

' int pdate;         // current date
pdate long 0

' 
' //
' //   Variables controlling the caching.
' //
' int lastread;     // the block address of the buf2 contents
lastread long 0

' int dirty;        // nonzero if buf2 is dirty
dirty long 0

' 
' //
' //  Buffering:  two sector buffers.  These two buffers must be longword
' //  aligned!  To ensure this, make sure they are the first byte variables
' //  defined in this object.
' //
' char buf1[512];   // main data buffer
buf1 byte 0[512]

' char buf2[512];   // main metadata buffer
buf2 byte 0[512]

' char padname[11]; // filename buffer
padname byte 0[11]

' int direntry0;
        alignl
direntry0 long 0

' 
' // Handle stuff
' int rootdir0;
rootdir0 long 0

' int rootdirend0;
rootdirend0 long 0

' int *curr_handle = 0;
curr_handle long 0

' int handle0[11];
handle0 long 0[11]

' 
' int loadhandle(int *handle)
_loadhandle global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!handle) return 0;

        mov     r1, r0
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0001
        mov     r1, #0
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     if (handle != curr_handle)
label0001
        mov     r1, r0
        rdlong  r2, ##curr_handle
        sub     r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0002

'         if (curr_handle)
        rdlong  r1, ##curr_handle

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0003

' //printf("Save curr_handle - %x\n", curr_handle);
'             curr_handle[0] = fclust;
        rdlong  r1, ##fclust
        rdlong  r2, ##curr_handle
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[1] = filesize;
        rdlong  r1, ##filesize
        rdlong  r2, ##curr_handle
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[2] = floc;
        rdlong  r1, ##floc
        rdlong  r2, ##curr_handle
        mov     r3, #2
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[3] = frem;
        rdlong  r1, ##frem
        rdlong  r2, ##curr_handle
        mov     r3, #3
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[4] = bufat;
        rdlong  r1, ##bufat
        rdlong  r2, ##curr_handle
        mov     r3, #4
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[5] = bufend;
        rdlong  r1, ##bufend
        rdlong  r2, ##curr_handle
        mov     r3, #5
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[6] = direntry;
        rdlong  r1, ##direntry
        rdlong  r2, ##curr_handle
        mov     r3, #6
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[7] = writelink;
        rdlong  r1, ##writelink
        rdlong  r2, ##curr_handle
        mov     r3, #7
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[8] = fatptr;
        rdlong  r1, ##fatptr
        rdlong  r2, ##curr_handle
        mov     r3, #8
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'             curr_handle[9] = firstcluster;
        rdlong  r1, ##firstcluster
        rdlong  r2, ##curr_handle
        mov     r3, #9
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'         }
' //printf("Load handle - %x\n", handle);
'         curr_handle  = handle;
label0003
        mov     r1, r0
        wrlong  r1, ##curr_handle

'         fclust       = curr_handle[0];
        rdlong  r1, ##curr_handle
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##fclust

'         filesize     = curr_handle[1];
        rdlong  r1, ##curr_handle
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##filesize

'         floc         = curr_handle[2];
        rdlong  r1, ##curr_handle
        mov     r2, #2
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##floc

'         frem         = curr_handle[3];
        rdlong  r1, ##curr_handle
        mov     r2, #3
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##frem

'         bufat        = curr_handle[4];
        rdlong  r1, ##curr_handle
        mov     r2, #4
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##bufat

'         bufend       = curr_handle[5];
        rdlong  r1, ##curr_handle
        mov     r2, #5
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##bufend

'         direntry     = curr_handle[6];
        rdlong  r1, ##curr_handle
        mov     r2, #6
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##direntry

'         writelink    = curr_handle[7];
        rdlong  r1, ##curr_handle
        mov     r2, #7
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##writelink

'         fatptr       = curr_handle[8];
        rdlong  r1, ##curr_handle
        mov     r2, #8
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##fatptr

'         firstcluster = curr_handle[9];
        rdlong  r1, ##curr_handle
        mov     r2, #9
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##firstcluster

'         buf          = curr_handle[10];
        rdlong  r1, ##curr_handle
        mov     r2, #10
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        wrlong  r1, ##buf

'     }
' 
'     return 1;
label0002
        mov     r1, #1
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void loadhandle0(void)
_loadhandle0 global
        sub     sp, #4
        wrlong  lr, sp

' {
'     loadhandle(handle0);

        mov     r0, ##handle0
        calld   lr, #_loadhandle

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int minimum(int a, int b)
_minimum global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (a < b) return a;

        mov     r2, r0
        mov     r3, r1
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0004
        mov     r2, r0
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return b;
label0004
        mov     r2, r1
        mov     r0, r2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void error(char *s)
_error   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("%s\n", s);

        calld   lr, #label0006
        byte    "%s", 10, 0
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

'     exit(10);
        mov     r1, #10
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
' void spinabort(int v)
_spinabort global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("Spin abort %d\n", v);

        calld   lr, #label0008
        byte    "Spin abort %d", 10, 0
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

'     exit(10);
        mov     r1, #10
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
' //
' //   This is just a pass-through function to allow the block layer
' //   to tristate the I/O pins to the card.
' //
' void release()
_release global
        sub     sp, #4
        wrlong  lr, sp

' {
'    //SPIN sdspi.release
' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   On metadata writes, if we are updating the FAT region, also update
' //   the second FAT region.
' //
' void writeblock2(int n, char *b)
_writeblock2 global
        sub     sp, #4
        wrlong  lr, sp

' {
'     writeblock(n, b);

        mov     r2, r0
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_writeblock
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     if (n >= fat1)
        mov     r2, r0
        rdlong  r3, ##fat1
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'         if (n < fat1 + sectorsperfat)
        cmp     r2, #0  wz
 if_z   jmp     #label0009
        mov     r2, r0
        rdlong  r3, ##fat1
        rdlong  r4, ##sectorsperfat
        add     r3, r4
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'             writeblock(n+sectorsperfat, b);
        cmp     r2, #0  wz
 if_z   jmp     #label0010
        mov     r2, r0
        rdlong  r3, ##sectorsperfat
        add     r2, r3
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_writeblock
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
label0010
label0009
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   If the metadata block is dirty, write it out.
' //
' void flushifdirty()
_flushifdirty global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (dirty)

        rdlong  r0, ##dirty

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0011

'         writeblock2(lastread, buf2);
        rdlong  r0, ##lastread
        mov     r1, ##buf2
        calld   lr, #_writeblock2

'         dirty = 0;
        mov     r0, #0
        wrlong  r0, ##dirty

'     }
' }
label0011
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Read a block into the metadata buffer, if that block is not already
' //   there.
' //
' void readblockc(int n)
_readblockc global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (n != lastread)

        mov     r1, r0
        rdlong  r2, ##lastread
        sub     r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0012

'         flushifdirty();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        rdlong  r0, sp
        add     sp, #4

'         readblock(n, buf2);
        mov     r1, r0
        mov     r2, ##buf2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_readblock
        rdlong  r0, sp
        add     sp, #4

'         lastread = n;
        mov     r1, r0
        wrlong  r1, ##lastread

'     }
' }
label0012
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Read a byte-reversed word from a (possibly odd) address.
' //
' int brword(char *b)
_brword  global
        sub     sp, #4
        wrlong  lr, sp

' {
'    return (b[0] & 255) + ((b[1] & 255) << 8);

        mov     r1, r0
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #255
        and     r1, r2
        mov     r2, r0
        mov     r3, #1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #255
        and     r2, r3
        mov     r3, #8
        shl     r2, r3
        add     r1, r2
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
' //   Read a byte-reversed long from a (possibly odd) address.
' //
' int brlong(char *b)
_brlong  global
        sub     sp, #4
        wrlong  lr, sp

' {
'    return brword(b) + (brword(b+2) << 16);

        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_brword
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, #2
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_brword
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #16
        shl     r2, r3
        add     r1, r2
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
' //   Read a cluster entry.
' //
' int brclust(char *b)
_brclust global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (filesystem == 1)

        rdlong  r1, ##filesystem
        mov     r2, #1
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         return brword(b);
        cmp     r1, #0  wz
 if_z   jmp     #label0013
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_brword
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     else
'         return brlong(b);
        jmp     #label0014
label0013
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_brlong
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
label0014
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Write a byte-reversed word to a (possibly odd) address, and
' //   mark the metadata buffer as dirty.
' //
' void brwword(char *w, int v)
_brwword global
        sub     sp, #4
        wrlong  lr, sp

' {
'     *w++ = v;

        mov     r2, r1
        mov     r3, r0
        mov     r4, r3
        add     r4, #1
        mov     r0, r4
        wrbyte  r2, r3

'     *w = v >> 8;
        mov     r2, r1
        mov     r3, #8
        sar     r2, r3
        mov     r3, r0
        wrbyte  r2, r3

'     dirty = 1;
        mov     r2, #1
        wrlong  r2, ##dirty

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Write a byte-reversed long to a (possibly odd) address, and
' //   mark the metadata buffer as dirty.
' //
' void brwlong(char *w, int v)
_brwlong global
        sub     sp, #4
        wrlong  lr, sp

' {
'     brwword(w, v);

        mov     r2, r0
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     brwword(w+2, v >> 16);
        mov     r2, r0
        mov     r3, #2
        add     r2, r3
        mov     r3, r1
        mov     r4, #16
        sar     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Write a cluster entry.
' void brwclust(char *w, int v)
_brwclust global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (filesystem == 1)

        rdlong  r2, ##filesystem
        mov     r3, #1
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         brwword(w, v);
        cmp     r2, #0  wz
 if_z   jmp     #label0015
        mov     r2, r0
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else
'         brwlong(w, v);
        jmp     #label0016
label0015
        mov     r2, r0
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
label0016
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   This may do more complicated stuff later.
' //
' void unmount()
_unmount global
        sub     sp, #4
        wrlong  lr, sp

' {
'     pclose();

        calld   lr, #_pclose

'     release();
        calld   lr, #_release

'   //SPIN sdspi.stop
' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getfstype()
_getfstype global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!strncmp(buf+0x36, "FAT16", 5)) return 1;

        rdlong  r0, ##buf
        mov     r1, #$36
        add     r0, r1
        calld   lr, #label0019
        byte    "FAT16", 0
        alignl
label0019
        mov     r1, lr
        mov     r2, #5
        calld   lr, #_strncmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0017
        mov     r0, #1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (!strncmp(buf+0x52, "FAT32", 5)) return 2;
label0017
        rdlong  r0, ##buf
        mov     r1, #$52
        add     r0, r1
        calld   lr, #label0022
        byte    "FAT32", 0
        alignl
label0022
        mov     r1, lr
        mov     r2, #5
        calld   lr, #_strncmp
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0020
        mov     r0, #2
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return 0;
label0020
        mov     r0, #0
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //{
' //   Mount a volume.  The address passed in is passed along to the block
' //   layer; see the currently used block layer for documentation.  If the
' //   volume mounts, a 0 is returned, else abort is called.
' //}
' int mount_explicit(int DO, int CLK, int DI, int CS)
_mount_explicit global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r, start, sectorspercluster, reserved, rootentries, sectors;
'     r = 0;

        sub     sp, #24
        mov     r4, #0
        mov     r5, #0
        add     r5, sp
        wrlong  r4, r5

'     buf = buf1;
        mov     r4, ##buf1
        wrlong  r4, ##buf

'     handle0[10] = buf1;
        mov     r4, ##buf1
        mov     r5, ##handle0
        mov     r6, #10
        shl     r6, #2
        add     r5, r6
        wrlong  r4, r5

'     curr_handle = handle0;
        mov     r4, ##handle0
        wrlong  r4, ##curr_handle

'     if (pdate == 0)
        rdlong  r4, ##pdate
        mov     r5, #0
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0

'         pdate = (((2009-1980) << 25) + (1 << 21) + (27 << 16) + (7 << 11));
        cmp     r4, #0  wz
 if_z   jmp     #label0023
        mov     r4, ##2009
        mov     r5, ##1980
        sub     r4, r5
        mov     r5, #25
        shl     r4, r5
        mov     r5, #1
        mov     r6, #21
        shl     r5, r6
        add     r4, r5
        mov     r5, #27
        mov     r6, #16
        shl     r5, r6
        add     r4, r5
        mov     r5, #7
        mov     r6, #11
        shl     r5, r6
        add     r4, r5
        wrlong  r4, ##pdate

'     //unmount();
'     sdspi_start_explicit(DO, CLK, DI, CS);
label0023
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
        calld   lr, #_sdspi_start_explicit
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     lastread = -1;
        mov     r4, #1
        neg     r4, r4
        wrlong  r4, ##lastread

'     dirty = 0;
        mov     r4, #0
        wrlong  r4, ##dirty

'     readblock(0, buf);
        mov     r4, #0
        rdlong  r5, ##buf
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_readblock
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     readblock(0, buf);
        mov     r4, #0
        rdlong  r5, ##buf
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_readblock
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     readblock(0, buf);
        mov     r4, #0
        rdlong  r5, ##buf
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_readblock
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     if (getfstype() > 0) {
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_getfstype
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #0
        cmps    r5, r4 wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        cmp     r4, #0  wz
 if_z   jmp     #label0024

'         start = 0;
        mov     r4, #0
        mov     r5, #4
        add     r5, sp
        wrlong  r4, r5

'     } else {
        jmp     #label0025
label0024

'         start = brlong(buf+0x1c6);
        rdlong  r4, ##buf
        mov     r5, #$1c6
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brlong
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #4
        add     r5, sp
        wrlong  r4, r5

'         readblock(start, buf);
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        rdlong  r5, ##buf
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        mov     r1, r5
        calld   lr, #_readblock
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     }
'     filesystem = getfstype();
label0025
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        calld   lr, #_getfstype
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        wrlong  r4, ##filesystem

'     if (filesystem == 0)
        rdlong  r4, ##filesystem
        mov     r5, #0
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0

'          spinabort(-20); // not a fat16 or fat32 volume
        cmp     r4, #0  wz
 if_z   jmp     #label0026
        mov     r4, #20
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_spinabort
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     if (brword(buf+0x0b) != 512)
label0026
        rdlong  r4, ##buf
        mov     r5, #$0b
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, ##512
        sub     r4, r5  wz
 if_nz  mov     r4, #1

'          spinabort(-21); // bad bytes per sector
        cmp     r4, #0  wz
 if_z   jmp     #label0027
        mov     r4, #21
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_spinabort
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     sectorspercluster = buf[0x0d];
label0027
        rdlong  r4, ##buf
        mov     r5, #$0d
        add     r4, r5
        rdbyte  r4, r4
        mov     r5, #8
        add     r5, sp
        wrlong  r4, r5

'     if (sectorspercluster & (sectorspercluster - 1))
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #8
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #1
        sub     r5, r6
        and     r4, r5

'          spinabort(-22); // bad sectors per cluster
        cmp     r4, #0  wz
 if_z   jmp     #label0028
        mov     r4, #22
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_spinabort
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     clustershift = 0;
label0028
        mov     r4, #0
        wrlong  r4, ##clustershift

'     while (sectorspercluster > 1) {
label0029
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #1
        cmps    r5, r4 wc
 if_c   mov     r4, #1
 if_nc  mov     r4, #0
        cmp     r4, #0  wz
 if_z   jmp     #label0030

'          clustershift++;
        rdlong  r4, ##clustershift
        add     r4, #1
        wrlong  r4, ##clustershift

'          sectorspercluster >>= 1;
        mov     r4, #1
        mov     r5, #8
        add     r5, sp
        rdlong  r6, r5
        sar     r6, r4
        wrlong  r6, r5

'     }
'     sectorspercluster = 1 << clustershift;
        jmp     #label0029
label0030
        mov     r4, #1
        rdlong  r5, ##clustershift
        shl     r4, r5
        mov     r5, #8
        add     r5, sp
        wrlong  r4, r5

'     clustersize = 512 << clustershift;
        mov     r4, ##512
        rdlong  r5, ##clustershift
        shl     r4, r5
        wrlong  r4, ##clustersize

'     reserved = brword(buf+0x0e);
        rdlong  r4, ##buf
        mov     r5, #$0e
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #12
        add     r5, sp
        wrlong  r4, r5

'     if (buf[0x10] != 2)
        rdlong  r4, ##buf
        mov     r5, #$10
        add     r4, r5
        rdbyte  r4, r4
        mov     r5, #2
        sub     r4, r5  wz
 if_nz  mov     r4, #1

'          spinabort(-23); // not two FATs
        cmp     r4, #0  wz
 if_z   jmp     #label0031
        mov     r4, #23
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_spinabort
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     sectors = brword(buf+0x13);
label0031
        rdlong  r4, ##buf
        mov     r5, #$13
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #20
        add     r5, sp
        wrlong  r4, r5

'     if (sectors == 0)
        mov     r4, #20
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #0
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0

'         sectors = brlong(buf+0x20);
        cmp     r4, #0  wz
 if_z   jmp     #label0032
        rdlong  r4, ##buf
        mov     r5, #$20
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brlong
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #20
        add     r5, sp
        wrlong  r4, r5

'     fat1 = start + reserved;
label0032
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #12
        add     r5, sp
        rdlong  r5, r5
        add     r4, r5
        wrlong  r4, ##fat1

'     if (filesystem == 2) {
        rdlong  r4, ##filesystem
        mov     r5, #2
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        cmp     r4, #0  wz
 if_z   jmp     #label0033

'          rootentries = 16 << clustershift;
        mov     r4, #16
        rdlong  r5, ##clustershift
        shl     r4, r5
        mov     r5, #16
        add     r5, sp
        wrlong  r4, r5

'          sectorsperfat = brlong(buf+0x24);
        rdlong  r4, ##buf
        mov     r5, #$24
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brlong
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        wrlong  r4, ##sectorsperfat

'          dataregion = (fat1 + 2 * sectorsperfat) - 2 * sectorspercluster;
        rdlong  r4, ##fat1
        mov     r5, #2
        rdlong  r6, ##sectorsperfat
        qmul    r5, r6
        getqx   r5
        add     r4, r5
        mov     r5, #2
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        qmul    r5, r6
        getqx   r5
        sub     r4, r5
        wrlong  r4, ##dataregion

'          rootdir = (dataregion + (brword(buf+0x2c) << clustershift)) << 9;
        rdlong  r4, ##dataregion
        rdlong  r5, ##buf
        mov     r6, #$2c
        add     r5, r6
        sub     sp, #20
        setq    #4
        wrlong  r0, sp
        mov     r0, r5
        calld   lr, #_brword
        mov     r5, r0
        setq    #4
        rdlong  r0, sp
        add     sp, #20
        rdlong  r6, ##clustershift
        shl     r5, r6
        add     r4, r5
        mov     r5, #9
        shl     r4, r5
        wrlong  r4, ##rootdir

'          rootdirend = rootdir + (rootentries << 5);
        rdlong  r4, ##rootdir
        mov     r5, #16
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #5
        shl     r5, r6
        add     r4, r5
        wrlong  r4, ##rootdirend

'          endofchain = 0xffffff0;
        mov     r4, ##$ffffff0
        wrlong  r4, ##endofchain

'     } else {
        jmp     #label0034
label0033

'          rootentries = brword(buf+0x11);
        rdlong  r4, ##buf
        mov     r5, #$11
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, #16
        add     r5, sp
        wrlong  r4, r5

'          sectorsperfat = brword(buf+0x16);
        rdlong  r4, ##buf
        mov     r5, #$16
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        wrlong  r4, ##sectorsperfat

'          rootdir = (fat1 + 2 * sectorsperfat) << 9;
        rdlong  r4, ##fat1
        mov     r5, #2
        rdlong  r6, ##sectorsperfat
        qmul    r5, r6
        getqx   r5
        add     r4, r5
        mov     r5, #9
        shl     r4, r5
        wrlong  r4, ##rootdir

'          rootdirend = rootdir + (rootentries << 5);
        rdlong  r4, ##rootdir
        mov     r5, #16
        add     r5, sp
        rdlong  r5, r5
        mov     r6, #5
        shl     r5, r6
        add     r4, r5
        wrlong  r4, ##rootdirend

'          dataregion = 1 + ((rootdirend - 1) >> 9) - 2 * sectorspercluster;
        mov     r4, #1
        rdlong  r5, ##rootdirend
        mov     r6, #1
        sub     r5, r6
        mov     r6, #9
        sar     r5, r6
        add     r4, r5
        mov     r5, #2
        mov     r6, #8
        add     r6, sp
        rdlong  r6, r6
        qmul    r5, r6
        getqx   r5
        sub     r4, r5
        wrlong  r4, ##dataregion

'          endofchain = 0xfff0;
        mov     r4, ##$fff0
        wrlong  r4, ##endofchain

'     }
'     rootdir0 = rootdir;
label0034
        rdlong  r4, ##rootdir
        wrlong  r4, ##rootdir0

'     rootdirend0 = rootdirend;
        rdlong  r4, ##rootdirend
        wrlong  r4, ##rootdirend0

'     if (brword(buf+0x1fe) != 0xaa55)
        rdlong  r4, ##buf
        mov     r5, #$1fe
        add     r4, r5
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_brword
        mov     r4, r0
        setq    #3
        rdlong  r0, sp
        add     sp, #16
        mov     r5, ##$aa55
        sub     r4, r5  wz
 if_nz  mov     r4, #1

'         spinabort(-24); // bad FAT signature
        cmp     r4, #0  wz
 if_z   jmp     #label0035
        mov     r4, #24
        neg     r4, r4
        sub     sp, #16
        setq    #3
        wrlong  r0, sp
        mov     r0, r4
        calld   lr, #_spinabort
        setq    #3
        rdlong  r0, sp
        add     sp, #16

'     totclusters = ((sectors - dataregion + start) >> clustershift);
label0035
        mov     r4, #20
        add     r4, sp
        rdlong  r4, r4
        rdlong  r5, ##dataregion
        sub     r4, r5
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        add     r4, r5
        rdlong  r5, ##clustershift
        sar     r4, r5
        wrlong  r4, ##totclusters

'     return r;
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r0, r4
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   For compatibility, a single pin.
' //
' int mount(int basepin)
_mount   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return mount_explicit(basepin, basepin+1, basepin+2, basepin+3);

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
        calld   lr, #_mount_explicit
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
' //   Read a byte address from the disk through the metadata buffer and
' //   return a pointer to that location.
' //
' char *readbytec(int byteloc)
_readbytec global
        sub     sp, #4
        wrlong  lr, sp

' {
'     readblockc(byteloc >> 9);

        mov     r1, r0
        mov     r2, #9
        sar     r1, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readblockc
        rdlong  r0, sp
        add     sp, #4

'     return buf2 + (byteloc & (512 - 1));
        mov     r1, ##buf2
        mov     r2, r0
        mov     r3, ##512
        mov     r4, #1
        sub     r3, r4
        and     r2, r3
        add     r1, r2
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
' //   Read a fat location and return a pointer to the location of that
' //   entry.
' //
' char *readfat(int clust)
_readfat global
        sub     sp, #4
        wrlong  lr, sp

' {
'     fatptr = (fat1 << 9) + (clust << filesystem);

        rdlong  r1, ##fat1
        mov     r2, #9
        shl     r1, r2
        mov     r2, r0
        rdlong  r3, ##filesystem
        shl     r2, r3
        add     r1, r2
        wrlong  r1, ##fatptr

'     return readbytec(fatptr);
        rdlong  r1, ##fatptr
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readbytec
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
' //   Follow the fat chain and update the writelink.
' //
' int followchain()
_followchain global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
'     r = brclust(readfat(fclust));

        sub     sp, #4
        rdlong  r0, ##fclust
        calld   lr, #_readfat
        mov     r0, r0
        calld   lr, #_brclust
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     writelink = fatptr;
        rdlong  r0, ##fatptr
        wrlong  r0, ##writelink

'     return r;
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
' //   Read the next cluster and return it.  Set up writelink to 
' //   point to the cluster we just read, for later updating.  If the
' //   cluster number is bad, return a negative number.
' //
' int nextcluster()
_nextcluster global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
'     r = followchain();

        sub     sp, #4
        calld   lr, #_followchain
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (r < 2 || r >= totclusters)
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #2
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        rdlong  r2, ##totclusters
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        or      r0, r1  wz
 if_nz  mov     r0, #1

'         spinabort(-9); // bad cluster value
        cmp     r0, #0  wz
 if_z   jmp     #label0036
        mov     r0, #9
        neg     r0, r0
        calld   lr, #_spinabort

'     return r;
label0036
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
' //   Free an entire cluster chain.  Used by remove and by overwrite.
' //   Assumes the pointer has already been cleared/set to end of chain.
' //
' void freeclusters(int clust)
_freeclusters global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *bp;
'     while (clust < endofchain) {

        sub     sp, #4
label0037
        mov     r1, r0
        rdlong  r2, ##endofchain
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0038

'         if (clust < 2)
        mov     r1, r0
        mov     r2, #2
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'             spinabort(-26); // bad cluster number");
        cmp     r1, #0  wz
 if_z   jmp     #label0039
        mov     r1, #26
        neg     r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_spinabort
        rdlong  r0, sp
        add     sp, #4

'         bp = readfat(clust);
label0039
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readfat
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         clust = brclust(bp);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_brclust
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r0, r1

'         brwclust(bp, 0);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_brwclust
        rdlong  r0, sp
        add     sp, #4

'     }
'     flushifdirty();
        jmp     #label0037
label0038
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Calculate the block address of the current data location.
' //
' int datablock()
_datablock global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return (fclust << clustershift) + dataregion + ((floc >> 9) & ((1 << clustershift) - 1));

        rdlong  r0, ##fclust
        rdlong  r1, ##clustershift
        shl     r0, r1
        rdlong  r1, ##dataregion
        add     r0, r1
        rdlong  r1, ##floc
        mov     r2, #9
        sar     r1, r2
        mov     r2, #1
        rdlong  r3, ##clustershift
        shl     r2, r3
        mov     r3, #1
        sub     r2, r3
        and     r1, r2
        add     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Compute the upper case version of a character.
' //
' int uc(int c)
_uc      global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if ('a' <= c && c <= 'z')

        mov     r1, #97
        mov     r2, r0
        cmps    r2, r1 wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        mov     r2, r0
        mov     r3, #122
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'         return c - 32;
        cmp     r1, #0  wz
 if_z   jmp     #label0040
        mov     r1, r0
        mov     r2, #32
        sub     r1, r2
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return c;
label0040
        mov     r1, r0
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
' //   Flush the current buffer, if we are open for write.  This may
' //   allocate a new cluster if needed.  If metadata is true, the
' //   metadata is written through to disk including any FAT cluster
' //   allocations and also the file size in the directory entry.
' //
' int pflushbuf(int rcnt, int metadata)
_pflushbuf global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r, cluststart, newcluster, count, i;
'     r = 0;

        sub     sp, #20
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (direntry == 0)
        rdlong  r2, ##direntry
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         spinabort(-27); // not open for writing
        cmp     r2, #0  wz
 if_z   jmp     #label0041
        mov     r2, #27
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     if (rcnt > 0) // must *not* allocate cluster if flushing an empty buffer
label0041
        mov     r2, r0
        mov     r3, #0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0042

'         if (frem < 512)
        rdlong  r2, ##frem
        mov     r3, ##512
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0043

'             // find a new cluster; could be anywhere!  If possible, stay on the
'             // same page used for the last cluster.
'             newcluster = -1;
        mov     r2, #1
        neg     r2, r2
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'             cluststart = fclust & (~((512 >> filesystem) - 1));
        rdlong  r2, ##fclust
        mov     r3, ##512
        rdlong  r4, ##filesystem
        sar     r3, r4
        mov     r4, #1
        sub     r3, r4
        xor     r3, ##$ffffffff
        and     r2, r3
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'             count = 2;
        mov     r2, #2
        mov     r3, #12
        add     r3, sp
        wrlong  r2, r3

'             while (1)
label0044
        mov     r2, #1

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0045

'                 readfat(cluststart);
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readfat
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 for (i=0; i<512; i+=1<<filesystem)
        mov     r2, #0
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3
label0046
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##512
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0048
        jmp     #label0049
label0047
        mov     r2, #1
        rdlong  r3, ##filesystem
        shl     r2, r3
        mov     r3, #16
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'                     if (buf2[i] == 0)
        jmp     #label0046
label0048
        mov     r2, ##buf2
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'                     {
        cmp     r2, #0  wz
 if_z   jmp     #label0050

'                         if (brclust(buf2+i) == 0)
        mov     r2, ##buf2
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_brclust
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'                         {
        cmp     r2, #0  wz
 if_z   jmp     #label0051

'                             newcluster = cluststart + (i >> filesystem);
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        rdlong  r4, ##filesystem
        sar     r3, r4
        add     r2, r3
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'                             if (newcluster >= totclusters)
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##totclusters
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'                                 newcluster = -1;
        cmp     r2, #0  wz
 if_z   jmp     #label0052
        mov     r2, #1
        neg     r2, r2
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'                             break;
label0052
        jmp     #label0049

'                         }
'                     }
label0051

'                     if (newcluster > 1)
label0050
        jmp     #label0047
label0049
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'                     {
        cmp     r2, #0  wz
 if_z   jmp     #label0053

'                         brwclust(buf2+i, endofchain+0xf);
        mov     r2, ##buf2
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        rdlong  r3, ##endofchain
        mov     r4, #$f
        add     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwclust
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                         if (writelink == 0)
        rdlong  r2, ##writelink
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'                         {
        cmp     r2, #0  wz
 if_z   jmp     #label0054

'                             brwword(readbytec(direntry)+0x1a, newcluster);
        rdlong  r2, ##direntry
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #$1a
        add     r2, r3
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                             writelink = (direntry&(512-filesystem));
        rdlong  r2, ##direntry
        mov     r3, ##512
        rdlong  r4, ##filesystem
        sub     r3, r4
        and     r2, r3
        wrlong  r2, ##writelink

'                             brwlong(buf2+writelink+0x1c, floc+bufat);
        mov     r2, ##buf2
        rdlong  r3, ##writelink
        add     r2, r3
        mov     r3, #$1c
        add     r2, r3
        rdlong  r3, ##floc
        rdlong  r4, ##bufat
        add     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                             if (filesystem == 2)
        rdlong  r2, ##filesystem
        mov     r3, #2
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'                             {
        cmp     r2, #0  wz
 if_z   jmp     #label0055

'                                 brwword(buf2+writelink+0x14, newcluster>>16);
        mov     r2, ##buf2
        rdlong  r3, ##writelink
        add     r2, r3
        mov     r3, #$14
        add     r2, r3
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #16
        sar     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                             }
'                     }
label0055

'                     else
'                     {
        jmp     #label0056
label0054

'                         brwclust(readbytec(writelink), newcluster);
        rdlong  r2, ##writelink
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwclust
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                     }
'                     writelink = fatptr + i;
label0056
        rdlong  r2, ##fatptr
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        wrlong  r2, ##writelink

'                     fclust = newcluster;
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        wrlong  r2, ##fclust

'                     frem = clustersize;
        rdlong  r2, ##clustersize
        wrlong  r2, ##frem

'                     break;
        jmp     #label0045

'                 }
'                 else
'                 {
        jmp     #label0057
label0053

'                     cluststart += (512 >> filesystem);
        mov     r2, ##512
        rdlong  r3, ##filesystem
        sar     r2, r3
        mov     r3, #4
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'                     if (cluststart >= totclusters)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##totclusters
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'                     {
        cmp     r2, #0  wz
 if_z   jmp     #label0058

'                         cluststart = 0;
        mov     r2, #0
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'                         count--;
        mov     r4, #12
        add     r4, sp
        rdlong  r2, r4
        sub     r2, #1
        wrlong  r2, r4

'                         if (rcnt < 0)
        mov     r2, r0
        mov     r3, #0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'                         {
        cmp     r2, #0  wz
 if_z   jmp     #label0059

'                             rcnt = -5; // No space left on device
        mov     r2, #5
        neg     r2, r2
        mov     r0, r2

'                             break;
        jmp     #label0045

'                         }
'                     }
label0059

'                 }
label0058

'             }
label0057

'         }
        jmp     #label0044
label0045

'         if (frem >= 512)
label0043
        rdlong  r2, ##frem
        mov     r3, ##512
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0060

'             writeblock(datablock(), buf);
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_datablock
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        rdlong  r3, ##buf
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_writeblock
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             if (rcnt == 512) // full buffer, clear it
        mov     r2, r0
        mov     r3, ##512
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0061

'                 floc += rcnt;
        mov     r2, r0
        rdlong  r4, ##floc
        add     r2, r4
        wrlong  r2, ##floc

'                 frem -= rcnt;
        mov     r2, r0
        rdlong  r4, ##frem
        sub     r4, r2
        wrlong  r4, ##frem

'                 bufat = 0;
        mov     r2, #0
        wrlong  r2, ##bufat

'                 bufend = rcnt;
        mov     r2, r0
        wrlong  r2, ##bufend

'             }
'         }
label0061

'     }
label0060

'     if (rcnt < 0 || metadata) // update metadata even if error
label0042
        mov     r2, r0
        mov     r3, #0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r1
        or      r2, r3  wz
 if_nz  mov     r2, #1

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0062

'         readblockc(direntry >> 9); // flushes unwritten FAT too
        rdlong  r2, ##direntry
        mov     r3, #9
        sar     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readblockc
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         brwlong(buf2+(direntry & (512-filesystem))+0x1c, floc+bufat);
        mov     r2, ##buf2
        rdlong  r3, ##direntry
        mov     r4, ##512
        rdlong  r5, ##filesystem
        sub     r4, r5
        and     r3, r4
        add     r2, r3
        mov     r3, #$1c
        add     r2, r3
        rdlong  r3, ##floc
        rdlong  r4, ##bufat
        add     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         flushifdirty();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
'     if (rcnt < 0)
label0062
        mov     r2, r0
        mov     r3, #0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         spinabort(rcnt);
        cmp     r2, #0  wz
 if_z   jmp     #label0063
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return rcnt;
label0063
        mov     r2, r0
        mov     r0, r2
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
' //{
' //   Call flush with the current data buffer location, and the flush
' //   metadata flag set.
' //}
' int pflush()
_pflush  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return pflushbuf(bufat, 1);

        rdlong  r0, ##bufat
        mov     r1, #1
        calld   lr, #_pflushbuf
        mov     r0, r0
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //
' //   Get some data into an empty buffer.  If no more data is available,
' //   return -1.  Otherwise return the number of bytes read into the
' //   buffer.
' //
' int pfillbuf()
_pfillbuf global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
'     r = 0;

        sub     sp, #4
        mov     r0, #0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (floc >= filesize)
        rdlong  r0, ##floc
        rdlong  r1, ##filesize
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'         return -1;
        cmp     r0, #0  wz
 if_z   jmp     #label0064
        mov     r0, #1
        neg     r0, r0
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (frem == 0) {
label0064
        rdlong  r0, ##frem
        mov     r1, #0
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0065

'         fclust = nextcluster();
        calld   lr, #_nextcluster
        mov     r0, r0
        wrlong  r0, ##fclust

'         frem = minimum(clustersize, filesize - floc);
        rdlong  r0, ##clustersize
        rdlong  r1, ##filesize
        rdlong  r2, ##floc
        sub     r1, r2
        calld   lr, #_minimum
        mov     r0, r0
        wrlong  r0, ##frem

'     }
'     readblock(datablock(), buf);
label0065
        calld   lr, #_datablock
        mov     r0, r0
        rdlong  r1, ##buf
        calld   lr, #_readblock

'     r = 512;
        mov     r0, ##512
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (floc + r >= filesize)
        rdlong  r0, ##floc
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        add     r0, r1
        rdlong  r1, ##filesize
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'         r = filesize - floc;
        cmp     r0, #0  wz
 if_z   jmp     #label0066
        rdlong  r0, ##filesize
        rdlong  r1, ##floc
        sub     r0, r1
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     floc += r;
label0066
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        rdlong  r2, ##floc
        add     r0, r2
        wrlong  r0, ##floc

'     frem -= r;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        rdlong  r2, ##frem
        sub     r2, r0
        wrlong  r2, ##frem

'     bufat = 0;
        mov     r0, #0
        wrlong  r0, ##bufat

'     bufend = r;
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        wrlong  r0, ##bufend

'     return r;
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
' //{
' //   Flush and close the currently open file if any.  Also reset the
' //   pointers to valid values.  If there is no error, 0 will be returned.
' //}
' int pclose()
_pclose  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
'     r = 0;

        sub     sp, #4
        mov     r0, #0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     if (direntry)
        rdlong  r0, ##direntry

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0067

'         //printf("pclose: direntry = %x\n", direntry);
'         r = pflush();
        calld   lr, #_pflush
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     }
'     bufat = 0;
label0067
        mov     r0, #0
        wrlong  r0, ##bufat

'     bufend = 0;
        mov     r0, #0
        wrlong  r0, ##bufend

'     filesize = 0;
        mov     r0, #0
        wrlong  r0, ##filesize

'     floc = 0;
        mov     r0, #0
        wrlong  r0, ##floc

'     frem = 0;
        mov     r0, #0
        wrlong  r0, ##frem

'     writelink = 0;
        mov     r0, #0
        wrlong  r0, ##writelink

'     direntry = 0;
        mov     r0, #0
        wrlong  r0, ##direntry

'     fclust = 0;
        mov     r0, #0
        wrlong  r0, ##fclust

'     firstcluster = 0;
        mov     r0, #0
        wrlong  r0, ##firstcluster

'     //SPIN sdspi.release
'     return r;
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
' //{
' //   Set the current date and time, as a long, in the format
' //   required by FAT16.  Various limits are not checked.
' //}
' int setdate(int year, int month, int day, int hour, int minute, int second)
_setdate global
        sub     sp, #4
        wrlong  lr, sp

' {
'     pdate = ((year-1980) << 25) + (month << 21) + (day << 16);

        mov     r6, r0
        mov     r7, ##1980
        sub     r6, r7
        mov     r7, #25
        shl     r6, r7
        mov     r7, r1
        mov     r8, #21
        shl     r7, r8
        add     r6, r7
        mov     r7, r2
        mov     r8, #16
        shl     r7, r8
        add     r6, r7
        wrlong  r6, ##pdate

'     pdate += (hour << 11) + (minute << 5) + (second >> 1);
        mov     r6, r3
        mov     r7, #11
        shl     r6, r7
        mov     r7, r4
        mov     r8, #5
        shl     r7, r8
        add     r6, r7
        mov     r7, r5
        mov     r8, #1
        sar     r7, r8
        add     r6, r7
        rdlong  r8, ##pdate
        add     r6, r8
        wrlong  r6, ##pdate

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' 
' void ConvertName(char *fname1, char *fname2)
_ConvertName global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
' 
'     i = 0;

        sub     sp, #4
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     while (i < 8 && *fname1 && *fname1 != '.')
label0068
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        rdbyte  r3, r3
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #46
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         fname2[i++] = uc(*fname1++);
        cmp     r2, #0  wz
 if_z   jmp     #label0069
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_uc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     while (i < 8)
        jmp     #label0068
label0069
label0070
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         fname2[i++] = ' ';
        cmp     r2, #0  wz
 if_z   jmp     #label0071
        mov     r2, #32
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     while (*fname1 &&  *fname1 != '.')
        jmp     #label0070
label0071
label0072
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, r0
        rdbyte  r3, r3
        mov     r4, #46
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         fname1++;
        cmp     r2, #0  wz
 if_z   jmp     #label0073
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     if (*fname1 == '.')
        jmp     #label0072
label0073
        mov     r2, r0
        rdbyte  r2, r2
        mov     r3, #46
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         fname1++;
        cmp     r2, #0  wz
 if_z   jmp     #label0074
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     while (i < 11 && *fname1)
label0074
label0075
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        rdbyte  r3, r3
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         fname2[i++] = uc(*fname1++);
        cmp     r2, #0  wz
 if_z   jmp     #label0076
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_uc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     while (i < 11)
        jmp     #label0075
label0076
label0077
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         fname2[i++] = ' ';
        cmp     r2, #0  wz
 if_z   jmp     #label0078
        mov     r2, #32
        mov     r3, r1
        mov     r6, #0
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

' }
        jmp     #label0077
label0078
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //{
' //   Close any currently open file, and open a new one with the given
' //   file name and mode.  Mode can be 'r' 'w' 'a' or 'd' (delete).
' //   If the file is opened successfully, 0 will be returned.  If the
' //   file did not exist, and the mode was not 'w' or 'a', -1 will be
' //   returned.  Otherwise abort will be called with a negative error
' //   code.
' //}
' int popen(char *s, char mode)
_popen   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r, i, sentinel, dirptr, freeentry;
' //printf("popen: %s %c\n", s, mode);
'     r = 0;

        sub     sp, #20
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     pclose();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     i = 0;
        mov     r2, #0
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     while (i<8 && s[0] && s[0] != '.')
label0079
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        mov     r4, #0
        add     r3, r4
        rdbyte  r3, r3
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0
        mov     r3, r0
        mov     r4, #0
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #46
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0080

'         //printf("padname[%d] = %x\n", i, *s);
'         padname[i++] = uc(*s++);
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_uc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, ##padname
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     }
'     while (i<8)
        jmp     #label0079
label0080
label0081
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         padname[i++] = ' ';
        cmp     r2, #0  wz
 if_z   jmp     #label0082
        mov     r2, #32
        mov     r3, ##padname
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     while (s[0] && s[0] != '.')
        jmp     #label0081
label0082
label0083
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #0
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #46
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         s++;
        cmp     r2, #0  wz
 if_z   jmp     #label0084
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     if (s[0] == '.')
        jmp     #label0083
label0084
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #46
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         s++;
        cmp     r2, #0  wz
 if_z   jmp     #label0085
        mov     r2, r0
        add     r2, #1
        mov     r0, r2

'     while (i<11 && s[0])
label0085
label0086
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        mov     r3, r0
        mov     r4, #0
        add     r3, r4
        rdbyte  r3, r3
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         padname[i++] = uc(*s++);
        cmp     r2, #0  wz
 if_z   jmp     #label0087
        mov     r2, r0
        mov     r3, r2
        add     r3, #1
        mov     r0, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_uc
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, ##padname
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     while (i < 11)
        jmp     #label0086
label0087
label0088
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'         padname[i++] = ' ';
        cmp     r2, #0  wz
 if_z   jmp     #label0089
        mov     r2, #32
        mov     r3, ##padname
        mov     r6, #4
        add     r6, sp
        rdlong  r4, r6
        mov     r5, r4
        add     r5, #1
        wrlong  r5, r6
        add     r3, r4
        wrbyte  r2, r3

'     sentinel = 0;
        jmp     #label0088
label0089
        mov     r2, #0
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'     freeentry = 0;
        mov     r2, #0
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

' //printf("padname = %s\n", padname);
' //printf("padname = %x, buf2 = %x\n", padname, buf2);
'     for (dirptr=rootdir; dirptr<rootdirend; dirptr += 32)
        rdlong  r2, ##rootdir
        mov     r3, #12
        add     r3, sp
        wrlong  r2, r3
label0090
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##rootdirend
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0092
        jmp     #label0093
label0091
        mov     r2, #32
        mov     r3, #12
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'     {
        jmp     #label0090
label0092

'         s = readbytec(dirptr);
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2

'         if (freeentry == 0 && (s[0] == 0 || s[0] == 0xe5))
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        mov     r3, r0
        mov     r4, #0
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #0
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        mov     r4, r0
        mov     r5, #0
        add     r4, r5
        rdbyte  r4, r4
        mov     r5, #$e5
        cmp     r4, r5  wz
 if_z   mov     r4, #1
 if_nz  mov     r4, #0
        or      r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'             freeentry = dirptr;
        cmp     r2, #0  wz
 if_z   jmp     #label0094
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

'         if (s[0] == 0)
label0094
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0095

'             sentinel = dirptr;
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'             break;
        jmp     #label0093

'         }
' //printf("padname = %s, s = %s\n", padname, s);
'         for (i=0; i<11; i++)
label0095
        mov     r2, #0
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3
label0096
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        cmp     r2, #0  wz
 if_nz  jmp     #label0098
        jmp     #label0099
label0097
        mov     r4, #4
        add     r4, sp
        rdlong  r2, r4
        add     r2, #1
        wrlong  r2, r4

'             if (padname[i] != s[i])
        jmp     #label0096
label0098
        mov     r2, ##padname
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        add     r3, r4
        rdbyte  r3, r3
        sub     r2, r3  wz
 if_nz  mov     r2, #1

'                 break;
        cmp     r2, #0  wz
 if_z   jmp     #label0100
        jmp     #label0099

'         if (i == 11 && 0 == (s[0x0b] & 0x08)) // this always returns
label0100
        jmp     #label0097
label0099
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #11
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        mov     r3, #0
        mov     r4, r0
        mov     r5, #$0b
        add     r4, r5
        rdbyte  r4, r4
        mov     r5, #$08
        and     r4, r5
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0101

'             fclust = brword(s+0x1a);
        mov     r2, r0
        mov     r3, #$1a
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_brword
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##fclust

'             if (filesystem == 2)
        rdlong  r2, ##filesystem
        mov     r3, #2
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0102

'                 fclust += brword(s+0x14) << 16;
        mov     r2, r0
        mov     r3, #$14
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_brword
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #16
        shl     r2, r3
        rdlong  r4, ##fclust
        add     r2, r4
        wrlong  r2, ##fclust

'             }
'             firstcluster = fclust;
label0102
        rdlong  r2, ##fclust
        wrlong  r2, ##firstcluster

'             filesize = brlong(s+0x1c);
        mov     r2, r0
        mov     r3, #$1c
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_brlong
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##filesize

'             if (mode == 'r')
        mov     r2, r1
        mov     r3, #114
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0103

'                 frem = minimum(clustersize, filesize);
        rdlong  r2, ##clustersize
        rdlong  r3, ##filesize
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_minimum
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##frem

'                 direntry0 = dirptr;
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        wrlong  r2, ##direntry0

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'             if (s[11] & 0xd9)
label0103
        mov     r2, r0
        mov     r3, #11
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$d9
        and     r2, r3

'                 spinabort(-6); // no permission to write
        cmp     r2, #0  wz
 if_z   jmp     #label0104
        mov     r2, #6
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             if (mode == 'd')
label0104
        mov     r2, r1
        mov     r3, #100
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0105

' //printf("About to delete %s\n", padname);
'                 brwword(s, 0xe5);
        mov     r2, r0
        mov     r3, #$e5
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 if (fclust)
        rdlong  r2, ##fclust

'                     freeclusters(fclust);
        cmp     r2, #0  wz
 if_z   jmp     #label0106
        rdlong  r2, ##fclust
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_freeclusters
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' //printf("Flush it\n");
'                 flushifdirty();
label0106
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'             if (mode == 'w')
label0105
        mov     r2, r1
        mov     r3, #119
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0107

'                 brwword(s+0x1a, 0);
        mov     r2, r0
        mov     r3, #$1a
        add     r2, r3
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 brwword(s+0x14, 0);
        mov     r2, r0
        mov     r3, #$14
        add     r2, r3
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 brwlong(s+0x1c, 0);
        mov     r2, r0
        mov     r3, #$1c
        add     r2, r3
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 writelink = 0;
        mov     r2, #0
        wrlong  r2, ##writelink

'                 direntry = dirptr;
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        wrlong  r2, ##direntry

'                 if (fclust)
        rdlong  r2, ##fclust

'                     freeclusters(fclust);
        cmp     r2, #0  wz
 if_z   jmp     #label0108
        rdlong  r2, ##fclust
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_freeclusters
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 bufend = 512;
label0108
        mov     r2, ##512
        wrlong  r2, ##bufend

'                 fclust = 0;
        mov     r2, #0
        wrlong  r2, ##fclust

'                 filesize = 0;
        mov     r2, #0
        wrlong  r2, ##filesize

'                 frem = 0;
        mov     r2, #0
        wrlong  r2, ##frem

'                 return 0;
        mov     r2, #0
        mov     r0, r2
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'             else if (mode == 'a')
        jmp     #label0109
label0107
        mov     r2, r1
        mov     r3, #97
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0110

'                 // this code will eventually be moved to seek
'                 frem = filesize;
        rdlong  r2, ##filesize
        wrlong  r2, ##frem

'                 freeentry = clustersize;
        rdlong  r2, ##clustersize
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

'                 if (fclust >= endofchain)
        rdlong  r2, ##fclust
        rdlong  r3, ##endofchain
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'                     fclust = 0;
        cmp     r2, #0  wz
 if_z   jmp     #label0111
        mov     r2, #0
        wrlong  r2, ##fclust

'                 while (frem > freeentry)
label0111
label0112
        rdlong  r2, ##frem
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'                 {
        cmp     r2, #0  wz
 if_z   jmp     #label0113

'                     if (fclust < 2)
        rdlong  r2, ##fclust
        mov     r3, #2
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'                         spinabort(-7); // eof while following chain
        cmp     r2, #0  wz
 if_z   jmp     #label0114
        mov     r2, #7
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                     fclust = nextcluster();
label0114
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_nextcluster
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        wrlong  r2, ##fclust

'                     frem -= freeentry;
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        rdlong  r4, ##frem
        sub     r4, r2
        wrlong  r4, ##frem

'                 }
'                 floc = filesize & (~(512 - 1));
        jmp     #label0112
label0113
        rdlong  r2, ##filesize
        mov     r3, ##512
        mov     r4, #1
        sub     r3, r4
        xor     r3, ##$ffffffff
        and     r2, r3
        wrlong  r2, ##floc

'                 bufend = 512;
        mov     r2, ##512
        wrlong  r2, ##bufend

'                 bufat = frem & (512 - 1);
        rdlong  r2, ##frem
        mov     r3, ##512
        mov     r4, #1
        sub     r3, r4
        and     r2, r3
        wrlong  r2, ##bufat

'                 writelink = 0;
        mov     r2, #0
        wrlong  r2, ##writelink

'                 direntry = dirptr;
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        wrlong  r2, ##direntry

'                 if (bufat)
        rdlong  r2, ##bufat

'                 {
        cmp     r2, #0  wz
 if_z   jmp     #label0115

'                     readblock(datablock(), buf);
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_datablock
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        rdlong  r3, ##buf
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_readblock
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                     frem = freeentry - (floc & (freeentry - 1));
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##floc
        mov     r4, #16
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #1
        sub     r4, r5
        and     r3, r4
        sub     r2, r3
        wrlong  r2, ##frem

'                 }
'                 else
'                 {
        jmp     #label0116
label0115

'                     if (fclust < 2 || frem == freeentry)
        rdlong  r2, ##fclust
        mov     r3, #2
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        rdlong  r3, ##frem
        mov     r4, #16
        add     r4, sp
        rdlong  r4, r4
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        or      r2, r3  wz
 if_nz  mov     r2, #1

'                         frem = 0;
        cmp     r2, #0  wz
 if_z   jmp     #label0117
        mov     r2, #0
        wrlong  r2, ##frem

'                     else
'                         frem = freeentry - (floc & (freeentry - 1));
        jmp     #label0118
label0117
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##floc
        mov     r4, #16
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #1
        sub     r4, r5
        and     r3, r4
        sub     r2, r3
        wrlong  r2, ##frem

'                 }
label0118

'                 if (fclust >= 2)
label0116
        rdlong  r2, ##fclust
        mov     r3, #2
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'                     followchain();
        cmp     r2, #0  wz
 if_z   jmp     #label0119
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_followchain
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'                 return 0;
label0119
        mov     r2, #0
        mov     r0, r2
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'             else
'             {
        jmp     #label0120
label0110

'                 spinabort(-3); // bad argument
        mov     r2, #3
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'             }
'         }
label0120
label0109

'     }
label0101

'     if (mode != 'w' && mode != 'a')
        jmp     #label0091
label0093
        mov     r2, r1
        mov     r3, #119
        sub     r2, r3  wz
 if_nz  mov     r2, #1
        mov     r3, r1
        mov     r4, #97
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'         return -1; // not found
        cmp     r2, #0  wz
 if_z   jmp     #label0121
        mov     r2, #1
        neg     r2, r2
        mov     r0, r2
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     direntry = freeentry;
label0121
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        wrlong  r2, ##direntry

'     if (direntry == 0)
        rdlong  r2, ##direntry
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         spinabort(-2); // no empty directory entry
        cmp     r2, #0  wz
 if_z   jmp     #label0122
        mov     r2, #2
        neg     r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_spinabort
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     // write (or new append): create valid directory entry
'     s = readbytec(direntry);
label0122
        rdlong  r2, ##direntry
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r0, r2

'     memset(s, 0, 32);
        mov     r2, r0
        mov     r3, #0
        mov     r4, #32
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

'     memcpy(s, padname, 11);
        mov     r2, r0
        mov     r3, ##padname
        mov     r4, #11
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_memcpy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     brwword(s+0x1a, 0);
        mov     r2, r0
        mov     r3, #$1a
        add     r2, r3
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     brwword(s+0x14, 0);
        mov     r2, r0
        mov     r3, #$14
        add     r2, r3
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     i = pdate;
        rdlong  r2, ##pdate
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     brwlong(s+0xe, i); // write create time and date
        mov     r2, r0
        mov     r3, #$e
        add     r2, r3
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     brwlong(s+0x16, i); // write last modified date and time
        mov     r2, r0
        mov     r3, #$16
        add     r2, r3
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwlong
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     if (direntry == sentinel && direntry + 32 < rootdirend)
        rdlong  r2, ##direntry
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        rdlong  r3, ##direntry
        mov     r4, #32
        add     r3, r4
        rdlong  r4, ##rootdirend
        cmps    r3, r4  wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0

'          brwword(readbytec(direntry+32), 0);
        cmp     r2, #0  wz
 if_z   jmp     #label0123
        rdlong  r2, ##direntry
        mov     r3, #32
        add     r2, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_brwword
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     flushifdirty();
label0123
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     writelink = 0;
        mov     r2, #0
        wrlong  r2, ##writelink

'     fclust = 0;
        mov     r2, #0
        wrlong  r2, ##fclust

'     bufend = 512;
        mov     r2, ##512
        wrlong  r2, ##bufend

'     return r;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2
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
' int get_filesize()
_get_filesize global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return filesize;

        rdlong  r0, ##filesize
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //{
' //   Read count bytes into the buffer ubuf.  Returns the number of bytes
' //   successfully read, or a negative number if there is an error.
' //   The buffer may be as large as you want.
' //}
' int pread(char *ubuf, int count)
_pread   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r, t;
'     r = 0;

        sub     sp, #8
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     while (count > 0)
label0124
        mov     r2, r1
        mov     r3, #0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0125

'         if (bufat >= bufend)
        rdlong  r2, ##bufat
        rdlong  r3, ##bufend
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'         {
        cmp     r2, #0  wz
 if_z   jmp     #label0126

'             t = pfillbuf();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pfillbuf
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'             if (t <= 0)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmps    r3, r2 wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'             {
        cmp     r2, #0  wz
 if_z   jmp     #label0127

'                 if (r > 0)
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'                 // parens below prevent this from being optimized out
'                 return (r);
        cmp     r2, #0  wz
 if_z   jmp     #label0128
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'                 return t;
label0128
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0127

'         t = minimum(bufend - bufat, count);
label0126
        rdlong  r2, ##bufend
        rdlong  r3, ##bufat
        sub     r2, r3
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_minimum
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         memcpy(ubuf, buf+bufat, t);
        mov     r2, r0
        rdlong  r3, ##buf
        rdlong  r4, ##bufat
        add     r3, r4
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_memcpy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         bufat += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        rdlong  r4, ##bufat
        add     r2, r4
        wrlong  r2, ##bufat

'         r += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'         ubuf += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r4, r0
        add     r2, r4
        mov     r0, r2

'         count -= t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r4, r1
        sub     r4, r2
        mov     r1, r4

'     }
'     return r;
        jmp     #label0124
label0125
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
' //{
' //   Read and return a single character.  If the end of file is
' //   reached, -1 will be returned.  If an error occurs, a negative
' //   number will be returned.
' //}
' int pgetc()
_pgetc   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int t;
'     if (bufat >= bufend)

        sub     sp, #4
        rdlong  r0, ##bufat
        rdlong  r1, ##bufend
        cmps    r0, r1  wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0129

'         t = pfillbuf();
        calld   lr, #_pfillbuf
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'         if (t <= 0)
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        mov     r1, #0
        cmps    r1, r0 wc
 if_nc  mov     r0, #1
 if_c   mov     r0, #0

'             return -1;
        cmp     r0, #0  wz
 if_z   jmp     #label0130
        mov     r0, #1
        neg     r0, r0
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
label0130

'     return (buf[bufat++] & 255);
label0129
        rdlong  r0, ##buf
        rdlong  r1, ##bufat
        mov     r2, r1
        add     r2, #1
        wrlong  r2, ##bufat
        add     r0, r1
        rdbyte  r0, r0
        mov     r1, #255
        and     r0, r1
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
' //{
' //   Write count bytes from the buffer ubuf.  Returns the number of bytes
' //   successfully written, or a negative number if there is an error.
' //   The buffer may be as large as you want.
' //}
' int pwrite(char *ubuf, int count)
_pwrite  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r, t;
'     r = 0;

        sub     sp, #8
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     while (count > 0)
label0131
        mov     r2, r1
        mov     r3, #0
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0132

'         if (bufat >= bufend)
        rdlong  r2, ##bufat
        rdlong  r3, ##bufend
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0

'             pflushbuf(bufat, 0);
        cmp     r2, #0  wz
 if_z   jmp     #label0133
        rdlong  r2, ##bufat
        mov     r3, #0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_pflushbuf
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         t = minimum(bufend - bufat, count);
label0133
        rdlong  r2, ##bufend
        rdlong  r3, ##bufat
        sub     r2, r3
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_minimum
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         memcpy(buf+bufat, ubuf, t);
        rdlong  r2, ##buf
        rdlong  r3, ##bufat
        add     r2, r3
        mov     r3, r0
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        mov     r2, r4
        calld   lr, #_memcpy
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         r += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'         bufat += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        rdlong  r4, ##bufat
        add     r2, r4
        wrlong  r2, ##bufat

'         ubuf += t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r4, r0
        add     r2, r4
        mov     r0, r2

'         count -= t;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r4, r1
        sub     r4, r2
        mov     r1, r4

'     }
'     return r;
        jmp     #label0131
label0132
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
' //{
' //   Write a null-terminated string to the file.
' //}
' int pputs(char *b)
_pputs   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return pwrite(b, strlen(b));

        mov     r1, r0
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_strlen
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_pwrite
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
' //{
' //   Write a single character into the file open for write.  Returns
' //   0 if successful, or a negative number if some error occurred.
' //}
' int pputc(int c)
_pputc   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int r;
'     r = 0;

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     if (bufat == 512)
        rdlong  r1, ##bufat
        mov     r2, ##512
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         if (pflushbuf(512, 0) < 0)
        cmp     r1, #0  wz
 if_z   jmp     #label0134
        mov     r1, ##512
        mov     r2, #0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_pflushbuf
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'             return -1;
        cmp     r1, #0  wz
 if_z   jmp     #label0135
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     buf[bufat++] = c;
label0135
label0134
        mov     r1, r0
        rdlong  r2, ##buf
        rdlong  r3, ##bufat
        mov     r4, r3
        add     r4, #1
        wrlong  r4, ##bufat
        add     r2, r3
        wrbyte  r1, r2

'     return r;
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
' //{
' //   Seek.  Right now will only seek within the current cluster.
' //   Added for PrEdit so he can debug; do not use with files larger
' //   than one cluster (and make that cluster size 32K please.)
' //
' //   Returns -1 on failure.  Make sure to check this return code!
' //
' //   We only support reads right now (but writes won't be too hard to
' //   add).
' //}
' int seek(int pos)
_seek    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int delta;
'     if (direntry || pos < 0 || pos > filesize)

        sub     sp, #4
        rdlong  r1, ##direntry
        mov     r2, r0
        mov     r3, #0
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1
        mov     r2, r0
        rdlong  r3, ##filesize
        cmps    r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'         return -1;
        cmp     r1, #0  wz
 if_z   jmp     #label0136
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     delta = (floc - bufend) & - clustersize;
label0136
        rdlong  r1, ##floc
        rdlong  r2, ##bufend
        sub     r1, r2
        rdlong  r2, ##clustersize
        neg     r2, r2
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     if (pos < delta)
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0137

'         fclust = firstcluster;
        rdlong  r1, ##firstcluster
        wrlong  r1, ##fclust

'         frem = minimum(clustersize, filesize);
        rdlong  r1, ##clustersize
        rdlong  r2, ##filesize
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_minimum
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##frem

'         floc = 0;
        mov     r1, #0
        wrlong  r1, ##floc

'         bufat = 0;
        mov     r1, #0
        wrlong  r1, ##bufat

'         bufend = 0;
        mov     r1, #0
        wrlong  r1, ##bufend

'         delta = 0;
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     }
'     while (pos >= delta + clustersize)
label0137
label0138
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        rdlong  r3, ##clustersize
        add     r2, r3
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0139

'         fclust = nextcluster();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_nextcluster
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##fclust

'         floc += clustersize;
        rdlong  r1, ##clustersize
        rdlong  r3, ##floc
        add     r1, r3
        wrlong  r1, ##floc

'         delta += clustersize;
        rdlong  r1, ##clustersize
        mov     r2, #0
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'         frem = minimum(clustersize, filesize - floc);
        rdlong  r1, ##clustersize
        rdlong  r2, ##filesize
        rdlong  r3, ##floc
        sub     r2, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_minimum
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##frem

'         bufat = 0;
        mov     r1, #0
        wrlong  r1, ##bufat

'         bufend = 0;
        mov     r1, #0
        wrlong  r1, ##bufend

'     }
'     if (bufend == 0 || pos < floc - bufend || pos >= floc - bufend + 512)
        jmp     #label0138
label0139
        rdlong  r1, ##bufend
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        mov     r2, r0
        rdlong  r3, ##floc
        rdlong  r4, ##bufend
        sub     r3, r4
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1
        mov     r2, r0
        rdlong  r3, ##floc
        rdlong  r4, ##bufend
        sub     r3, r4
        mov     r4, ##512
        add     r3, r4
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0140

'         // must change buffer
'         delta = floc + frem;
        rdlong  r1, ##floc
        rdlong  r2, ##frem
        add     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         floc = pos & - 512;
        mov     r1, r0
        mov     r2, ##512
        neg     r2, r2
        and     r1, r2
        wrlong  r1, ##floc

'         frem = delta - floc;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        rdlong  r2, ##floc
        sub     r1, r2
        wrlong  r1, ##frem

'         pfillbuf();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pfillbuf
        rdlong  r0, sp
        add     sp, #4

'     }
'     bufat = pos & (512 - 1);
label0140
        mov     r1, r0
        mov     r2, ##512
        mov     r3, #1
        sub     r2, r3
        and     r1, r2
        wrlong  r1, ##bufat

'     return 0;
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
' int tell()
_tell    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return floc + bufat - bufend;

        rdlong  r0, ##floc
        rdlong  r1, ##bufat
        add     r0, r1
        rdlong  r1, ##bufend
        sub     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //{
' //   Close the currently open file, and set up the read buffer for
' //   calls to nextfile().
' //}
' int popendir()
_popendir global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int off;
'     pclose();

        sub     sp, #4
        calld   lr, #_pclose

'     off = rootdir - (dataregion << 9);
        rdlong  r0, ##rootdir
        rdlong  r1, ##dataregion
        mov     r2, #9
        shl     r1, r2
        sub     r0, r1
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'     fclust = off >> (clustershift + 9);
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        rdlong  r1, ##clustershift
        mov     r2, #9
        add     r1, r2
        sar     r0, r1
        wrlong  r0, ##fclust

'     floc = off - (fclust << (clustershift + 9));
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        rdlong  r1, ##fclust
        rdlong  r2, ##clustershift
        mov     r3, #9
        add     r2, r3
        shl     r1, r2
        sub     r0, r1
        wrlong  r0, ##floc

'     frem = rootdirend - rootdir;
        rdlong  r0, ##rootdirend
        rdlong  r1, ##rootdir
        sub     r0, r1
        wrlong  r0, ##frem

'     filesize = floc + frem;
        rdlong  r0, ##floc
        rdlong  r1, ##frem
        add     r0, r1
        wrlong  r0, ##filesize

'     return 0;
        mov     r0, #0
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
' //{
' //   Find the next file in the root directory and extract its
' //   (8.3) name into fbuf.  Fbuf must be sized to hold at least
' //   13 characters (8 + 1 + 3 + 1).  If there is no next file,
' //   -1 will be returned.  If there is, 0 will be returned.
' //}
' int nextfile(char *fbuf)
_nextfile global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, t; char *at, *lns;
'     while (1)

        sub     sp, #16
label0141
        mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0142

'         if (bufat >= bufend)
        rdlong  r1, ##bufat
        rdlong  r2, ##bufend
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0143

'             t = pfillbuf();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pfillbuf
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'             if (t < 0)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'                 return t;
        cmp     r1, #0  wz
 if_z   jmp     #label0144
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             if (((floc >> 9) & ((1 << clustershift) - 1)) == 0)
label0144
        rdlong  r1, ##floc
        mov     r2, #9
        sar     r1, r2
        mov     r2, #1
        rdlong  r3, ##clustershift
        shl     r2, r3
        mov     r3, #1
        sub     r2, r3
        and     r1, r2
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'                 fclust++;
        cmp     r1, #0  wz
 if_z   jmp     #label0145
        rdlong  r1, ##fclust
        add     r1, #1
        wrlong  r1, ##fclust

'         }
label0145

'         at = buf + bufat;
label0143
        rdlong  r1, ##buf
        rdlong  r2, ##bufat
        add     r1, r2
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'         if (at[0] == 0)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             return -1;
        cmp     r1, #0  wz
 if_z   jmp     #label0146
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         bufat += 32;
label0146
        mov     r1, #32
        rdlong  r3, ##bufat
        add     r1, r3
        wrlong  r1, ##bufat

'         if (at[0] != 0xe5 && (at[0x0b] & 0x08) == 0)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$e5
        sub     r1, r2  wz
 if_nz  mov     r1, #1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$0b
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$08
        and     r2, r3
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0147

'             lns = fbuf;
        mov     r1, r0
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'             for (i=0; i<11; i++)
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0148
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #11
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0150
        jmp     #label0151
label0149
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'             {
        jmp     #label0148
label0150

'                 fbuf[0] = at[i];
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        wrbyte  r1, r2

'                 fbuf++;
        mov     r1, r0
        add     r1, #1
        mov     r0, r1

'                 if (at[i] != ' ')
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #32
        sub     r1, r2  wz
 if_nz  mov     r1, #1

'                     lns = fbuf;
        cmp     r1, #0  wz
 if_z   jmp     #label0152
        mov     r1, r0
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'                 if (i == 7 || i == 10)
label0152
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #7
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #10
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'                 {
        cmp     r1, #0  wz
 if_z   jmp     #label0153

'                     fbuf = lns;
        mov     r1, #12
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1

'                     if (i == 7)
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #7
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'                     {
        cmp     r1, #0  wz
 if_z   jmp     #label0154

'                         fbuf[0] = '.';
        mov     r1, #46
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        wrbyte  r1, r2

'                         fbuf++;
        mov     r1, r0
        add     r1, #1
        mov     r0, r1

'                     }
'                 }
label0154

'             }
label0153

'             fbuf[0] = 0;
        jmp     #label0149
label0151
        mov     r1, #0
        mov     r2, r0
        mov     r3, #0
        add     r2, r3
        wrbyte  r1, r2

'             return 0;
        mov     r1, #0
        mov     r0, r1
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         }
'     }
label0147

' }
        jmp     #label0141
label0142
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' //{
' //   Utility routines; may be removed.
' //}
' int getclustersize()
_getclustersize global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return clustersize;

        rdlong  r0, ##clustersize
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int getclustercount()
_getclustercount global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return totclusters;

        rdlong  r0, ##totclusters
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void pstat(int *filestat)
_pstat   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     ptr = readbytec(direntry0) + 11;

        sub     sp, #4
        rdlong  r1, ##direntry0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readbytec
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #11
        add     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     filestat[0] = *ptr;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #0
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

'     filestat[1] = filesize;
        rdlong  r1, ##filesize
        mov     r2, r0
        mov     r3, #1
        shl     r3, #2
        add     r2, r3
        wrlong  r1, r2

' }
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void InitRootDirectory(void)
_InitRootDirectory global
        sub     sp, #4
        wrlong  lr, sp

' {
'     rootdir = rootdir0;

        rdlong  r0, ##rootdir0
        wrlong  r0, ##rootdir

'     rootdirend = rootdirend0;
        rdlong  r0, ##rootdirend0
        wrlong  r0, ##rootdirend

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int InitSubDirectory(char *fname)
_InitSubDirectory global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     int retval;
'     char tempbuf[64];
' 
'     //printf("InitSubDirectory: %s\n", fname);
'     loadhandle(handle0);

        sub     sp, #72
        mov     r1, ##handle0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     retval = popen(fname, 'r');
        mov     r1, r0
        mov     r2, #114
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_popen
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (retval)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0155

'         //printf("InitSubDirectory: failed %d\n", result);
'         return retval;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
        add     sp, #72
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     ptr = readbytec(direntry0) + 11;
label0155
        rdlong  r1, ##direntry0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readbytec
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #11
        add     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     if (!(*ptr & 0x10))
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1
        mov     r2, #$10
        and     r1, r2
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0156

'         pclose();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pclose
        rdlong  r0, sp
        add     sp, #4

'         return -2;
        mov     r1, #2
        neg     r1, r1
        mov     r0, r1
        add     sp, #72
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     rootdir = ((fclust << clustershift) + dataregion) << 9;
label0156
        rdlong  r1, ##fclust
        rdlong  r2, ##clustershift
        shl     r1, r2
        rdlong  r2, ##dataregion
        add     r1, r2
        mov     r2, #9
        shl     r1, r2
        wrlong  r1, ##rootdir

'     rootdirend = rootdir + 32768;
        rdlong  r1, ##rootdir
        mov     r2, ##32768
        add     r1, r2
        wrlong  r1, ##rootdirend

'     pclose();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pclose
        rdlong  r0, sp
        add     sp, #4

'     return retval;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
        add     sp, #72
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #72
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int pchdir(char *path)
_pchdir  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int retval;
'     char *nextptr;
'     retval = 0;

        sub     sp, #8
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

' 
'     //printf("chdir: %s\n", path);
'     // Check if starting from root directory
'     if (*path == '/')
        mov     r1, r0
        rdbyte  r1, r1
        mov     r2, #47
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0157

'         path++;
        mov     r1, r0
        add     r1, #1
        mov     r0, r1

'         InitRootDirectory();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_InitRootDirectory
        rdlong  r0, sp
        add     sp, #4

'     }
' 
'     // Loop over sub-directory names in path
'     while (*path)
label0157
label0158
        mov     r1, r0
        rdbyte  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0159

'         nextptr = path;
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'         while (*nextptr)
label0160
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0161

'             if (*nextptr++ == '/')
        mov     r3, #4
        add     r3, sp
        rdlong  r1, r3
        mov     r2, r1
        add     r2, #1
        wrlong  r2, r3
        rdbyte  r1, r1
        mov     r2, #47
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0162

'                 nextptr[-1] = 0;
        mov     r1, #0
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        neg     r3, r3
        add     r2, r3
        wrbyte  r1, r2

'                 break;
        jmp     #label0161

'             }
'         }
label0162

'         if (retval = InitSubDirectory(path))
        jmp     #label0160
label0161
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_InitSubDirectory
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'             InitRootDirectory();
        cmp     r1, #0  wz
 if_z   jmp     #label0163
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_InitRootDirectory
        rdlong  r0, sp
        add     sp, #4

'         if (*nextptr)
label0163
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        rdbyte  r1, r1

'             nextptr[-1] = '/';
        cmp     r1, #0  wz
 if_z   jmp     #label0164
        mov     r1, #47
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        neg     r3, r3
        add     r2, r3
        wrbyte  r1, r2

'         if (retval)
label0164
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1

'             break;
        cmp     r1, #0  wz
 if_z   jmp     #label0165
        jmp     #label0159

'         path = nextptr;
label0165
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1

'     }
'     return retval;
        jmp     #label0158
label0159
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
' int pmkdir(char *fname)
_pmkdir  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     int retval;
'     char tempbuf[32];
' 
'     loadhandle(handle0);

        sub     sp, #40
        mov     r1, ##handle0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        rdlong  r0, sp
        add     sp, #4

'     retval = popen(fname, 'r');
        mov     r1, r0
        mov     r2, #114
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_popen
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (!retval)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0166

'         pclose();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pclose
        rdlong  r0, sp
        add     sp, #4

'         return -1;
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #40
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     retval = popen(fname, 'w');
label0166
        mov     r1, r0
        mov     r2, #119
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_popen
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (retval) return retval;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0167
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
        add     sp, #40
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     ptr = readbytec(direntry) + 11;
label0167
        rdlong  r1, ##direntry
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_readbytec
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #11
        add     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     *ptr = 0x30;
        mov     r1, #$30
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        wrbyte  r1, r2

'     dirty = 1;
        mov     r1, #1
        wrlong  r1, ##dirty

'     memset(tempbuf, 0, 32);
        mov     r1, #8
        add     r1, sp
        mov     r2, #0
        mov     r3, #32
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     pwrite(tempbuf, 32);
        mov     r1, #8
        add     r1, sp
        mov     r2, #32
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_pwrite
        rdlong  r0, sp
        add     sp, #4

'     pclose();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_pclose
        rdlong  r0, sp
        add     sp, #4

'     flushifdirty();
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        rdlong  r0, sp
        add     sp, #4

'     return retval;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r0, r1
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
' int chmod(char *fname, int modebits)
_chmod   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     int retval;
' 
'     loadhandle(handle0);

        sub     sp, #8
        mov     r2, ##handle0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
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
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     if (!retval)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0168

'         pclose();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         ptr = readbytec(direntry0) + 11;
        rdlong  r2, ##direntry0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #11
        add     r2, r3
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'         *ptr = modebits;
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        wrbyte  r2, r3

'         dirty = 1;
        mov     r2, #1
        wrlong  r2, ##dirty

'         flushifdirty();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
' 
'     return retval;
label0168
        mov     r2, #4
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
' int rename(char *fname1, char *fname2)
_rename  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     char *ptr;
'     int retval;
' 
'     //printf("rename %s %s\n", fname1, fname2);
'     loadhandle(handle0);

        sub     sp, #8
        mov     r2, ##handle0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_loadhandle
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     retval = popen(fname2, 'r');
        mov     r2, r1
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
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     if (!retval)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0169

'         pclose();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         //printf("Trace 1\n");
'         return -2;
        mov     r2, #2
        neg     r2, r2
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     retval = popen(fname1, 'r');
label0169
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
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     if (retval)
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0170

'         //printf("Trace 2\n");
'         return retval;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r0, r2
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     //printf("Trace 3\n");
'     pclose();
label0170
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_pclose
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     ptr = readbytec(direntry0);
        rdlong  r2, ##direntry0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_readbytec
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     ConvertName(fname2, ptr);
        mov     r2, r1
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_ConvertName
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     dirty = 1;
        mov     r2, #1
        wrlong  r2, ##dirty

'     flushifdirty();
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        calld   lr, #_flushifdirty
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     return 0;
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
' // This routine returns the first sector number
' int hget_first_sector(int *handle)
_hget_first_sector global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (!loadhandle(handle)) return -1;

        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_loadhandle
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0171
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return (firstcluster << clustershift) + dataregion;
label0171
        rdlong  r1, ##firstcluster
        rdlong  r2, ##clustershift
        shl     r1, r2
        rdlong  r2, ##dataregion
        add     r1, r2
        mov     r0, r1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int *get_volumeinfo(void)
_get_volumeinfo global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return &filesystem;

        mov     r0, ##filesystem
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int *get_fileinfo(void)
_get_fileinfo global
        sub     sp, #4
        wrlong  lr, sp

' {
'     return &fclust;

        mov     r0, ##fclust
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' char *hgets(int *handle, char *ubuf, int count)
_hgets   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int val;
'     int index;
'     char *ptr;
' 
'     if (!loadhandle(handle)) return 0;

        sub     sp, #12
        mov     r3, r0
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_loadhandle
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        cmp     r3, #0  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0172
        mov     r3, #0
        mov     r0, r3
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
'     count--;
label0172
        mov     r3, r2
        sub     r3, #1
        mov     r2, r3

'     index = 0;
        mov     r3, #0
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     while (index < count)
label0173
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r2
        cmps    r3, r4  wc
 if_c   mov     r3, #1
 if_nc  mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0174

'         if (bufat >= bufend)
        rdlong  r3, ##bufat
        rdlong  r4, ##bufend
        cmps    r3, r4  wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'         {
        cmp     r3, #0  wz
 if_z   jmp     #label0175

'             if (pfillbuf() <= 0)
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        calld   lr, #_pfillbuf
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #0
        cmps    r4, r3 wc
 if_nc  mov     r3, #1
 if_c   mov     r3, #0

'             {
        cmp     r3, #0  wz
 if_z   jmp     #label0176

'                 if (index) break;
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        cmp     r3, #0  wz
 if_z   jmp     #label0177
        jmp     #label0174

'                 return 0;
label0177
        mov     r3, #0
        mov     r0, r3
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0176

'         ubuf[index++] = val = buf[bufat++];
label0175
        rdlong  r3, ##buf
        rdlong  r4, ##bufat
        mov     r5, r4
        add     r5, #1
        wrlong  r5, ##bufat
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4
        mov     r4, r1
        mov     r7, #4
        add     r7, sp
        rdlong  r5, r7
        mov     r6, r5
        add     r6, #1
        wrlong  r6, r7
        add     r4, r5
        wrbyte  r3, r4

'         if (val == 10) break;
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #10
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0178
        jmp     #label0174

'     }
label0178

'     ubuf[index] = 0
        jmp     #label0173
label0174

'     if (index) return ubuf;
        mov     r3, #0
        mov     r4, r1
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        add     r4, r5
        wrbyte  r3, r4
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1

'     return 0;
        mov     r5, #0
        mov     r0, r5
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
' //{
' //  Permission is hereby granted, free of charge, to any person obtaining
' //  a copy of this software and associated documentation files
' //  (the "Software"), to deal in the Software without restriction,
' //  including without limitation the rights to use, copy, modify, merge,
' //  publish, distribute, sublicense, and/or sell copies of the Software,
' //  and to permit persons to whom the Software is furnished to do so,
' //  subject to the following conditions:
' //
' //  The above copyright notice and this permission notice shall be included
' //  in all copies or substantial portions of the Software.
' //
' //  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
' //  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
' //  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
' //  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
' //  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
' //  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
' //  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
' //}
' EOF

CON
  main = 0
