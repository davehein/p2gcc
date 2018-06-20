int strlen(char *str)
{
    char *str0;
    str0 = str;
    while (*str++) {}
    return (str - str0 - 1);
}
