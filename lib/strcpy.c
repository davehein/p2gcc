#include <string.h>

char *strcpy(char *dstptr, const char *srcptr)
{
    char *dstptr0;
    dstptr0 = dstptr;

    while (*srcptr) *dstptr++ = *srcptr++;
    *dstptr = 0;
    return dstptr0;
}
