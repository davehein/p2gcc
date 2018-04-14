#include <string.h>

void *memcpy(void *destination, const void *source, size_t num)
{
    char *dstptr = destination;
    const char *srcptr = source;

    while (num-- > 0) *dstptr++ = *srcptr++;
    return destination;
}
