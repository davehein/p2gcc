void puthex(int val)
{
    int i, j;

    for (i = 0; i < 7; i++)
    {
        if (val & 0xf0000000) break;
        val <<= 4;
    }

    for (i = i; i < 8; i++)
    {
        j = (val >> 28) & 15;
        if (j < 10) putchar(j + '0');
        else putchar(j+'a'-10);
        val <<= 4;
    }
}

