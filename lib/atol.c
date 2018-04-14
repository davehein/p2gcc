#include <stdlib.h>

long int atol(const char *str)
{
    int negate, value;
    value = 0;
    negate = 0;
  
    if (*str == '+')
        str++;
    else if (*str == '-')
    {
        str++;
        negate = 1;
    }

    while (*str >= '0' && *str <= '9')
        value = value*10 + (*str++) - '0';

    if (negate) value = -value;

    return value;
}
