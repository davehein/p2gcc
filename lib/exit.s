	.global	_exit
_exit
	cogid	r1
        mov     r2, #0
        wrlong  r2, r2
	cogstop	r1
