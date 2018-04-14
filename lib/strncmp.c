#include <string.h>

int strncmp(const char *str1, const char *str2, size_t num)
{
    while (--num > 0 && *str1 && *str1 == *str2)
    {
        str1++;
        str2++;
    }
    return (*str1 - *str2);
}
