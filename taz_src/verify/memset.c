char *memset(char *ptr, int value, int num)
{
    char *ptr0;
    ptr0 = ptr;
    while (num-- > 0) *ptr++ = value;
    return ptr0;
}
