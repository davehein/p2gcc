int p2bitcycles;

void putch(int val)
{
    __asm__("        rdlong  r3, ##_p2bitcycles");
    //__asm__("        mov     r3, ##160000000/115200");
    __asm__("        or      r0, #$100");
    __asm__("        shl     r0, #1");
    __asm__("        mov     r1, #10");
    __asm__("        getct   r2");
    __asm__("loop");
    __asm__("        shr     r0, #1 wc");
    __asm__("        drvc    #62");
    __asm__("        addct1  r2, r3");
    __asm__("        waitct1");
    __asm__("        djnz    r1, #loop");
}
