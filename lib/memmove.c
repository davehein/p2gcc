#include <string.h>

void *memmove(void *destination, const void *source, size_t num)
{
    char *dstptr = destination;
    const char *srcptr = source;

    if (source >= destination)
    {
        while (num-- > 0) *dstptr++ = *srcptr++;
    }
    else
    {
        dstptr += num - 1;
        srcptr += num - 1;
        while (num-- > 0) *dstptr-- = *srcptr--;
    }
    return destination;
}
