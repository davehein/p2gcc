int strncmp(char *str1, char *str2, int num)
{
    while (--num > 0 && *str1 && *str1 == *str2)
    {
        str1++;
        str2++;
    }
    return (*str1 - *str2);
}
