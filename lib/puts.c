#include <stdio.h>

int puts(const char *str)
{
    while (*str) putchar(*str++);
    putchar(10);
    return 0;
}

