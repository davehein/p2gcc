int strtol(char *str, char **endptr, int base)
{
    int negate, value;
    value = 0;
    negate = 0;

    // Skip leading blanks
    while(*str == ' ') str++;

    // Check for + or - 
    if (*str == '+')
        str++;
    else if (*str == '-')
    {
        str++;
        negate = 1;
    }

    // Skip 0x or 0X if base 16
    if (base == 16)
    {
        if (*str == '0')
        {
            str++;
            if (*str == 'x' || *str == 'X')
                str++;
        }
    }

    // If base is 0 set it to 8, 10 or 16
    else if (!base)
    {
        if (*str == '0')
        {
            str++;
            if (*str == 'x' || *str == 'X')
            {
                str++;
                base = 16;
            }
            else
                base = 8;
        }
        else
            base = 10;
    }

    while (*str >= '0')
    {
        if (*str <= '9')
        {
            if (*str - '0' >= base) break;
            value = value*base + (*str++) - '0';
        }
        else if (*str >= 'a')
        {
            if (*str - 'a' + 10 >= base) break;
            value = value*base + (*str++) - 'a' + 10;
        }
        else if (*str >= 'A')
        {
            if (*str - 'A' + 10 >= base) break;
            value = value*base + (*str++) - 'A' + 10;
        }
        else
            break;
    }

    if (endptr) *endptr = str;
    if (negate) value = -value;

    return value;
}
