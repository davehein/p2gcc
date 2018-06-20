void sprintf(char *str, char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10)
{
    int i, index;
    int arglist[10];

    va_start(index, fmt);
    for (i = 0; i < 10; i++)
        arglist[i] = va_arg(index, int);
    va_end(index);
    vsprintf(str, fmt, arglist);
}

