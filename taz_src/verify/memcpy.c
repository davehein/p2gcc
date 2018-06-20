char *memcpy(char *dstptr, char *srcptr, int num)
{
    char *dstptr0;
    dstptr0 = dstptr;
    while (num-- > 0) *dstptr++ = *srcptr++;
    return dstptr0;
}
