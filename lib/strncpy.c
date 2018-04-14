#include <string.h>

char *strncpy(char *dstptr, const char *srcptr, size_t num)
{
    char *dstptr0;
    dstptr0 = dstptr;

    while (*srcptr && num > 0)
    {
        num-- ;
        *dstptr++ = *srcptr++;
    }

    while (num-- > 0) *dstptr++ = 0;

    return dstptr0;
}
