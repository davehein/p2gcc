#include <string.h>

char *strchr(const char *str, int val)
{
    while (*str)
    {
        if (*str == val)
            return (char *)str;
        str++;
    }
    return 0;
}

