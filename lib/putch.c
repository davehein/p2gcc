void putch(int val)
{
    inline("        or      reg0, #$100");
    inline("        shl     reg0, #1");
    inline("        mov     reg1, #10");
    inline("        getct   reg2");
    inline(".loop   shr     reg0, #1 wc");
    inline("        drvc    #62");
    inline("        addct1  reg2, ##80000000/115200");
    inline("        waitct1");
    inline("        djnz    reg1, #.loop");
}

void putchar(int val)
{
    if (val == 10)
        putch(13);
    putch(val);
}
