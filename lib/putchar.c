#include <stdio.h>

void putch(int val);

int putchar(int val)
{
    if (val == 10)
        putch(13);
    putch(val);
    return val;
}
