char *strcpy(char *dstptr, char *srcptr)
{
    char *dstptr0;
    dstptr0 = dstptr;

    while (*srcptr) *dstptr++ = *srcptr++;
    *dstptr = 0;
    return dstptr0;
}

char *strncpy(char *dstptr, char *srcptr, int num)
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
