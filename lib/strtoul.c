#include <stdlib.h>

unsigned long strtoul(const char *str, char **endptr, int base)
{
    // Skip leading blanks
    while(*str == ' ') str++;

    // Check for - 
    if (*str == '-')
        return 0;

    return (unsigned long)strtol(str, endptr, base);
}
