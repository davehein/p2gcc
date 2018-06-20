void putdec(int val)
{
    int i, j;

    i = 1000000000;
    if (val == 0)
    {
        putchar('0');
        return;
    }
    if (val < 0)
    {
        putchar('-');
        val = -val;
    }
    while (i > val) i /= 10;
    while (i)
    {
        j = val/i;
        putchar(j+'0');
        val -= j * i;
        i /= 10;
    }
}

