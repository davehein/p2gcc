char *itoa10(int value, char *ptr)
{
    char *rval = ptr;
    int zeroflag = 0;
    int i = 1000000000;

    if (value < 0)
    {
        *ptr++ = '-';
        if (value == 0x80000000)
        {
            *ptr++ = '2';
            value += 2000000000;
        }
        value = -value;
    }

    while (i)
    {
        if (value >= i)
        {
            *ptr++ = (value / i) + '0';
            value %= i;
            zeroflag = 1;
        }
        else if (zeroflag || i == 1)
        {
            *ptr++ = '0';
        }
        i /= 10;
    }
    *ptr = 0;
    return rval;
}
