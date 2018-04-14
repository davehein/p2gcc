	.global	_putch
_putch
	or	r0, #$100
	shl	r0, #1
	mov	r1, #10
	getct	r2
loop	shr	r0, #1 wc
	drvc	#62
	addct1	r2, ##80000000/115200
	waitct1
	djnz	r1, #loop
	jmp	lr
