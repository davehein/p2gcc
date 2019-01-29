	.global	_getch
_getch
        rdlong  r4, ##_p2bitcycles
        'mov     r4, ##80000000/115200
        mov     r5, r4
        shr     r5, #1
	mov	r1, #8
loop1	and	inb, ##0x80000000 wz
 if_nz	jmp	#loop1
	getct   r2
	add     r2, r5 '##40000000/115200
loop2	addct1  r2, r4 '##80000000/115200
	waitct1
	shr	r0, #1
	mov	r3, inb
	and	r3, ##0x80000000
	or	r0, r3
	djnz	r1, #loop2
	addct1  r2, r4 '##80000000/115200
	waitct1
	shr	r0, #24
	jmp	lr
