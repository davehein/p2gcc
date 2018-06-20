char *strcat(char *dstptr, char *srcptr)
{
    char *dstptr0;
    dstptr0 = dstptr;

    while (*dstptr) dstptr++;
    while (*srcptr) *dstptr++ = *srcptr++;
    *dstptr = 0;
    return dstptr0;
}
