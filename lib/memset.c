#include <string.h>

void *memset(void *destination, int value, size_t num)
{
    char *dstptr = destination;

    while (num-- > 0) *dstptr++ = value;
    return destination;
}
