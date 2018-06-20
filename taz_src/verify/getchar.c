int getch(unsigned int val)
{
    int count;
    count = 8;
    while (inb & 0x80000000) {}
    inline("getct   temp2");
    inline("add     temp2, #25000000/115200");
    while (count--)
    {
        inline("addct1  temp2, #50000000/115200");
        inline("waitct1");
        val = (val >> 1) | (inb & 0x80000000);
    }
    inline("addct1  temp2, #50000000/115200");
    inline("waitct1");
    return (val >> 24);
}

int getchar(void)
{
    int val;
    val = getch();
    putchar(val);
    return val;
}
