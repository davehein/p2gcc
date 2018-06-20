int sscanf(char *str, char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8)
{
    int i;
    int va;
    int arglist[8];

    va_start(va, fmt);
    for (i = 0; i < 8; i++)
        arglist[i] = va_arg(va, int);
    va_end(va);

    return vsscanf(str, fmt, arglist);
}

int vsscanf(char *str, char *fmt, int *arglist)
{
    char *ptr;
    char *ptr1;
    int *iptr;
    int num;

    num = 0;
    ptr = str;
    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            if (*fmt == 0) break;
            if (*fmt == 'd')
            {
                iptr = *arglist++;
                *iptr = strtol(ptr, &ptr, 10);
            }
            else if (*fmt == 'x')
            {
                iptr = *arglist++;
                *iptr = strtol(ptr, &ptr, 16);
            }
            else if (*fmt == 's')
            {
                ptr1 = *arglist++;
                while (*ptr && *ptr == ' ') ptr++;
                while (*ptr && *ptr != ' ') *ptr1++ = *ptr++;
                *ptr1 = 0;
            }
            num++;
        }
        fmt++;
    }
    return num;
}
