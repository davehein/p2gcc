void putch(int val)
{
    int count;
    val |= 0x100;
    val <<= 1;
    count = 10;
    inline("        getct   temp2");
    while (count--)
    {
        outb = val << 30;
        inline("        addct1  temp2, #50000000/115200");
        inline("        waitct1");
        val >>= 1;
    }
    waitx(2000);
}

void putchar(int val)
{
    if (val == 10)
        putch(13);
    putch(val);
}
