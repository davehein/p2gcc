#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "cstrsubs.h"
// SPIN OBJECT c : "cliboslt"
// SPIN OBJECT

// Find the first occurance of "val" in the string "str"
// Point to the NULL at the end of the string of not found
char *FindChar(char *str, int val)
{
    while (*str)
    {
        if (*str == val) break;
        str++;
    }
    return str;
}

// Skip until a value not equal to "val" is found in "str"
// Point to the NULL at the end of the string if all value are equal to "val"
char *SkipChar(char *str, int val)
{
    while (*str)
    {
        if (*str != val) break;
        str++;
    }
    return str;
}

// Search if the first part of a string in "str" matches on of the strings
// in a list pointed to by "list".  Return the index value if there is a
// match, or -1 if no match.
int SearchListN(char **list, char *str)
{
    int i;
    for (i = 0; list[i]; i++)
    {
        if (!strncmp(str, list[i], strlen(list[i]))) return i;
    }
    return -1;
}

// Search for the first occurance in "str1" of one of the characters in "str2"
char *FindChars(char *str1, char *str2)
{
    char *ptr;
    while (*str1)
    {
        ptr = str2;
        while (*ptr)
        {
            if (*str1 == *ptr) return str1;
            ptr++;
        }
        str1++;
    }
    return str1;
}

// Seach the list of strings in "list" for a match to the string in "str"
// Return the index value if there is a match, or -1 if no match.
int SearchList(char **list, char *str)
{
    int i;

    for (i = 0; list[i]; i++)
    {
        if (!strcmp(list[i], str)) return i;
    }

    return -1;
}

// Remove carriage-return and line-feed characters from the end of a string
void RemoveCRLF(char *ptr)
{
    int len = strlen(ptr);

    while (len--)
    {
        if (ptr[len] != 13 && ptr[len] != 10) break;
        ptr[len] = 0;
    }
}
