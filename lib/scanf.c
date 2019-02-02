#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int scanf(const char *fmt, ...)
{
    char *ptr;
    int *iptr;
    char *ptr1;
    va_list va;
    int count = 0;
    char inbuf[200];

    gets(inbuf);
    va_start(va, fmt);
    ptr = inbuf;
    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            if (*fmt == 0) break;
            if (*fmt == 'd')
            {
                iptr = (int *)va_arg(va, int);
                count++;
                *iptr = strtol(ptr, &ptr, 10);
            }
            else if (*fmt == 'x')
            {
                iptr = (int *)va_arg(va, int);
                count++;
                *iptr = strtol(ptr, &ptr, 16);
            }
            else if (*fmt == 'f' || *fmt == 'g')
            {
                float *fptr = (float *)va_arg(va, int);
                count++;
                *fptr = strtof(ptr, &ptr);
            }
            else if (*fmt == 's')
            {
                ptr1 = (char *)va_arg(va, int);
                count++;
                while (*ptr && *ptr == ' ') ptr++;
                while (*ptr && *ptr != ' ') *ptr1++ = *ptr++;
                *ptr1 = 0;
            }
        }
        fmt++;
    }
    va_end(va);
    return count;
}

