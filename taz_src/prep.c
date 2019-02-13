#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cstrsubs.h"

#define BUFFER_SIZE 1000
#define MAX_SYMBOLS 100
#define BIGBUF_SIZE 100 * MAX_SYMBOLS

#define MODE_DELIMETER 0
#define MODE_NUMBER    1
#define MODE_SYMBOL    2

char buffer[BUFFER_SIZE];
char outbuf[BUFFER_SIZE];

char *Symbol[MAX_SYMBOLS];
char *Symptr[MAX_SYMBOLS];
char bigbuf[BIGBUF_SIZE];
char *bigptr = bigbuf;
int numsym = 0;

void AddToTable(char *ptr)
{
    int len;
    char *ptr1, *ptr2, *ptr3;

    ptr = SkipChar(ptr, ' ');
    if (*ptr == 0) return;
    ptr1 = FindChar(ptr, ' ');
    ptr2 = SkipChar(ptr1, ' ');
    len = ptr1 - ptr;
    ptr3 = ptr2 - 1;
    for (ptr1 = ptr2; *ptr1; ptr1++)
    {
        if (*ptr1 == '/' && ptr1[1] == '/')
        {
            ptr3[1] = 0;
            break;
        }
        if (*ptr1 != ' ') ptr3 = ptr1;
    }
    Symbol[numsym] = bigptr;
    memcpy(bigptr, ptr, len);
    bigptr += len;
    *bigptr++ = 0;
    Symptr[numsym++] = bigptr;
    strcpy(bigptr, ptr2);
    bigptr += strlen(ptr2) + 1;
}

int check_mode(int val, int mode)
{
    if (mode == MODE_DELIMETER)
    {
        if (val == '_')
            mode = MODE_SYMBOL;
        else if (val >= 'A' && val <= 'Z')
            mode = MODE_SYMBOL;
        else if (val >= 'a' && val <= 'z')
            mode = MODE_SYMBOL;
        else if (val >= '0' && val <= '9')
            mode = MODE_NUMBER;
    }
    else if (mode == MODE_NUMBER)
    {
        if (val >= '0' && val <= '9')
            mode = MODE_NUMBER;
        else if (val == '_')
            mode = MODE_SYMBOL;
        else if (val >= 'A' && val <= 'Z')
            mode = MODE_SYMBOL;
        else if (val >= 'a' && val <= 'z')
            mode = MODE_SYMBOL;
        else
            mode = MODE_DELIMETER;
    }
    else // MODE_SYMBOL
    {
        if (val >= '0' && val <= '9')
            mode = MODE_SYMBOL;
        else if (val == '_')
            mode = MODE_SYMBOL;
        else if (val >= 'A' && val <= 'Z')
            mode = MODE_SYMBOL;
        else if (val >= 'a' && val <= 'z')
            mode = MODE_SYMBOL;
        else
            mode = MODE_DELIMETER;
    }
    return mode;
}

int CheckString(char *inptr, char *outptr)
{
    int i, mode, len;
    int prev_mode = MODE_DELIMETER;
    int changed = 0;

    while (*inptr)
    {
        mode = check_mode(*inptr, prev_mode);
        if (mode != MODE_SYMBOL || prev_mode == MODE_SYMBOL)
        {
            prev_mode = mode;
            *outptr++ = *inptr++;
            continue;
        }
        prev_mode = mode;
        for (i = 0; i < numsym; i++)
        {
            len = strlen(Symbol[i]);
            if (!strncmp(inptr, Symbol[i], len))
            {
                if (check_mode(inptr[len], mode) != MODE_SYMBOL) break;
            }
        }
        if (i < numsym)
        {
            changed = 1;
            strcpy(outptr, Symptr[i]);
            outptr += strlen(Symptr[i]);
            inptr += len;
        }
        else
            *outptr++ = *inptr++;
    }
    *outptr = 0;

    return changed;
}

void usage(void)
{
    printf("usage: prep file\n");
    exit(1);
}

int main(int argc, char **argv)
{
    FILE *infile;

#ifdef __P2GCC__
    sd_mount(58, 61, 59, 60);
    chdir(argv[argc]);
#endif

    if (argc != 2) usage();
    infile = fopen(argv[1], "r");
    if (!infile)
    {
        printf("Could not open %s\n", argv[1]);
        exit(1);
    }
    while (fgets(buffer, 1000, infile))
    {
        RemoveCRLF(buffer);
        if (!strncmp(buffer, "#define ", 8))
        {
            AddToTable(&buffer[8]);
            printf("\n");
        }
        else
        {
            while (CheckString(buffer, outbuf))
                strcpy(buffer, outbuf);
            printf("%s\n", outbuf);
        }
    }
    fclose(infile);
    return 0;
}
