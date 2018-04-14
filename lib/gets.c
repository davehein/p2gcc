#include <stdio.h>

int getch(void);
void putch(int val);

char *gets(char *ptr)
{
    int val;
    char *ptr1;
    ptr1 = ptr;

    while (1)
    {
        val = getch();
        if (val == 8 || val == 127)
        {
            if (ptr != ptr1)
            {
                putch(8);
                putch(' ');
                putch(8);
                ptr--;
            }
        }
        else
        {
            if (val == 13 || val == 10)
            {
                putchar(10);
                break;
            }
            putch(val);
            *ptr++ = val;
        }
    }
    *ptr = 0;

    return ptr1;
}
