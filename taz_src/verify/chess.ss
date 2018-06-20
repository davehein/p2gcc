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
' //# This program implements the game of chess on the Parallax P2 processor.
' //#
' //# Copyright (c) 2013-2015, Dave Hein
' //# MIT Licensed
' //############################################################################
' 
' // The chess board state is maintained in a 160-byte character array that
' // contains the following informtion:
' 
' 
' 
' 
' 
' 
' 
' 
' 
' 
' 
' 
' 
' char *symbols;
symbols long 0

' 
' // Directions that the pieces can move
' int king_moves[8] = {11, 13, -13, -11, -1, 12, 1, -12};
king_moves long 11, 13, - 13, - 11, - 1, 12, 1, - 12

' int knight_moves[8] = {-23, -10, 14, 25, 23, 10, -14, -25};
knight_moves long - 23, - 10, 14, 25, 23, 10, - 14, - 25

' 
' // The piece values
' int values[] = { 0, 20, 64, 65, 100, 195, 10000, 0};
values long 0, 20, 64, 65, 100, 195, 10000, 0

' 
' // Pawn position values
' signed char pawn_values[] = {
pawn_values byte
'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 10, 10, 10, 10, 10, 10, 10, 10, 0, 0,
  byte 0, 0, 10, 10, 10, 10, 10, 10, 10, 10, 0, 0

'     0, 0, 2, 2, 4, 6, 6, 4, 2, 2, 0, 0,
  byte 0, 0, 2, 2, 4, 6, 6, 4, 2, 2, 0, 0

'     0, 0, 1, 1, 2, 6, 6, 2, 1, 1, 0, 0,
  byte 0, 0, 1, 1, 2, 6, 6, 2, 1, 1, 0, 0

'     0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0

'     0, 0, 1, -1, -2, 0, 0, -2, -1, 1, 0, 0,
  byte 0, 0, 1, - 1, - 2, 0, 0, - 2, - 1, 1, 0, 0

'     0, 0, 1, 2, 2, -5, -5, 2, 2, 1, 0, 0,
  byte 0, 0, 1, 2, 2, - 5, - 5, 2, 2, 1, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

' 
' // Knight position values
' signed char knight_values[] = {
knight_values byte
'     0, 0,-10, -8, -6, -6, -6, -6, -8,-10, 0, 0,
  byte 0, 0, - 10, - 8, - 6, - 6, - 6, - 6, - 8, - 10, 0, 0

'     0, 0, -8, -4, 0, 0, 0, 0, -4, -8, 0, 0,
  byte 0, 0, - 8, - 4, 0, 0, 0, 0, - 4, - 8, 0, 0

'     0, 0, -6, 0, 2, 3, 3, 2, 0, -6, 0, 0,
  byte 0, 0, - 6, 0, 2, 3, 3, 2, 0, - 6, 0, 0

'     0, 0, -6, 1, 3, 4, 4, 3, 1, -6, 0, 0,
  byte 0, 0, - 6, 1, 3, 4, 4, 3, 1, - 6, 0, 0

'     0, 0, -6, 0, 3, 4, 4, 3, 0, -6, 0, 0,
  byte 0, 0, - 6, 0, 3, 4, 4, 3, 0, - 6, 0, 0

'     0, 0, -6, 1, 2, 3, 3, 2, 1, -6, 0, 0,
  byte 0, 0, - 6, 1, 2, 3, 3, 2, 1, - 6, 0, 0

'     0, 0, -8, -4, 0, 1, 1, 0, -4, -8, 0, 0,
  byte 0, 0, - 8, - 4, 0, 1, 1, 0, - 4, - 8, 0, 0

'     0, 0,-10, -8, -4, -6, -6, -4, -8,-10, 0, 0};
  byte 0, 0, - 10, - 8, - 4, - 6, - 6, - 4, - 8, - 10, 0, 0

' 
' // Bishop position values
' signed char bishop_values[] = {
bishop_values byte
'     0, 0, -4, -2, -2, -2, -2, -2, -2, -4, 0, 0,
  byte 0, 0, - 4, - 2, - 2, - 2, - 2, - 2, - 2, - 4, 0, 0

'     0, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, 0,
  byte 0, 0, - 2, 0, 0, 0, 0, 0, 0, - 2, 0, 0

'     0, 0, -2, 0, 1, 2, 2, 1, 0, -2, 0, 0,
  byte 0, 0, - 2, 0, 1, 2, 2, 1, 0, - 2, 0, 0

'     0, 0, -2, 1, 1, 2, 2, 1, 1, -2, 0, 0,
  byte 0, 0, - 2, 1, 1, 2, 2, 1, 1, - 2, 0, 0

'     0, 0, -2, 0, 2, 2, 2, 2, 0, -2, 0, 0,
  byte 0, 0, - 2, 0, 2, 2, 2, 2, 0, - 2, 0, 0

'     0, 0, -2, 2, 2, 2, 2, 2, 2, -2, 0, 0,
  byte 0, 0, - 2, 2, 2, 2, 2, 2, 2, - 2, 0, 0

'     0, 0, -2, 1, 0, 0, 0, 0, 1, -2, 0, 0,
  byte 0, 0, - 2, 1, 0, 0, 0, 0, 1, - 2, 0, 0

'     0, 0, -4, -2, -8, -2, -2, -8, -2, -4, 0, 0};
  byte 0, 0, - 4, - 2, - 8, - 2, - 2, - 8, - 2, - 4, 0, 0

' 
' // King position values
' signed char king_values[] = {
king_values byte
'     0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
  byte 0, 0, - 6, - 8, - 8, - 10, - 10, - 8, - 8, - 6, 0, 0

'     0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
  byte 0, 0, - 6, - 8, - 8, - 10, - 10, - 8, - 8, - 6, 0, 0

'     0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
  byte 0, 0, - 6, - 8, - 8, - 10, - 10, - 8, - 8, - 6, 0, 0

'     0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
  byte 0, 0, - 6, - 8, - 8, - 10, - 10, - 8, - 8, - 6, 0, 0

'     0, 0, -4, -6, -6, -8, -8, -6, -6, -4, 0, 0,
  byte 0, 0, - 4, - 6, - 6, - 8, - 8, - 6, - 6, - 4, 0, 0

'     0, 0, -2, -4, -4, -4, -4, -4, -4, -2, 0, 0,
  byte 0, 0, - 2, - 4, - 4, - 4, - 4, - 4, - 4, - 2, 0, 0

'     0, 0, 4, 4, 0, 0, 0, 0, 4, 4, 0, 0,
  byte 0, 0, 4, 4, 0, 0, 0, 0, 4, 4, 0, 0

'     0, 0, 4, 6, 2, 0, 0, 2, 6, 4, 0, 0};
  byte 0, 0, 4, 6, 2, 0, 0, 2, 6, 4, 0, 0

' 
' // Null position values used for the queen and rooks
' signed char null_values[] = {
null_values byte
'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

' 
' signed char *pos_values[8] = { null_values, pawn_values, knight_values,
        alignl
pos_values long null_values, pawn_values, knight_values

' bishop_values, null_values, null_values, king_values, null_values};
  long bishop_values, null_values, null_values, king_values, null_values

' 
' unsigned char black_rank[8] = {4, 2, 3, 5, 6, 3, 2, 4};
black_rank byte 4, 2, 3, 5, 6, 3, 2, 4

' unsigned char white_rank[8] = {4 | 0x80, 2 | 0x80, 3 | 0x80,
white_rank byte 4 | $80, 2 | $80, 3 | $80

'     5 | 0x80, 6 | 0x80, 3 | 0x80, 2 | 0x80, 4 | 0x80};
  byte 5 | $80, 6 | $80, 3 | $80, 2 | $80, 4 | $80

' 
' // Global variables
' int MoveFunction;      // Function that is called for each move
        alignl
MoveFunction long 0

' int movenum;           // current move number
movenum long 0

' int person_old;        // postion selected by person to move from
person_old long 0

' int person_new;        // postion selected by person to move to
person_new long 0

' int playdepth;         // number of moves to look ahead
playdepth long 0

' int validmove;         // indicates if a human's move is valid
validmove long 0

' int compcolor;         // color that the computer is playing
compcolor long 0

' int human_playing;     // indicates that a person is playing
human_playing long 0

' char inbuf[80];        // buffer for human input
inbuf byte 0[80]

' char positionstr[3];   // Used by PositionToString
positionstr byte 0[3]

' 
' int PieceFunctions[8] = {0, 4, 5, 6, 7, 8, 9, 0};
        alignl
PieceFunctions long 0, 4, 5, 6, 7, 8, 9, 0

' 
' // Return the value of a piece at a particular position on the board
' int get_pos_value(int piece, int position)
_get_pos_value global
        sub     sp, #4
        wrlong  lr, sp

' {
'     signed char *ptr;
'     ptr = pos_values[piece];

        sub     sp, #4
        mov     r2, ##pos_values
        mov     r3, r0
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     return ptr[position];
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        shl     r2, #24
        sar     r2, #24
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
' // Prepare to search the next level
' void InitializeNextLevel(unsigned char *level, unsigned char *next_level)
_InitializeNextLevel global
        sub     sp, #4
        wrlong  lr, sp

' {
'     memcpy(next_level, level, 160);

        mov     r2, r1
        mov     r3, r0
        mov     r4, #160
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

'     next_level[149] = next_level[149] + 1;
        mov     r2, r1
        mov     r3, #149
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #1
        add     r2, r3
        mov     r3, r1
        mov     r4, #149
        add     r3, r4
        wrbyte  r2, r3

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void ChangeColor(unsigned char *level)
_ChangeColor global
        sub     sp, #4
        wrlong  lr, sp

' {
'     level[148] = level[148] ^ 0x80;

        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        xor     r1, r2
        mov     r2, r0
        mov     r3, #148
        add     r2, r3
        wrbyte  r1, r2

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int BoardValue(unsigned char *level)
_BoardValue global
        sub     sp, #4
        wrlong  lr, sp

' {
'     short *slevel;
'     slevel = level;

        sub     sp, #4
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     return slevel[144>>1];
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #144
        mov     r3, #1
        sar     r2, r3
        shl     r2, #1
        add     r1, r2
        rdword  r1, r1
        shl     r1, #16
        sar     r1, #16
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
' // Convert a numeric position value to a string
' char *PositionToString(int position)
_PositionToString global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int row, col;
'     row = position / 12;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #12
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        call    #__DIVSI
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     col = position % 12;
        mov     r1, r0
        mov     r2, #12
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        call    #__DIVSI
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     positionstr[0] = col - 2 + 'a';
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #2
        sub     r1, r2
        mov     r2, #97
        add     r1, r2
        mov     r2, ##positionstr
        mov     r3, #0
        add     r2, r3
        wrbyte  r1, r2

'     positionstr[1] = 10 - row + '0';
        mov     r1, #10
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     r1, r2
        mov     r2, #48
        add     r1, r2
        mov     r2, ##positionstr
        mov     r3, #1
        add     r2, r3
        wrbyte  r1, r2

'     positionstr[2] = 0;
        mov     r1, #0
        mov     r2, ##positionstr
        mov     r3, #2
        add     r2, r3
        wrbyte  r1, r2

'     return positionstr;
        mov     r1, ##positionstr
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
' // Convert a postion string to a numeric value
' int StringToPostion(char *str)
_StringToPostion global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned int col;
'     unsigned int row;
'     col = tolower(str[0]) - 'a';

        sub     sp, #8
        mov     r1, r0
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_tolower
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #97
        sub     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     row = str[1] - '1';
        mov     r1, r0
        mov     r2, #1
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #49
        sub     r1, r2
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (col > 7 || row > 7) return -1;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #7
        cmp     r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #7
        cmp     r3, r2 wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1
        cmp     r1, #0  wz
 if_z   jmp     #label0001
        mov     r1, #1
        neg     r1, r1
        mov     r0, r1
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return (7 - row + 2) * 12 + col + 2;
label0001
        mov     r1, #7
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        sub     r1, r2
        mov     r2, #2
        add     r1, r2
        mov     r2, #12
        qmul    r1, r2
        getqx   r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        mov     r2, #2
        add     r1, r2
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
' // Print the board
' void PrintBoard(unsigned char *level)
_PrintBoard global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i, j;
'     unsigned char *ptr;
'     ptr = level + (12 * 2);

        sub     sp, #12
        mov     r1, r0
        mov     r2, #12
        mov     r3, #2
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     printf("\n ");
        calld   lr, #label0003
        byte    10, " ", 0
        alignl
label0003
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     for (i = 'a'; i <= 'h'; i++) printf("|%c ", i);
        mov     r1, #97
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0004
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #104
        cmps    r2, r1 wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0006
        jmp     #label0007
label0005
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3
        jmp     #label0004
label0006
        calld   lr, #label0009
        byte    "|%c ", 0
        alignl
label0009
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

'     printf("|");
        jmp     #label0005
label0007
        calld   lr, #label0011
        byte    "|", 0
        alignl
label0011
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     for (i = 0; i < 8; i++)
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0012
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0014
        jmp     #label0015
label0013
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0012
label0014

'         printf("\n-+--+--+--+--+--+--+--+--+");
        calld   lr, #label0017
        byte    10, "-+--+--+--+--+--+--+--+--+", 0
        alignl
label0017
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         printf("\n%c", '8' - i);
        calld   lr, #label0019
        byte    10, "%c", 0
        alignl
label0019
        mov     r1, lr
        mov     r2, #56
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        sub     r2, r3
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

'         for (j = 2; j < 10; j++)
        mov     r1, #2
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2
label0020
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #10
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0022
        jmp     #label0023
label0021
        mov     r3, #4
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         {
        jmp     #label0020
label0022

'             if (ptr[j])
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0024

'                 printf("|%c", symbols[ptr[j] & 0x07]);
        calld   lr, #label0026
        byte    "|%c", 0
        alignl
label0026
        mov     r1, lr
        rdlong  r2, ##symbols
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #$07
        and     r3, r4
        add     r2, r3
        rdbyte  r2, r2
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

'                 if (ptr[j] & 0x80)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        and     r1, r2

'                     printf("W");
        cmp     r1, #0  wz
 if_z   jmp     #label0027
        calld   lr, #label0029
        byte    "W", 0
        alignl
label0029
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'                 else
'                     printf("B");
        jmp     #label0030
label0027
        calld   lr, #label0032
        byte    "B", 0
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

'             }
label0030

'             else if ((i^j)&1)
        jmp     #label0033
label0024
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        xor     r1, r2
        mov     r2, #1
        and     r1, r2

'                 printf("|--");
        cmp     r1, #0  wz
 if_z   jmp     #label0034
        calld   lr, #label0036
        byte    "|--", 0
        alignl
label0036
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'             else
'                 printf("|  ");
        jmp     #label0037
label0034
        calld   lr, #label0039
        byte    "|  ", 0
        alignl
label0039
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         }
label0037
label0033

'         printf("|");
        jmp     #label0021
label0023
        calld   lr, #label0041
        byte    "|", 0
        alignl
label0041
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         ptr += 12;
        mov     r1, #12
        mov     r2, #8
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'     }
'     printf("\n-+--+--+--+--+--+--+--+--+");
        jmp     #label0013
label0015
        calld   lr, #label0043
        byte    10, "-+--+--+--+--+--+--+--+--+", 0
        alignl
label0043
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     printf("\n\n");
        calld   lr, #label0045
        byte    10, 10, 0
        alignl
label0045
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Determine if the board position contains the current color's piece
' int IsMyPiece(unsigned char *level, int offs)
_IsMyPiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     brd = level;

        sub     sp, #4
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (brd[offs] == 0) return 0;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0046
        mov     r2, #0
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[offs] == 0xff) return 0;
label0046
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$ff
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0047
        mov     r2, #0
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return ((brd[offs] & 0x80) == level[148]);
label0047
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$80
        and     r2, r3
        mov     r3, r0
        mov     r4, #148
        add     r3, r4
        rdbyte  r3, r3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
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
' // Determine if the board position contains the other color's piece
' int IsOtherPiece(unsigned char *level, int offs)
_IsOtherPiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     brd = level;

        sub     sp, #4
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     if (brd[offs] == 0) return 0;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0048
        mov     r2, #0
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[offs] == 0xff) return 0;
label0048
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$ff
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0049
        mov     r2, #0
        mov     r0, r2
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     return ((brd[offs] & 0x80) != level[148]);
label0049
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$80
        and     r2, r3
        mov     r3, r0
        mov     r4, #148
        add     r3, r4
        rdbyte  r3, r3
        sub     r2, r3  wz
 if_nz  mov     r2, #1
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
' // Determine if the board position does not contain the
' // current color's piece and is in bounds.
' int IsMoveOK(unsigned char *level, int offs)
_IsMoveOK global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     brd = level;

        sub     sp, #4
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     return (!IsMyPiece(level, offs) && brd[offs] != 0xff);
        mov     r2, r0
        mov     r3, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_IsMyPiece
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #$ff
        sub     r3, r4  wz
 if_nz  mov     r3, #1
        cmp     r2, #0  wz
 if_nz  cmp     r3, #0  wz
 if_nz  mov     r2, #1
 if_z   mov     r2, #0
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
' // Generate moves in a certain direction for a bishop, rook or queen
' void AnalyzeDirectionalMoves(unsigned char *level, int direction)
_AnalyzeDirectionalMoves global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     brd = level;

        sub     sp, #4
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     level[151] = level[150];
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        wrbyte  r2, r3

'     while (1)
label0050
        mov     r2, #1

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0051

'         //level[151] += direction;
'         level[151] = level[151] + direction;
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r1
        add     r2, r3
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        wrbyte  r2, r3

'         if (IsMyPiece(level, level[151]) || brd[level[151]] == 0xff) break;
        mov     r2, r0
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_IsMyPiece
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r0
        mov     r5, #151
        add     r4, r5
        rdbyte  r4, r4
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #$ff
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        or      r2, r3  wz
 if_nz  mov     r2, #1
        cmp     r2, #0  wz
 if_z   jmp     #label0052
        jmp     #label0051

'         CallMoveFunction(MoveFunction, level);
label0052
        rdlong  r2, ##MoveFunction
        mov     r3, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_CallMoveFunction
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'         if (brd[level[151]] != 0) break;
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #0
        sub     r2, r3  wz
 if_nz  mov     r2, #1
        cmp     r2, #0  wz
 if_z   jmp     #label0053
        jmp     #label0051

'     }
label0053

' }
        jmp     #label0050
label0051
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Determine if the king's space is under attack
' int IsCheck(unsigned char *level)
_IsCheck global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int color;
'     unsigned char *king_ptr;
'     int i, row_step, offs, incr, flags, piece;
'     color = level[148];

        sub     sp, #32
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     king_ptr = level;
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (color)
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0054

'         row_step = -12;
        mov     r1, #12
        neg     r1, r1
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'         king_ptr += level[154];
        mov     r1, r0
        mov     r2, #154
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'     }
'     else
'     {
        jmp     #label0055
label0054

'         row_step = 12;
        mov     r1, #12
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'         king_ptr += level[155];
        mov     r1, r0
        mov     r2, #155
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'     }
'     color ^= 0x80;
label0055
        mov     r1, #$80
        mov     r2, #0
        add     r2, sp
        rdlong  r3, r2
        xor     r1, r3
        wrlong  r1, r2

'     // Check for pawns
'     if ((king_ptr[row_step + 1] & (0x80 | 0x07)) == (color | 1))
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        add     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        mov     r3, #$07
        or      r2, r3
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        or      r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0056
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if ((king_ptr[row_step - 1] & (0x80 | 0x07)) == (color | 1))
label0056
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        sub     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        mov     r3, #$07
        or      r2, r3
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        or      r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0057
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     // Check for knights
'     for (i = 0; i < 8; i++)
label0057
        mov     r1, #0
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2
label0058
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0060
        jmp     #label0061
label0059
        mov     r3, #8
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0058
label0060

'         if ((king_ptr[knight_moves[i]] & (0x80 | 0x07)) == (color | 2))
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, ##knight_moves
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        mov     r3, #$07
        or      r2, r3
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #2
        or      r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0062
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
label0062

'     // Check for king, queen, bishop or rook
'     for (i = 0; i < 8; i++)
        jmp     #label0059
label0061
        mov     r1, #0
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2
label0063
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0065
        jmp     #label0066
label0064
        mov     r3, #8
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0063
label0065

'         offs = incr = king_moves[i];
        mov     r1, ##king_moves
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #20
        add     r2, sp
        wrlong  r1, r2
        mov     r2, #16
        add     r2, sp
        wrlong  r1, r2

'         if ((king_ptr[offs] & (0x80 | 0x07)) == (color | 6))
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$80
        mov     r3, #$07
        or      r2, r3
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #6
        or      r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0067
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         while (king_ptr[offs] == 0)
label0067
label0068
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             offs += incr;
        cmp     r1, #0  wz
 if_z   jmp     #label0069
        mov     r1, #20
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #16
        add     r2, sp
        rdlong  r3, r2
        add     r1, r3
        wrlong  r1, r2

'         flags = king_ptr[offs];
        jmp     #label0068
label0069
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #24
        add     r2, sp
        wrlong  r1, r2

'         if ((flags & 0x80) != color)
        mov     r1, #24
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$80
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        sub     r1, r2  wz
 if_nz  mov     r1, #1

'             continue;
        cmp     r1, #0  wz
 if_z   jmp     #label0070
        jmp     #label0064

'         piece = flags & 0x07;
label0070
        mov     r1, #24
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$07
        and     r1, r2
        mov     r2, #28
        add     r2, sp
        wrlong  r1, r2

'         if (piece == 5)
        mov     r1, #28
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #5
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0071
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         if (i < 4)
label0071
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0072

'             if (piece == 3)
        mov     r1, #28
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'                 return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0073
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         }
label0073

'         else
'         {
        jmp     #label0074
label0072

'             if (piece == 4)
        mov     r1, #28
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'                 return 1;
        cmp     r1, #0  wz
 if_z   jmp     #label0075
        mov     r1, #1
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         }
label0075

'     }
label0074

'     return 0;
        jmp     #label0064
label0066
        mov     r1, #0
        mov     r0, r1
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #32
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // This routine catches invalid piece values, and should never be called
' void Invalid(unsigned char *level)
_Invalid global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("Invalid piece\n");

        calld   lr, #label0077
        byte    "Invalid piece", 10, 0
        alignl
label0077
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
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
' // Generate all possible moves for a pawn
' void Pawn(unsigned char *level)
_Pawn    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int row_step;
'     unsigned char *brd;
'     row_step = 12;

        sub     sp, #8
        mov     r1, #12
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     brd = level;
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'         row_step = -12;
        cmp     r1, #0  wz
 if_z   jmp     #label0078
        mov     r1, #12
        neg     r1, r1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     // Check capture to the left
'     level[151] = level[150] - 1 + row_step;
label0078
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #1
        sub     r1, r2
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     if (IsOtherPiece(level, level[151]) || level[156] == level[150] - 1)
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsOtherPiece
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #150
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #1
        sub     r3, r4
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0079

'         CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'     }
'     // Check capture to the right
'     //level[151] += 2;
'     level[151] = level[151] + 2;
label0079
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     if (IsOtherPiece(level, level[151]) || level[156] == level[150] + 1)
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsOtherPiece
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #150
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #1
        add     r3, r4
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0080

'         CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'     }
'     // Check moving forward one space
'     //level[151] -= 1;
'     level[151] = level[151] - 1;
label0080
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #1
        sub     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     if (IsMoveOK(level, level[151]) && !IsOtherPiece(level, level[151]))
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsMoveOK
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_IsOtherPiece
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0081

'         CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'     }
'     else
'         return;
        jmp     #label0082
label0081
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[level[150]] & 0x40)
label0082
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$40
        and     r1, r2

'         return;
        cmp     r1, #0  wz
 if_z   jmp     #label0083
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     // Check moving forward two spaces
'     //level[151] += row_step;
'     level[151] = level[151] + row_step;
label0083
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     if (IsMoveOK(level, level[151]) && !IsOtherPiece(level, level[151]))
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsMoveOK
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, r0
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_IsOtherPiece
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        cmp     r2, #0  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0084

'         CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'     }
' }
label0084
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all possible moves for a knight
' void Knight(unsigned char *level)
_Knight  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     unsigned char *brd;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     for (i = 0; i < 8; i++)
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0085
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0087
        jmp     #label0088
label0086
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0085
label0087

'         level[151] = level[150] + knight_moves[i];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, ##knight_moves
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'         if (IsMoveOK(level, level[151]))
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsMoveOK
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0089

'             CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'         }
'     }
label0089

' }
        jmp     #label0086
label0088
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all possible moves for a bishop
' void Bishop(unsigned char *level)
_Bishop  global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     for (i = 0; i < 4; i++)

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0090
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0092
        jmp     #label0093
label0091
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         AnalyzeDirectionalMoves(level, king_moves[i]);
        jmp     #label0090
label0092
        mov     r1, r0
        mov     r2, ##king_moves
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_AnalyzeDirectionalMoves
        rdlong  r0, sp
        add     sp, #4

' }
        jmp     #label0091
label0093
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all possible moves for a rook
' void Rook(unsigned char *level)
_Rook    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     unsigned char *brd;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     for (i = 4; i < 8; i++)
        mov     r1, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0094
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0096
        jmp     #label0097
label0095
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         AnalyzeDirectionalMoves(level, king_moves[i]);
        jmp     #label0094
label0096
        mov     r1, r0
        mov     r2, ##king_moves
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_AnalyzeDirectionalMoves
        rdlong  r0, sp
        add     sp, #4

' }
        jmp     #label0095
label0097
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all possible moves for a queen
' void Queen(unsigned char *level)
_Queen   global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     for (i = 0; i < 8; i++)

        sub     sp, #4
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0098
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0100
        jmp     #label0101
label0099
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         AnalyzeDirectionalMoves(level, king_moves[i]);
        jmp     #label0098
label0100
        mov     r1, r0
        mov     r2, ##king_moves
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_AnalyzeDirectionalMoves
        rdlong  r0, sp
        add     sp, #4

' }
        jmp     #label0099
label0101
        add     sp, #4
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Determine if this space is under attack
' int IsSpaceUnderAttack(unsigned char *level, int position)
_IsSpaceUnderAttack global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int retval, king_pos;
'     if (level[148])

        sub     sp, #8
        mov     r2, r0
        mov     r3, #148
        add     r2, r3
        rdbyte  r2, r2

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0102

'         king_pos = level[154];
        mov     r2, r0
        mov     r3, #154
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         level[154] = position;
        mov     r2, r1
        mov     r3, r0
        mov     r4, #154
        add     r3, r4
        wrbyte  r2, r3

'         retval = IsCheck(level);
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_IsCheck
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'         level[154] = king_pos;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #154
        add     r3, r4
        wrbyte  r2, r3

'     }
'     else
'     {
        jmp     #label0103
label0102

'         king_pos = level[155];
        mov     r2, r0
        mov     r3, #155
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'         level[155] = position;
        mov     r2, r1
        mov     r3, r0
        mov     r4, #155
        add     r3, r4
        wrbyte  r2, r3

'         retval = IsCheck(level);
        mov     r2, r0
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_IsCheck
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'         level[155] = king_pos;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #155
        add     r3, r4
        wrbyte  r2, r3

'     }
'     return retval;
label0103
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
' void CastleRight(unsigned char *level)
_CastleRight global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int old_pos;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     old_pos = level[150];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (brd[old_pos + 1]) return;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        add     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0104
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[old_pos + 2]) return;
label0104
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #2
        add     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0105
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[old_pos + 3] & 0x40) return;
label0105
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #3
        add     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$40
        and     r1, r2
        cmp     r1, #0  wz
 if_z   jmp     #label0106
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (IsCheck(level)) return;
label0106
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_IsCheck
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0107
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (IsSpaceUnderAttack(level, level[150] + 1)) return;
label0107
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #1
        add     r2, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsSpaceUnderAttack
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0108
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     level[151] = level[150] + 2;
label0108
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void CastleLeft(unsigned char *level)
_CastleLeft global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int old_pos;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     old_pos = level[150];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (brd[old_pos - 1]) return;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #1
        sub     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0109
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[old_pos - 2]) return;
label0109
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #2
        sub     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0110
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[old_pos - 3]) return;
label0110
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #3
        sub     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0111
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (brd[old_pos - 4] & 0x40) return;
label0111
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #4
        sub     r2, r3
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$40
        and     r1, r2
        cmp     r1, #0  wz
 if_z   jmp     #label0112
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (IsCheck(level)) return;
label0112
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_IsCheck
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0113
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (IsSpaceUnderAttack(level, level[150] - 1)) return;
label0113
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #1
        sub     r2, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsSpaceUnderAttack
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0114
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     level[151] = level[150] - 2;
label0114
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #2
        sub     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'     CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all possible moves for a king
' void King(unsigned char *level)
_King    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int i;
'     unsigned char *brd;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     // Check 8 single-space moves
'     for (i = 0; i < 8; i++)
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0115
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0117
        jmp     #label0118
label0116
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0115
label0117

'         level[151] = level[150] + king_moves[i];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, ##king_moves
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'         if (IsMoveOK(level, level[151]))
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsMoveOK
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0119

'             CallMoveFunction(MoveFunction, level);
        rdlong  r1, ##MoveFunction
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'         }
'     }
label0119

'     // Check castling
'     if (!(brd[level[150]] & 0x40))
        jmp     #label0116
label0118
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$40
        and     r1, r2
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0120

'         CastleRight(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_CastleRight
        rdlong  r0, sp
        add     sp, #4

'         CastleLeft(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_CastleLeft
        rdlong  r0, sp
        add     sp, #4

'     }
' }
label0120
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Call the piece move generator function if this the color is correct
' void MoveIfMyPiece(unsigned char *level)
_MoveIfMyPiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int piece;
'     unsigned char *brd;
'     brd = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     if (IsMyPiece(level, level[150]))
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_IsMyPiece
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0121

'         piece = brd[level[150]] & 0x07;
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$07
        and     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'         CallMoveFunction(PieceFunctions[piece], level);
        mov     r1, ##PieceFunctions
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_CallMoveFunction
        rdlong  r0, sp
        add     sp, #4

'     }
' }
label0121
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Generate all moves on the board and analyze them
' void AnalyzeAllMoves(unsigned char *level)
_AnalyzeAllMoves global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int row, col, rowinc;
'     if (level[148] == 0x00)

        sub     sp, #12
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$00
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0122

'         level[150] = ((12 * 2) + 2); // start at the left top
        mov     r1, #12
        mov     r2, #2
        qmul    r1, r2
        getqx   r1
        mov     r2, #2
        add     r1, r2
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'         rowinc = 12 - 8;
        mov     r1, #12
        mov     r2, #8
        sub     r1, r2
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     }
'     else
'     {
        jmp     #label0123
label0122

'         level[150] = ((12 * 9) + 2); // start at the left bottom
        mov     r1, #12
        mov     r2, #9
        qmul    r1, r2
        getqx   r1
        mov     r2, #2
        add     r1, r2
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'         rowinc = -12 - 8;
        mov     r1, #12
        neg     r1, r1
        mov     r2, #8
        sub     r1, r2
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     }
'     for (row = 0; row < 8; row++)
label0123
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2
label0124
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0126
        jmp     #label0127
label0125
        mov     r3, #0
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'     {
        jmp     #label0124
label0126

'         for (col = 0; col < 8; col++)
        mov     r1, #0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2
label0128
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #8
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        cmp     r1, #0  wz
 if_nz  jmp     #label0130
        jmp     #label0131
label0129
        mov     r3, #4
        add     r3, sp
        rdlong  r1, r3
        add     r1, #1
        wrlong  r1, r3

'         {
        jmp     #label0128
label0130

'             MoveIfMyPiece(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_MoveIfMyPiece
        rdlong  r0, sp
        add     sp, #4

'             //level[150] += 1;
'             level[150] = level[150] + 1;
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #1
        add     r1, r2
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'         }
'         //level[150] += rowinc;
'         level[150] = level[150] + rowinc;
        jmp     #label0129
label0131
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        add     r1, r2
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'     }
' }
        jmp     #label0125
label0127
        add     sp, #12
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Remove a piece from the board and subtract its value
' void RemovePiece(unsigned char *level, int position)
_RemovePiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int entry;
'     int piece;
'     int value;
'     short *slevel;
'     brd = level;

        sub     sp, #20
        mov     r2, r0
        mov     r3, #0
        add     r3, sp
        wrlong  r2, r3

'     entry = brd[position];
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        add     r3, sp
        wrlong  r2, r3

'     piece = entry & 0x07;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$07
        and     r2, r3
        mov     r3, #8
        add     r3, sp
        wrlong  r2, r3

'     value = values[piece];
        mov     r2, ##values
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3
        shl     r3, #2
        add     r2, r3
        rdlong  r2, r2
        mov     r3, #12
        add     r3, sp
        wrlong  r2, r3

'     slevel = level;
        mov     r2, r0
        mov     r3, #16
        add     r3, sp
        wrlong  r2, r3

'     if (entry == 0) return;
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #0
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r2, #0  wz
 if_z   jmp     #label0132
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (entry == 0xff)
label0132
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$ff
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0133

'         printf("RemovePiece: %d is out of bounds\n", position);
        calld   lr, #label0135
        byte    "RemovePiece: %d is out of bounds", 10, 0
        alignl
label0135
        mov     r2, lr
        mov     r3, r1
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

'         exit(1);
        mov     r2, #1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_exit
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     }
'     if (entry & 0x80)
label0133
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$80
        and     r2, r3

'     {
        cmp     r2, #0  wz
 if_z   jmp     #label0136

'         //value += pos_values[piece][position - (2 * 12)];
'         value += get_pos_value(piece, position - (2 * 12));
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r1
        mov     r4, #2
        mov     r5, #12
        qmul    r4, r5
        getqx   r4
        sub     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_get_pos_value
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #12
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'         //slevel[144>>1] -= value;
'         slevel[144>>1] = slevel[144>>1] - value;
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #144
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        sub     r2, r3
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #144
        mov     r5, #1
        sar     r4, r5
        shl     r4, #1
        add     r3, r4
        wrword  r2, r3

'     }
'     else
'     {
        jmp     #label0137
label0136

'         //value += pos_values[piece][(12 * 10) - 1 - position];
'         value += get_pos_value(piece, (12 * 10) - 1 - position);
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #12
        mov     r4, #10
        qmul    r3, r4
        getqx   r3
        mov     r4, #1
        sub     r3, r4
        mov     r4, r1
        sub     r3, r4
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        mov     r1, r3
        calld   lr, #_get_pos_value
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
        mov     r3, #12
        add     r3, sp
        rdlong  r4, r3
        add     r2, r4
        wrlong  r2, r3

'         //slevel[144>>1] += value;
'         slevel[144>>1] = slevel[144>>1] + value;
        mov     r2, #16
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #144
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        add     r2, r3
        mov     r3, #16
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #144
        mov     r5, #1
        sar     r4, r5
        shl     r4, #1
        add     r3, r4
        wrword  r2, r3

'     }
'     brd[position] = 0;
label0137
        mov     r2, #0
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        add     r3, r4
        wrbyte  r2, r3

' }
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Add a piece to the board and add its value
' void AddPiece(unsigned char *level, int position, int entry)
_AddPiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int piece;
'     int value;
'     short *slevel;
'     brd = level;

        sub     sp, #16
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     piece = entry & 0x07;
        mov     r3, r2
        mov     r4, #$07
        and     r3, r4
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     value = values[piece];
        mov     r3, ##values
        mov     r4, #4
        add     r4, sp
        rdlong  r4, r4
        shl     r4, #2
        add     r3, r4
        rdlong  r3, r3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     slevel = level;
        mov     r3, r0
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'     if (brd[position])
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        add     r3, r4
        rdbyte  r3, r3

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0138

'         printf("AddPiece: %d occupied\n", position);
        calld   lr, #label0140
        byte    "AddPiece: %d occupied", 10, 0
        alignl
label0140
        mov     r3, lr
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r4, sp
        sub     sp, #4
        wrlong  r3, sp
        calld   lr, #_printf
        add     sp, #8
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'         exit(1);
        mov     r3, #1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_exit
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     }
'     if (brd[position])
label0138
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        add     r3, r4
        rdbyte  r3, r3

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0141

'         printf("RemovePiece: %d is out of bounds\n", position);
        calld   lr, #label0143
        byte    "RemovePiece: %d is out of bounds", 10, 0
        alignl
label0143
        mov     r3, lr
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r4, sp
        sub     sp, #4
        wrlong  r3, sp
        calld   lr, #_printf
        add     sp, #8
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'         exit(1);
        mov     r3, #1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_exit
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     }
'     if (entry & 0x80)
label0141
        mov     r3, r2
        mov     r4, #$80
        and     r3, r4

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0144

'         //value += pos_values[piece][position - (2 * 12)];
'         value += get_pos_value(piece, position - (2 * 12));
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        mov     r5, #2
        mov     r6, #12
        qmul    r5, r6
        getqx   r5
        sub     r4, r5
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_get_pos_value
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        rdlong  r5, r4
        add     r3, r5
        wrlong  r3, r4

'         //slevel[144>>1] += value;
'         slevel[144>>1] = slevel[144>>1] + value;
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #144
        mov     r5, #1
        sar     r4, r5
        shl     r4, #1
        add     r3, r4
        rdword  r3, r3
        shl     r3, #16
        sar     r3, #16
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        add     r3, r4
        mov     r4, #12
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #144
        mov     r6, #1
        sar     r5, r6
        shl     r5, #1
        add     r4, r5
        wrword  r3, r4

'     }
'     else
'     {
        jmp     #label0145
label0144

'         //value += pos_values[piece][(12 * 10) - 1 - position];
'         value += get_pos_value(piece, (12 * 10) - 1 - position);
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #12
        mov     r5, #10
        qmul    r4, r5
        getqx   r4
        mov     r5, #1
        sub     r4, r5
        mov     r5, r1
        sub     r4, r5
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_get_pos_value
        mov     r3, r0
        setq    #2
        rdlong  r0, sp
        add     sp, #12
        mov     r4, #8
        add     r4, sp
        rdlong  r5, r4
        add     r3, r5
        wrlong  r3, r4

'         //slevel[144>>1] -= value;
'         slevel[144>>1] = slevel[144>>1] - value;
        mov     r3, #12
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #144
        mov     r5, #1
        sar     r4, r5
        shl     r4, #1
        add     r3, r4
        rdword  r3, r3
        shl     r3, #16
        sar     r3, #16
        mov     r4, #8
        add     r4, sp
        rdlong  r4, r4
        sub     r3, r4
        mov     r4, #12
        add     r4, sp
        rdlong  r4, r4
        mov     r5, #144
        mov     r6, #1
        sar     r5, r6
        shl     r5, #1
        add     r4, r5
        wrword  r3, r4

'     }
'     brd[position] = entry | 0x40;
label0145
        mov     r3, r2
        mov     r4, #$40
        or      r3, r4
        mov     r4, #0
        add     r4, sp
        rdlong  r4, r4
        mov     r5, r1
        add     r4, r5
        wrbyte  r3, r4

' }
        add     sp, #16
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Move a piece from one place to another and adjust the board's value
' void MovePiece(unsigned char *level, int old_pos, int new_pos)
_MovePiece global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int entry1;
'     int entry2;
'     int piece;
'     int value;
'     short *slevel;
'     slevel = level;

        sub     sp, #24
        mov     r3, r0
        mov     r4, #20
        add     r4, sp
        wrlong  r3, r4

'     brd = level;
        mov     r3, r0
        mov     r4, #0
        add     r4, sp
        wrlong  r3, r4

'     entry1 = brd[old_pos];
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r1
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #4
        add     r4, sp
        wrlong  r3, r4

'     entry2 = brd[new_pos];
        mov     r3, #0
        add     r3, sp
        rdlong  r3, r3
        mov     r4, r2
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #8
        add     r4, sp
        wrlong  r3, r4

'     piece = entry1 & 0x07;
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #$07
        and     r3, r4
        mov     r4, #12
        add     r4, sp
        wrlong  r3, r4

'     //printf("MovePiece: %d from", piece);
'     //printf(" %s to", PositionToString(old_pos));
'     //printf(" %s - ", PositionToString(new_pos));
'     if (entry1 == 0) return;
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #0
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0
        cmp     r3, #0  wz
 if_z   jmp     #label0146
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     if (entry1 == 0xff)
label0146
        mov     r3, #4
        add     r3, sp
        rdlong  r3, r3
        mov     r4, #$ff
        cmp     r3, r4  wz
 if_z   mov     r3, #1
 if_nz  mov     r3, #0

'     {
        cmp     r3, #0  wz
 if_z   jmp     #label0147

'         printf("MovePiece: %d is out of bounds\n", old_pos);
        calld   lr, #label0149
        byte    "MovePiece: %d is out of bounds", 10, 0
        alignl
label0149
        mov     r3, lr
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r4, sp
        sub     sp, #4
        wrlong  r3, sp
        calld   lr, #_printf
        add     sp, #8
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'         exit(1);
        mov     r3, #1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        calld   lr, #_exit
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     }
'     if (entry2)
label0147
        mov     r3, #8
        add     r3, sp
        rdlong  r3, r3

'         RemovePiece(level, new_pos);
        cmp     r3, #0  wz
 if_z   jmp     #label0150
        mov     r3, r0
        mov     r4, r2
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_RemovePiece
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     RemovePiece(level, old_pos);
label0150
        mov     r3, r0
        mov     r4, r1
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        calld   lr, #_RemovePiece
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     AddPiece(level, new_pos, entry1);
        mov     r3, r0
        mov     r4, r2
        mov     r5, #4
        add     r5, sp
        rdlong  r5, r5
        sub     sp, #12
        setq    #2
        wrlong  r0, sp
        mov     r0, r3
        mov     r1, r4
        mov     r2, r5
        calld   lr, #_AddPiece
        setq    #2
        rdlong  r0, sp
        add     sp, #12

'     //printf("%d\n", slevel[144>>1]);
' }
        add     sp, #24
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Move a piece and remove an opponent's piece if taken
' // Check for castling, en passant capture and pawn promotion
' void PerformMove(unsigned char *level)
_PerformMove global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *brd;
'     int val1;
'     int val2;
'     int en_passant;
'     int value;
'     brd = level;

        sub     sp, #20
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     val1 = brd[level[150]];
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     val2 = brd[level[151]];
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     en_passant = level[156];
        mov     r1, r0
        mov     r2, #156
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #12
        add     r2, sp
        wrlong  r1, r2

'     value = values[val2 & 0x07];
        mov     r1, ##values
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #$07
        and     r2, r3
        shl     r2, #2
        add     r1, r2
        rdlong  r1, r1
        mov     r2, #16
        add     r2, sp
        wrlong  r1, r2

' 
'     // Clear en_passant flag.  May be set later.
'     level[156] = 0;
        mov     r1, #0
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        wrbyte  r1, r2

' 
'     // Check if taking opponent's piece
'     if (val2) RemovePiece(level, level[151]);
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        cmp     r1, #0  wz
 if_z   jmp     #label0151
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_RemovePiece
        rdlong  r0, sp
        add     sp, #4

' 
'     // Check if moving king
'     if ((val1 & 0x07) == 6)
label0151
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$07
        and     r1, r2
        mov     r2, #6
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0152

'         // Update it's position
'         if (val1 & 0x80)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$80
        and     r1, r2

'             level[154] = level[151];
        cmp     r1, #0  wz
 if_z   jmp     #label0153
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #154
        add     r2, r3
        wrbyte  r1, r2

'         else
'             level[155] = level[151];
        jmp     #label0154
label0153
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #155
        add     r2, r3
        wrbyte  r1, r2

'         // Check for castle right
'         if (level[151] == level[150] + 2)
label0154
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #2
        add     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0155

'             if (level[149] == 0) printf("CASTLE RIGHT\n\n");
        mov     r1, r0
        mov     r2, #149
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0156
        calld   lr, #label0158
        byte    "CASTLE RIGHT", 10, 10, 0
        alignl
label0158
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'             MovePiece(level, level[150] + 3, level[150] + 1);
label0156
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #3
        add     r2, r3
        mov     r3, r0
        mov     r4, #150
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #1
        add     r3, r4
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_MovePiece
        rdlong  r0, sp
        add     sp, #4

'         }
'         // Check for castle left
'         if (level[151] == level[150] - 2)
label0155
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #2
        sub     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0159

'             if (level[149] == 0) printf("CASTLE LEFT\n\n");
        mov     r1, r0
        mov     r2, #149
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0160
        calld   lr, #label0162
        byte    "CASTLE LEFT", 10, 10, 0
        alignl
label0162
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'             MovePiece(level, level[150] - 4, level[150] - 1);
label0160
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #4
        sub     r2, r3
        mov     r3, r0
        mov     r4, #150
        add     r3, r4
        rdbyte  r3, r3
        mov     r4, #1
        sub     r3, r4
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_MovePiece
        rdlong  r0, sp
        add     sp, #4

'         }
'     }
label0159

' 
'     // Check if moving pawn
'     if ((val1 & 0x07) == 1)
label0152
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$07
        and     r1, r2
        mov     r2, #1
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0163

'         if (val1 & 0x80)
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #$80
        and     r1, r2

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0164

'             // Set the en passant flag if moving pawn two spaces
'             if (level[151] == level[150] - (2 * 12))
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #2
        mov     r4, #12
        qmul    r3, r4
        getqx   r3
        sub     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0165

'                 level[156] = level[151];
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        wrbyte  r1, r2

'             }
'             // Check for en passant capture
'             else if (level[151] == en_passant - 12)
        jmp     #label0166
label0165
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #12
        sub     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0167

'                 if (level[149] == 0) printf("EN PASSANT\n\n");
        mov     r1, r0
        mov     r2, #149
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0168
        calld   lr, #label0170
        byte    "EN PASSANT", 10, 10, 0
        alignl
label0170
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'                 RemovePiece(level, en_passant);
label0168
        mov     r1, r0
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_RemovePiece
        rdlong  r0, sp
        add     sp, #4

'             }
'             // Promote pawn to queen if reaching final rank
'             else if (level[151] <= ((12 * 2) + 9))
        jmp     #label0171
label0167
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #12
        mov     r3, #2
        qmul    r2, r3
        getqx   r2
        mov     r3, #9
        add     r2, r3
        cmps    r2, r1 wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0172

'                 RemovePiece(level, level[150]);
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_RemovePiece
        rdlong  r0, sp
        add     sp, #4

'                 AddPiece(level, level[151], 0x80 | 5);
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$80
        mov     r4, #5
        or      r3, r4
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_AddPiece
        rdlong  r0, sp
        add     sp, #4

'                 return;
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0172
label0171
label0166

'         else
'         {
        jmp     #label0173
label0164

'             // Set the en passant flag if moving pawn two spaces
'             if (level[151] == level[150] + (2 * 12))
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #2
        mov     r4, #12
        qmul    r3, r4
        getqx   r3
        add     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0174

'                 level[156] = level[151];
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        wrbyte  r1, r2

'             }
'             // Check for en passant capture
'             else if (level[151] == en_passant + 12)
        jmp     #label0175
label0174
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #12
        add     r2, r3
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0176

'                 if (level[149] == 0) printf("EN PASSANT\n\n");
        mov     r1, r0
        mov     r2, #149
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0177
        calld   lr, #label0179
        byte    "EN PASSANT", 10, 10, 0
        alignl
label0179
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'                 RemovePiece(level, en_passant);
label0177
        mov     r1, r0
        mov     r2, #12
        add     r2, sp
        rdlong  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_RemovePiece
        rdlong  r0, sp
        add     sp, #4

'             }
'             // Promote pawn to queen if reaching final rank
'             else if (level[151] >= ((12 * 9) + 2))
        jmp     #label0180
label0176
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #12
        mov     r3, #9
        qmul    r2, r3
        getqx   r2
        mov     r3, #2
        add     r2, r3
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0181

'                 RemovePiece(level, level[150]);
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_RemovePiece
        rdlong  r0, sp
        add     sp, #4

'                 AddPiece(level, level[151], 0x00 | 5);
        mov     r1, r0
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$00
        mov     r4, #5
        or      r3, r4
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_AddPiece
        rdlong  r0, sp
        add     sp, #4

'                 return;
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'             }
'         }
label0181
label0180
label0175

'     }
label0173

'     MovePiece(level, level[150], level[151]);
label0163
        mov     r1, r0
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_MovePiece
        rdlong  r0, sp
        add     sp, #4

' }
        add     sp, #20
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Analyze move from old_pos to new_pos.  If we have reached the maximum depth
' // check if the board value is better than the values from the previous moves.
' // If we have not reached the maximum depth, determine the best counter-move
' // at the next level, and check if better than any previous move.
' // In the case of a tie, pick the new move 25% of the time.
' void AnalyzeMove(unsigned char *level)
_AnalyzeMove global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char next_level[160];
'     int update, value;
'     unsigned char *ptr;
'     short *slevel;
'     short *snext_level;
'     ptr = level;

        sub     sp, #180
        mov     r1, r0
        mov     r2, #168
        add     r2, sp
        wrlong  r1, r2

'     slevel = level;
        mov     r1, r0
        mov     r2, #172
        add     r2, sp
        wrlong  r1, r2

'     snext_level = next_level;
        mov     r1, #0
        add     r1, sp
        mov     r2, #176
        add     r2, sp
        wrlong  r1, r2

' 
'     if (ptr[level[150]] == 0xff || ptr[level[151]] == 0xff)
        mov     r1, #168
        add     r1, sp
        rdlong  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$ff
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        mov     r2, #168
        add     r2, sp
        rdlong  r2, r2
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #$ff
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0182

'         printf("BAD MOVE: %2.2x-%2.2x\n", level[150], level[151]);
        calld   lr, #label0184
        byte    "BAD MOVE: %2.2x-%2.2x", 10, 0
        alignl
label0184
        mov     r1, lr
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
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

'         exit(0);
        mov     r1, #0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_exit
        rdlong  r0, sp
        add     sp, #4

'     }
' 
'     InitializeNextLevel(level, next_level);
label0182
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_InitializeNextLevel
        rdlong  r0, sp
        add     sp, #4

'     PerformMove(next_level);
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_PerformMove
        rdlong  r0, sp
        add     sp, #4

'     if (IsCheck(next_level)) return;
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_IsCheck
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   jmp     #label0185
        add     sp, #180
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     value = BoardValue(next_level);
label0185
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_BoardValue
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #164
        add     r2, sp
        wrlong  r1, r2

' 
'     // Stop searching if checkmate
'     if (value > 5000 || value < -5000)
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, ##5000
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #164
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##5000
        neg     r3, r3
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0186

'         slevel[146>>1] = value;
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'         level[152] = level[150];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'         level[153] = level[151];
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'     }
'     else if (next_level[149] == playdepth)
        jmp     #label0187
label0186
        mov     r1, #0
        add     r1, sp
        mov     r2, #149
        add     r1, r2
        rdbyte  r1, r1
        rdlong  r2, ##playdepth
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0188

'         if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'             update = (value > slevel[146>>1]);
        cmp     r1, #0  wz
 if_z   jmp     #label0189
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #160
        add     r2, sp
        wrlong  r1, r2

'         else
'             update = (value < slevel[146>>1]);
        jmp     #label0190
label0189
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #160
        add     r2, sp
        wrlong  r1, r2

'         if (update)
label0190
        mov     r1, #160
        add     r1, sp
        rdlong  r1, r1

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0191

'             slevel[146>>1] = value;
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'             level[152] = level[150];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'             level[153] = level[151];
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'         }
'     }
label0191

'     else
'     {
        jmp     #label0192
label0188

'         ChangeColor(next_level);
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_ChangeColor
        rdlong  r0, sp
        add     sp, #4

'         if (next_level[148] == 0x00)
        mov     r1, #0
        add     r1, sp
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$00
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             snext_level[146>>1] = 0x7fff;
        cmp     r1, #0  wz
 if_z   jmp     #label0193
        mov     r1, ##$7fff
        mov     r2, #176
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'         else
'             snext_level[146>>1] = -0x7fff;
        jmp     #label0194
label0193
        mov     r1, ##$7fff
        neg     r1, r1
        mov     r2, #176
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'         next_level[152] = 0;
label0194
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'         next_level[153] = 0;
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'         AnalyzeAllMoves(next_level);
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_AnalyzeAllMoves
        rdlong  r0, sp
        add     sp, #4

'         if (!next_level[152])
        mov     r1, #0
        add     r1, sp
        mov     r2, #152
        add     r1, r2
        rdbyte  r1, r1
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0195

'             // Check for check
'             if (IsCheck(next_level))
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_IsCheck
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4

'             {
        cmp     r1, #0  wz
 if_z   jmp     #label0196

'                 if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'                     snext_level[146>>1] = 10000;
        cmp     r1, #0  wz
 if_z   jmp     #label0197
        mov     r1, ##10000
        mov     r2, #176
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'                 else
'                     snext_level[146>>1] = -10000;
        jmp     #label0198
label0197
        mov     r1, ##10000
        neg     r1, r1
        mov     r2, #176
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'             }
label0198

'             else
'                 snext_level[146>>1] = 0; // Should go for draw only if way behind
        jmp     #label0199
label0196
        mov     r1, #0
        mov     r2, #176
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'         }
label0199

'         value = snext_level[146>>1];
label0195
        mov     r1, #176
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #146
        mov     r3, #1
        sar     r2, r3
        shl     r2, #1
        add     r1, r2
        rdword  r1, r1
        shl     r1, #16
        sar     r1, #16
        mov     r2, #164
        add     r2, sp
        wrlong  r1, r2

'         if (value == slevel[146>>1])
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0200

'             update = ((rand() & 3) == 0);
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_rand
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #3
        and     r1, r2
        mov     r2, #0
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        mov     r2, #160
        add     r2, sp
        wrlong  r1, r2

'         }
'         else
'         {
        jmp     #label0201
label0200

'             if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'                 update = (value > slevel[146>>1]);
        cmp     r1, #0  wz
 if_z   jmp     #label0202
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #160
        add     r2, sp
        wrlong  r1, r2

'             else
'                 update = (value < slevel[146>>1]);
        jmp     #label0203
label0202
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        cmps    r1, r2  wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #160
        add     r2, sp
        wrlong  r1, r2

'         }
label0203

'         if (update)
label0201
        mov     r1, #160
        add     r1, sp
        rdlong  r1, r1

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0204

'             slevel[146>>1] = value;
        mov     r1, #164
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #172
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'             level[152] = level[150];
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'             level[153] = level[151];
        mov     r1, r0
        mov     r2, #151
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'         }
'     }
label0204

' }
label0192
label0187
        add     sp, #180
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int IsCheckMate(unsigned char *level)
_IsCheckMate global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int retval;
'     int playdepth_save;
'     short *slevel;
'     retval = 0;

        sub     sp, #12
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     playdepth_save = playdepth;
        rdlong  r1, ##playdepth
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     slevel = level;
        mov     r1, r0
        mov     r2, #8
        add     r2, sp
        wrlong  r1, r2

'     playdepth = 2;
        mov     r1, #2
        wrlong  r1, ##playdepth

'     MoveFunction = 1;
        mov     r1, #1
        wrlong  r1, ##MoveFunction

'     if (level[148] == 0x00)
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$00
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         slevel[146>>1] = 0x7fff;
        cmp     r1, #0  wz
 if_z   jmp     #label0205
        mov     r1, ##$7fff
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     else
'         slevel[146>>1] = -0x7fff;
        jmp     #label0206
label0205
        mov     r1, ##$7fff
        neg     r1, r1
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     level[152] = 0;
label0206
        mov     r1, #0
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'     level[153] = 0;
        mov     r1, #0
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'     AnalyzeAllMoves(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_AnalyzeAllMoves
        rdlong  r0, sp
        add     sp, #4

'     //printf("slevel[146>>1] = %d\n", slevel[146>>1]);
'     if (slevel[146>>1] > 5000 || slevel[146>>1] < -5000)
        mov     r1, #8
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #146
        mov     r3, #1
        sar     r2, r3
        shl     r2, #1
        add     r1, r2
        rdword  r1, r1
        shl     r1, #16
        sar     r1, #16
        mov     r2, ##5000
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #8
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        rdword  r2, r2
        shl     r2, #16
        sar     r2, #16
        mov     r3, ##5000
        neg     r3, r3
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0207

'         printf("CHECKMATE\n");
        calld   lr, #label0209
        byte    "CHECKMATE", 10, 0
        alignl
label0209
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         retval = 1;
        mov     r1, #1
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     }
'     playdepth = playdepth_save;
label0207
        mov     r1, #4
        add     r1, sp
        rdlong  r1, r1
        wrlong  r1, ##playdepth

'     return retval;
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
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
' // Analyze all possible moves and select the best one
' int PerformComputerMove(unsigned char *level)
_PerformComputerMove global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int value;
'     short *slevel;
'     slevel = level;

        sub     sp, #8
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

' 
'     MoveFunction = 1;
        mov     r1, #1
        wrlong  r1, ##MoveFunction

'     if (level[148] == 0x00)
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, #$00
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         slevel[146>>1] = 0x7fff;
        cmp     r1, #0  wz
 if_z   jmp     #label0210
        mov     r1, ##$7fff
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     else
'         slevel[146>>1] = -0x7fff;
        jmp     #label0211
label0210
        mov     r1, ##$7fff
        neg     r1, r1
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #146
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     //printf("PerformComputerMove: slevel[146>>1] = %d\n", slevel[146>>1]);
'     level[152] = 0;
label0211
        mov     r1, #0
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        wrbyte  r1, r2

'     level[153] = 0;
        mov     r1, #0
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        wrbyte  r1, r2

'     AnalyzeAllMoves(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_AnalyzeAllMoves
        rdlong  r0, sp
        add     sp, #4

' 
'     // Check if best_old was updated, which indicates at least one move
'     if (level[152])
        mov     r1, r0
        mov     r2, #152
        add     r1, r2
        rdbyte  r1, r1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0212

'         if (level[152] == level[153])
        mov     r1, r0
        mov     r2, #152
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        rdbyte  r2, r2
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'             printf("STALEMATE\n");
        cmp     r1, #0  wz
 if_z   jmp     #label0213
        calld   lr, #label0215
        byte    "STALEMATE", 10, 0
        alignl
label0215
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         level[150] = level[152];
label0213
        mov     r1, r0
        mov     r2, #152
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'         level[151] = level[153];
        mov     r1, r0
        mov     r2, #153
        add     r1, r2
        rdbyte  r1, r1
        mov     r2, r0
        mov     r3, #151
        add     r2, r3
        wrbyte  r1, r2

'         PerformMove(level);
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_PerformMove
        rdlong  r0, sp
        add     sp, #4

'     }
'     else
'     {
        jmp     #label0216
label0212

'         printf("Couldn't find a move\n");
        calld   lr, #label0218
        byte    "Couldn't find a move", 10, 0
        alignl
label0218
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         printf("STALEMATE\n");
        calld   lr, #label0220
        byte    "STALEMATE", 10, 0
        alignl
label0220
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'     }
'     value = BoardValue(level);
label0216
        mov     r1, r0
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_BoardValue
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     if (value > 5000 || value < -5000)
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, ##5000
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        mov     r2, #0
        add     r2, sp
        rdlong  r2, r2
        mov     r3, ##5000
        neg     r3, r3
        cmps    r2, r3  wc
 if_c   mov     r2, #1
 if_nc  mov     r2, #0
        or      r1, r2  wz
 if_nz  mov     r1, #1

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0221

'         //printf("value = %d\n", value);
'         printf("CHECKMATE\n");
        calld   lr, #label0223
        byte    "CHECKMATE", 10, 0
        alignl
label0223
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         return 0;
        mov     r1, #0
        mov     r0, r1
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     if (movenum > 200)
label0221
        rdlong  r1, ##movenum
        mov     r2, #200
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0224

'         printf("STALEMATE\n");
        calld   lr, #label0226
        byte    "STALEMATE", 10, 0
        alignl
label0226
        mov     r1, lr
        sub     sp, #4
        wrlong  r0, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_printf
        add     sp, #4
        rdlong  r0, sp
        add     sp, #4

'         return 0;
        mov     r1, #0
        mov     r0, r1
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'     }
'     if (level[148])
label0224
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'         printf("White's Move %d: ", ++movenum);
        cmp     r1, #0  wz
 if_z   jmp     #label0227
        calld   lr, #label0229
        byte    "White's Move %d: ", 0
        alignl
label0229
        mov     r1, lr
        rdlong  r2, ##movenum
        add     r2, #1
        wrlong  r2, ##movenum
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

'     else
'         printf("Blacks's Move %d: ", movenum);
        jmp     #label0230
label0227
        calld   lr, #label0232
        byte    "Blacks's Move %d: ", 0
        alignl
label0232
        mov     r1, lr
        rdlong  r2, ##movenum
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

'     printf(" %s", PositionToString(level[152]));
label0230
        calld   lr, #label0234
        byte    " %s", 0
        alignl
label0234
        mov     r1, lr
        mov     r2, r0
        mov     r3, #152
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_PositionToString
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
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

'     printf("-%s\n", PositionToString(level[153]));
        calld   lr, #label0236
        byte    "-%s", 10, 0
        alignl
label0236
        mov     r1, lr
        mov     r2, r0
        mov     r3, #153
        add     r2, r3
        rdbyte  r2, r2
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_PositionToString
        mov     r2, r0
        setq    #1
        rdlong  r0, sp
        add     sp, #8
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

'     return 1;
        mov     r1, #1
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
' // Check if the person's intended move matches any generated moves
' void CheckPersonMove(unsigned char *level)
_CheckPersonMove global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char next_level[160];
' 
'     // Is there a match?
'     if ((level[150] == person_old) && (person_new == level[151]))

        sub     sp, #160
        mov     r1, r0
        mov     r2, #150
        add     r1, r2
        rdbyte  r1, r1
        rdlong  r2, ##person_old
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        rdlong  r2, ##person_new
        mov     r3, r0
        mov     r4, #151
        add     r3, r4
        rdbyte  r3, r3
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0237

'         InitializeNextLevel(level, next_level);
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        calld   lr, #_InitializeNextLevel
        rdlong  r0, sp
        add     sp, #4

'         PerformMove(next_level);
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_PerformMove
        rdlong  r0, sp
        add     sp, #4

'         if (!IsCheck(next_level))
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_IsCheck
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0238

'             validmove = 1;
        mov     r1, #1
        wrlong  r1, ##validmove

'             memcpy(level, next_level, 160);
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        mov     r3, #160
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memcpy
        rdlong  r0, sp
        add     sp, #4

'         }
'     }
label0238

' }
label0237
        add     sp, #160
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Prompt for a move and check if it's valid
' int PerformPersonMove(unsigned char *level)
_PerformPersonMove global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char next_level[160];
'     validmove = 0;

        sub     sp, #160
        mov     r1, #0
        wrlong  r1, ##validmove

'     if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'         movenum++;
        cmp     r1, #0  wz
 if_z   jmp     #label0239
        rdlong  r1, ##movenum
        add     r1, #1
        wrlong  r1, ##movenum

' 
'     // Loop until we get a valid move
'     while (!validmove)
label0239
label0240
        rdlong  r1, ##validmove
        cmp     r1, #0  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0

'     {
        cmp     r1, #0  wz
 if_z   jmp     #label0241

'         if (level[148])
        mov     r1, r0
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1

'             printf("White's Move %d: ", movenum);
        cmp     r1, #0  wz
 if_z   jmp     #label0242
        calld   lr, #label0244
        byte    "White's Move %d: ", 0
        alignl
label0244
        mov     r1, lr
        rdlong  r2, ##movenum
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

'         else
'             printf("Blacks's Move %d: ", movenum);
        jmp     #label0245
label0242
        calld   lr, #label0247
        byte    "Blacks's Move %d: ", 0
        alignl
label0247
        mov     r1, lr
        rdlong  r2, ##movenum
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

'         gets(inbuf);
label0245
        mov     r1, ##inbuf
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_gets
        rdlong  r0, sp
        add     sp, #4

'         if (toupper(inbuf[0]) == 'Q') return 0;
        mov     r1, ##inbuf
        mov     r2, #0
        add     r1, r2
        rdbyte  r1, r1
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_toupper
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        mov     r2, #81
        cmp     r1, r2  wz
 if_z   mov     r1, #1
 if_nz  mov     r1, #0
        cmp     r1, #0  wz
 if_z   jmp     #label0248
        mov     r1, #0
        mov     r0, r1
        add     sp, #160
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         person_old = StringToPostion(inbuf);
label0248
        mov     r1, ##inbuf
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_StringToPostion
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##person_old

'         person_new = StringToPostion(inbuf + 3);
        mov     r1, ##inbuf
        mov     r2, #3
        add     r1, r2
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_StringToPostion
        mov     r1, r0
        rdlong  r0, sp
        add     sp, #4
        wrlong  r1, ##person_new

'         if (person_old >= 0 && person_new >= 0 && inbuf[2] == '-')
        rdlong  r1, ##person_old
        mov     r2, #0
        cmps    r1, r2  wc
 if_nc  mov     r1, #1
 if_c   mov     r1, #0
        rdlong  r2, ##person_new
        mov     r3, #0
        cmps    r2, r3  wc
 if_nc  mov     r2, #1
 if_c   mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0
        mov     r2, ##inbuf
        mov     r3, #2
        add     r2, r3
        rdbyte  r2, r2
        mov     r3, #45
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0
        cmp     r1, #0  wz
 if_nz  cmp     r2, #0  wz
 if_nz  mov     r1, #1
 if_z   mov     r1, #0

'         {
        cmp     r1, #0  wz
 if_z   jmp     #label0249

'             MoveFunction = 2;
        mov     r1, #2
        wrlong  r1, ##MoveFunction

'             level[150] = person_old;
        rdlong  r1, ##person_old
        mov     r2, r0
        mov     r3, #150
        add     r2, r3
        wrbyte  r1, r2

'             memcpy(next_level, level, 160);
        mov     r1, #0
        add     r1, sp
        mov     r2, r0
        mov     r3, #160
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memcpy
        rdlong  r0, sp
        add     sp, #4

'             MoveIfMyPiece(next_level);
        mov     r1, #0
        add     r1, sp
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        calld   lr, #_MoveIfMyPiece
        rdlong  r0, sp
        add     sp, #4

'         }
'     }
label0249

' 
'     next_level[149] = 0;
        jmp     #label0240
label0241
        mov     r1, #0
        mov     r2, #0
        add     r2, sp
        mov     r3, #149
        add     r2, r3
        wrbyte  r1, r2

'     memcpy(level, next_level, 160);
        mov     r1, r0
        mov     r2, #0
        add     r2, sp
        mov     r3, #160
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memcpy
        rdlong  r0, sp
        add     sp, #4

'     return 1;
        mov     r1, #1
        mov     r0, r1
        add     sp, #160
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #160
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Prompt person for color, and set the computer's color
' void GetColor()
_GetColor global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("Do you want White (Y/N): ");

        calld   lr, #label0251
        byte    "Do you want White (Y/N): ", 0
        alignl
label0251
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     gets(inbuf);
        mov     r0, ##inbuf
        calld   lr, #_gets

'     //compcolor = (toupper(inbuf[0]) == 'Y') ? 0x00 : 0x80;
'     if (toupper(inbuf[0]) == 'Y')
        mov     r0, ##inbuf
        mov     r1, #0
        add     r0, r1
        rdbyte  r0, r0
        calld   lr, #_toupper
        mov     r0, r0
        mov     r1, #89
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'         compcolor = 0;
        cmp     r0, #0  wz
 if_z   jmp     #label0252
        mov     r0, #0
        wrlong  r0, ##compcolor

'     else
'         compcolor = 0x80;
        jmp     #label0253
label0252
        mov     r0, #$80
        wrlong  r0, ##compcolor

' }
label0253
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Prompt for the playing level
' void GetPlayLevel()
_GetPlayLevel global
        sub     sp, #4
        wrlong  lr, sp

' {
'     playdepth = 0;

        mov     r0, #0
        wrlong  r0, ##playdepth

'     while (playdepth < 1 || playdepth > 5)
label0254
        rdlong  r0, ##playdepth
        mov     r1, #1
        cmps    r0, r1  wc
 if_c   mov     r0, #1
 if_nc  mov     r0, #0
        rdlong  r1, ##playdepth
        mov     r2, #5
        cmps    r2, r1 wc
 if_c   mov     r1, #1
 if_nc  mov     r1, #0
        or      r0, r1  wz
 if_nz  mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0255

'         printf("Enter Play Level (1-%d): ", 5);
        calld   lr, #label0257
        byte    "Enter Play Level (1-%d): ", 0
        alignl
label0257
        mov     r0, lr
        mov     r1, #5
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'         gets(inbuf);
        mov     r0, ##inbuf
        calld   lr, #_gets

'         sscanf(inbuf, "%d", &playdepth);
        mov     r0, ##inbuf
        calld   lr, #label0259
        byte    "%d", 0
        alignl
label0259
        mov     r1, lr
        mov     r2, ##playdepth
        sub     sp, #4
        wrlong  r2, sp
        sub     sp, #4
        wrlong  r1, sp
        calld   lr, #_sscanf
        add     sp, #8

'     }
' }
        jmp     #label0254
label0255
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' void Initialize(unsigned char *level)
_Initialize global
        sub     sp, #4
        wrlong  lr, sp

' {
'     unsigned char *ptr;
'     short *slevel;
'     ptr = level + ((12 * 2) + 2);

        sub     sp, #8
        mov     r1, r0
        mov     r2, #12
        mov     r3, #2
        qmul    r2, r3
        getqx   r2
        mov     r3, #2
        add     r2, r3
        add     r1, r2
        mov     r2, #0
        add     r2, sp
        wrlong  r1, r2

'     slevel = level;
        mov     r1, r0
        mov     r2, #4
        add     r2, sp
        wrlong  r1, r2

'     memset(level, 0xff, (12 * 12));
        mov     r1, r0
        mov     r2, #$ff
        mov     r3, #12
        mov     r4, #12
        qmul    r3, r4
        getqx   r3
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memcpy(ptr, black_rank, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, ##black_rank
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memcpy
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + 12, 0x00 | 1, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        add     r1, r2
        mov     r2, #$00
        mov     r3, #1
        or      r2, r3
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + (12 * 2), 0, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #2
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #0
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + (12 * 3), 0, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #3
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #0
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + (12 * 4), 0, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #4
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #0
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + (12 * 5), 0, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #5
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #0
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memset(ptr + (12 * 6), 0x80 | 1, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #6
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, #$80
        mov     r3, #1
        or      r2, r3
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memset
        rdlong  r0, sp
        add     sp, #4

'     memcpy(ptr + (12 * 7), white_rank, 8);
        mov     r1, #0
        add     r1, sp
        rdlong  r1, r1
        mov     r2, #12
        mov     r3, #7
        qmul    r2, r3
        getqx   r2
        add     r1, r2
        mov     r2, ##white_rank
        mov     r3, #8
        sub     sp, #4
        wrlong  r0, sp
        mov     r0, r1
        mov     r1, r2
        mov     r2, r3
        calld   lr, #_memcpy
        rdlong  r0, sp
        add     sp, #4

'     movenum = 0;
        mov     r1, #0
        wrlong  r1, ##movenum

'     level[149] = 0;
        mov     r1, #0
        mov     r2, r0
        mov     r3, #149
        add     r2, r3
        wrbyte  r1, r2

'     level[148] = 0x80;
        mov     r1, #$80
        mov     r2, r0
        mov     r3, #148
        add     r2, r3
        wrbyte  r1, r2

'     slevel[144>>1] = 0;
        mov     r1, #0
        mov     r2, #4
        add     r2, sp
        rdlong  r2, r2
        mov     r3, #144
        mov     r4, #1
        sar     r3, r4
        shl     r3, #1
        add     r2, r3
        wrword  r1, r2

'     level[154] = ((12 * 9) + 2) + 4;
        mov     r1, #12
        mov     r2, #9
        qmul    r1, r2
        getqx   r1
        mov     r2, #2
        add     r1, r2
        mov     r2, #4
        add     r1, r2
        mov     r2, r0
        mov     r3, #154
        add     r2, r3
        wrbyte  r1, r2

'     level[155] = ((12 * 2) + 2) + 4;
        mov     r1, #12
        mov     r2, #2
        qmul    r1, r2
        getqx   r1
        mov     r2, #2
        add     r1, r2
        mov     r2, #4
        add     r1, r2
        mov     r2, r0
        mov     r3, #155
        add     r2, r3
        wrbyte  r1, r2

'     level[156] = 0;
        mov     r1, #0
        mov     r2, r0
        mov     r3, #156
        add     r2, r3
        wrbyte  r1, r2

' }
        add     sp, #8
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int PlayChess()
_PlayChess global
        sub     sp, #4
        wrlong  lr, sp

' {
'     int retval;
'     unsigned char level[160];
'     GetPlayLevel();

        sub     sp, #164
        calld   lr, #_GetPlayLevel

'     printf("Do you want to play against the computer? (Y/N): ");
        calld   lr, #label0261
        byte    "Do you want to play against the computer? (Y/N): ", 0
        alignl
label0261
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     gets(inbuf);
        mov     r0, ##inbuf
        calld   lr, #_gets

'     human_playing = (toupper(inbuf[0]) == 'Y');
        mov     r0, ##inbuf
        mov     r1, #0
        add     r0, r1
        rdbyte  r0, r0
        calld   lr, #_toupper
        mov     r0, r0
        mov     r1, #89
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        wrlong  r0, ##human_playing

'     if (human_playing)
        rdlong  r0, ##human_playing

'         GetColor();
        cmp     r0, #0  wz
 if_z   jmp     #label0262
        calld   lr, #_GetColor

'     else
'         compcolor = 0x80;
        jmp     #label0263
label0262
        mov     r0, #$80
        wrlong  r0, ##compcolor

'     Initialize(level);
label0263
        mov     r0, #4
        add     r0, sp
        calld   lr, #_Initialize

'     PrintBoard(level);
        mov     r0, #4
        add     r0, sp
        calld   lr, #_PrintBoard

'     while (1)
label0264
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0265

'         //printf("compcolor = %d, level[148] = %d\n", compcolor, level[148]);
'         if (compcolor == level[148])
        rdlong  r0, ##compcolor
        mov     r1, #4
        add     r1, sp
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        cmp     r0, r1  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'             retval = PerformComputerMove(level);
        cmp     r0, #0  wz
 if_z   jmp     #label0266
        mov     r0, #4
        add     r0, sp
        calld   lr, #_PerformComputerMove
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'         else
'             retval = PerformPersonMove(level);
        jmp     #label0267
label0266
        mov     r0, #4
        add     r0, sp
        calld   lr, #_PerformPersonMove
        mov     r0, r0
        mov     r1, #0
        add     r1, sp
        wrlong  r0, r1

'         if (!retval) return 1;
label0267
        mov     r0, #0
        add     r0, sp
        rdlong  r0, r0
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0
        cmp     r0, #0  wz
 if_z   jmp     #label0268
        mov     r0, #1
        add     sp, #164
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

'         PrintBoard(level);
label0268
        mov     r0, #4
        add     r0, sp
        calld   lr, #_PrintBoard

'         if (IsCheck(level))
        mov     r0, #4
        add     r0, sp
        calld   lr, #_IsCheck
        mov     r0, r0

'             printf("Illegal move into check %d\n", level[148]);
        cmp     r0, #0  wz
 if_z   jmp     #label0269
        calld   lr, #label0271
        byte    "Illegal move into check %d", 10, 0
        alignl
label0271
        mov     r0, lr
        mov     r1, #4
        add     r1, sp
        mov     r2, #148
        add     r1, r2
        rdbyte  r1, r1
        sub     sp, #4
        wrlong  r1, sp
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #8

'         ChangeColor(level);
label0269
        mov     r0, #4
        add     r0, sp
        calld   lr, #_ChangeColor

'         if (IsCheck(level))
        mov     r0, #4
        add     r0, sp
        calld   lr, #_IsCheck
        mov     r0, r0

'         {
        cmp     r0, #0  wz
 if_z   jmp     #label0272

'             if (IsCheckMate(level)) break;
        mov     r0, #4
        add     r0, sp
        calld   lr, #_IsCheckMate
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0273
        jmp     #label0265

'             printf("CHECK\n\n");
label0273
        calld   lr, #label0275
        byte    "CHECK", 10, 10, 0
        alignl
label0275
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'         }
'         if (!human_playing)
label0272
        rdlong  r0, ##human_playing
        cmp     r0, #0  wz
 if_z   mov     r0, #1
 if_nz  mov     r0, #0

'             compcolor ^= 0x80;
        cmp     r0, #0  wz
 if_z   jmp     #label0276
        mov     r0, #$80
        rdlong  r2, ##compcolor
        xor     r0, r2
        wrlong  r0, ##compcolor

'     }
label0276

'     return 0;
        jmp     #label0264
label0265
        mov     r0, #0
        add     sp, #164
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        add     sp, #164
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' // Call the appropriate move function based on the function number
' void CallMoveFunction(int funcnum, unsigned char *level)
_CallMoveFunction global
        sub     sp, #4
        wrlong  lr, sp

' {
'     if (funcnum == 1)

        mov     r2, r0
        mov     r3, #1
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         AnalyzeMove(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0277
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_AnalyzeMove
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 2)
        jmp     #label0278
label0277
        mov     r2, r0
        mov     r3, #2
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         CheckPersonMove(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0279
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_CheckPersonMove
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 4)
        jmp     #label0280
label0279
        mov     r2, r0
        mov     r3, #4
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         Pawn(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0281
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Pawn
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 5)
        jmp     #label0282
label0281
        mov     r2, r0
        mov     r3, #5
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         Knight(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0283
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Knight
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 6)
        jmp     #label0284
label0283
        mov     r2, r0
        mov     r3, #6
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         Bishop(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0285
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Bishop
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 7)
        jmp     #label0286
label0285
        mov     r2, r0
        mov     r3, #7
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         Rook(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0287
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Rook
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 8)
        jmp     #label0288
label0287
        mov     r2, r0
        mov     r3, #8
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         Queen(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0289
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Queen
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else if (funcnum == 9)
        jmp     #label0290
label0289
        mov     r2, r0
        mov     r3, #9
        cmp     r2, r3  wz
 if_z   mov     r2, #1
 if_nz  mov     r2, #0

'         King(level);
        cmp     r2, #0  wz
 if_z   jmp     #label0291
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_King
        setq    #1
        rdlong  r0, sp
        add     sp, #8

'     else
'         Invalid(level);
        jmp     #label0292
label0291
        mov     r2, r1
        sub     sp, #8
        setq    #1
        wrlong  r0, sp
        mov     r0, r2
        calld   lr, #_Invalid
        setq    #1
        rdlong  r0, sp
        add     sp, #8

' }
label0292
label0290
label0288
label0286
label0284
label0282
label0280
label0278
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
' int main()
_main    global
        sub     sp, #4
        wrlong  lr, sp

' {
'     printf("P2 Chess\n");

        calld   lr, #label0294
        byte    "P2 Chess", 10, 0
        alignl
label0294
        mov     r0, lr
        sub     sp, #4
        wrlong  r0, sp
        calld   lr, #_printf
        add     sp, #4

'     symbols = "xPNBRQKx";
        calld   lr, #label0296
        byte    "xPNBRQKx", 0
        alignl
label0296
        mov     r0, lr
        wrlong  r0, ##symbols

'     pos_values[0] = null_values;
        mov     r0, ##null_values
        mov     r1, ##pos_values
        mov     r2, #0
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[1] = pawn_values;
        mov     r0, ##pawn_values
        mov     r1, ##pos_values
        mov     r2, #1
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[2] = knight_values;
        mov     r0, ##knight_values
        mov     r1, ##pos_values
        mov     r2, #2
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[3] = bishop_values;
        mov     r0, ##bishop_values
        mov     r1, ##pos_values
        mov     r2, #3
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[4] = null_values;
        mov     r0, ##null_values
        mov     r1, ##pos_values
        mov     r2, #4
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[5] = null_values;
        mov     r0, ##null_values
        mov     r1, ##pos_values
        mov     r2, #5
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[6] = king_values;
        mov     r0, ##king_values
        mov     r1, ##pos_values
        mov     r2, #6
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     pos_values[7] = null_values;
        mov     r0, ##null_values
        mov     r1, ##pos_values
        mov     r2, #7
        shl     r2, #2
        add     r1, r2
        wrlong  r0, r1

'     srand(1);
        mov     r0, #1
        calld   lr, #_srand

'     while (1)
label0297
        mov     r0, #1

'     {
        cmp     r0, #0  wz
 if_z   jmp     #label0298

'         if (PlayChess()) break;
        calld   lr, #_PlayChess
        mov     r0, r0
        cmp     r0, #0  wz
 if_z   jmp     #label0299
        jmp     #label0298

'     }
label0299

'     return 1;
        jmp     #label0297
label0298
        mov     r0, #1
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' }
        rdlong  lr, sp
        add     sp, #4
        jmp     lr

' 
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
' EOF
