#include <string.h>

size_t strlen(const char *str)
{
    const char *str0 = str;
    while (*str++) {}
    return (str - str0 - 1);
}
