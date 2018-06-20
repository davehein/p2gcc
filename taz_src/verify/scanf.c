void scanf(char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8)
{
    int i;
    int va;
    int arglist[8];
    char inbuf[100];

    va_start(va, fmt);
    for (i = 0; i < 8; i++)
        arglist[i] = va_arg(va, int);
    va_end(va);

    gets(inbuf);

    return vsscanf(inbuf, fmt, arglist);
}

