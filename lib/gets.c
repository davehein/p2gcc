#include <stdio.h>
#include <string.h>

int getch(void);
void putch(int val);

char *getsn(char *ptr, int num)
{
    int val;
    char *ptr1;
    ptr1 = ptr;

    while (num > 1)
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
                *ptr++ = 10;
                break;
            }
            putch(val);
            *ptr++ = val;
        }
        num--;
    }
    *ptr = 0;

    return ptr1;
}

char *gets(char *str)
{
    int len;
    getsn(str, 1000000000);
    if ((len = strlen(str)))
        if (str[len-1] == 10) str[len-1] = 0;
    return str;
}
