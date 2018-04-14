#include <stdio.h>

int getch(void);

int getchar(void)
{
    int val;
    val = getch();
    if (val == 13)
        putchar(10);
    else
        putchar(val);
    return val;
}
