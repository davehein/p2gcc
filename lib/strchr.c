#include <string.h>

char *strchr(const char *str, int val)
{
    do {
        if (*str == val)
            return (char *)str;
    } while (*str++);
    return 0;
}

