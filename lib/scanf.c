#include <stdio.h>
#include <stdarg.h>

int scanf(const char *fmt, ...)
{
    va_list va;
    int count = 0;
    int negate, value, inval;
    char *cptr;
    int *iptr;
    va_start(va, fmt);
    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            if (*fmt == 0) break;
            if (*fmt == 'd')
            {
                negate = 0;
                value = 0;
                iptr = (int *)va_arg(va, int);
                count++;
                while (1)
                {
                    inval = getchar();
                    if (inval > ' ') break;
                }
                if (inval == '+')
                    inval = getchar();
                else if (inval == '-')
                {
                    negate = 1;
                    inval = getchar();
                }
                while (inval >= '0' && inval <= '9')
                {
                    value = value * 10 + inval - '0';
                    inval = getchar();
                }
                if (negate)
                    *iptr = -value;
                else
                    *iptr = value;
            }
            else if (*fmt == 'x')
            {
                negate = 0;
                value = 0;
                iptr = (int *)va_arg(va, int);
                count++;
                while (1)
                {
                    inval = getchar();
                    if (inval > ' ') break;
                }
                if (inval == '+')
                    inval = getchar();
                else if (inval == '-')
                {
                    negate = 1;
                    inval = getchar();
                }
                while (1)
                {
                    if (inval >= '0' && inval <= '9')
                        value = (value << 4) + inval - '0';
                    else if (inval >= 'A' && inval <= 'F')
                        value = (value << 4) + inval - 'A' + 10;
                    else if (inval >= 'a' && inval <= 'f')
                        value = (value << 4) + inval - 'a' + 10;
                    else
                        break;
                    inval = getchar();
                }
                if (negate)
                    *iptr = -value;
                else
                    *iptr = value;
            }
            else if (*fmt == 's')
            {
                cptr = (char *)va_arg(va, int);
                count++;
                while (1)
                {
                    inval = getchar();
                    if (inval > ' ') break;
                }
                while (inval > ' ')
                {
                    *cptr++ = inval;
                    inval = getchar();
                }
                *cptr = 0;
            }
        }
        fmt++;
    }
    va_end(va);
    return count;
}

