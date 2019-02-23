/*
 *
 * Copyright (c) 2018 by Dave Hein
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "strsubs.h"

static char *Delimiters[] = {
    "@@@", "##", "#", ",", "[", "]", "++", "+", "--", "-", "<<",
    "<", ">>", "><", ">", "*", "/", "\\", "&", "|<", "|", "(", ")",
     "@", "==", "=", 0};

char *FindChar(char *str, int val)
{
    while (*str)
    {
	if (*str == val) break;
	str++;
    }
    return str;
}

char *SkipChars(char *str, char *chars)
{
    char *ptr;
    while (*str)
    {
	ptr = FindChar(chars, *str);
	if (*ptr == 0) break;
	str++;
    }
    return str;
}

char *FindChars(char *str, char *chars)
{
    char *ptr;
    while (*str)
    {
	ptr = FindChar(chars, *str);
	if (*ptr) break;
	str++;
    }
    return str;
}

int Tokenize(char *str, char **tokens, int maxnum, char *tokenbuf)
{
    char *ptr;
    int val, index, len, num = 0;

    while (*str)
    {
	str = SkipChars(str, " \t");
	val = *str;
	if (val == 0 || val == '\'') break;
        if (num >= maxnum - 1)
        {
            printf("Tokenize: too many tokens\n");
            return num;
        }
        if (*str == '"')
        {
            ptr = FindChar(str+1, '"');
            len = ptr - str + 1;
            if (*ptr) ptr++;
        }
        else if (*str == '{')
        {
            ptr = FindChar(str+1, '}');
            if (*ptr == 0) break;
            str = ptr + 1;
            continue;
        }
	else if ((index = SearchDelimiters(str)) >= 0)
        {
            len = strlen(Delimiters[index]);
            ptr = str + len;
        }
        else
        {
	    ptr = FindChars(str, " \t@#,[]+-<>*/&|()\"='");
            len = ptr - str;
        }
        tokens[num++] = tokenbuf;
        memcpy(tokenbuf, str, len);
        tokenbuf[len] = 0;
        tokenbuf += len + 1;
        str = ptr;
    }
#if 0
    {
        int i;
        for (i = 0; i < num; i++) printf("<%s>", tokens[i]);
        printf("\n");
    }
#endif
    return num;
}

int StrToBin(char *str)
{
    int value = 0;
    while ((str[0] & 0xfe) == '0' || str[0] == '_')
    {
	if (*str != '_') value = (value << 1) | (str[0] & 1);
	str++;
    }
    return value;
}

int StrToQuad(char *str)
{
    int value = 0;
    while ((str[0] & 0xfc) == '0' || str[0] == '_')
    {
	if (*str != '_') value = (value << 2) | (str[0] & 3);
	str++;
    }
    return value;
}

int StrToHex(char *str)
{
    int value = 0;

    while (1)
    {
        if (*str >= 'a' && *str <= 'f')
            value = (value << 4) | ((*str) - 'a' + 10);
        else if (*str >= 'A' && *str <= 'F')
            value = (value << 4) | ((*str) - 'A' + 10);
        else if (isdigit((int)(*str)))
            value = (value << 4) | ((*str) - '0');
        else if (*str != '_')
            break;
	str++;
    }

    return value;
}

int StrToDec(char *str)
{
    int value = 0;
    int sign = (*str == '-');

    str += sign;
    while (isdigit((int)(*str)) || *str == '_')
    {
	if (*str != '_') value = (value * 10) + ((*str) - '0');
	str++;
    }
    if (sign) value = -value;

    return value;
}

int StrToFlt(char *str)
{
    int retval;
    int pointflag = 0;
    double value = 0.0;
    double divisor = 1.0;
    float fretval;
    int sign = (*str == '-');

    str += sign;
    while (isdigit((int)(*str)) || *str == '_' || *str == '.')
    {
        if (*str == '.') pointflag = 1;
	else if (*str != '_')
        {
            if (pointflag) divisor *= 10.0;
            value = (value * 10.0) + ((*str) - '0');
        }
	str++;
    }
    value /= divisor;
    if (sign) value = -value;
    fretval = (float)value;
    memcpy(&retval, &fretval, 4);

    return retval;
}

int StrToDec1(char *str, int *is_float)
{
    char *ptr = FindChar(str, '.');

    if (*ptr)
    {
        *is_float = 1;
        return StrToFlt(str);
    }
    else
    {
        *is_float = 0;
        return StrToDec(str);
    }
}

int StrCompNoCase(char *str1, char *str2)
{
    while (*str1 && *str2)
    {
	if (toupper((int)(*str1++)) != toupper((int)(*str2++))) return 0;
    }
    if (*str1 || *str2) return 0;
    return 1;
}

void RemoveCRLF(char *buffer)
{
    int len = strlen(buffer);

    while (len > 0)
    {
	len--;
	if (buffer[len] != 10 && buffer[len] != 13) break;
	buffer[len] = 0;
    }
}

int SearchList(char **list, char *str)
{
    int i;

    for (i = 0; list[i]; i++)
    {
	if (StrCompNoCase(list[i], str)) return i;
    }

    return -1;
}

int SearchDelimiters(char *str)
{
    int i;

    for (i = 0; Delimiters[i]; i++)
    {
        if (strncmp(str, Delimiters[i], strlen(Delimiters[i])) == 0)
            return i;
    }

    return -1;
}

FILE *FileOpen(char *fname, char *mode)
{
    FILE *file = fopen(fname, mode);

    if (file == 0)
    {
	printf("ERROR: Could not open %s\n", fname);
	exit(1);
    }

    return file;
}

int CheckForUnicode(FILE *infile)
{
    int num;
    int unicode = 0;
    unsigned char buffer[2];

    num = fread(buffer, 1, 2, infile);

    if (num == 2 && buffer[0] == 0xff && buffer[1] == 0xfe) unicode = 1;

    fseek(infile, 0, SEEK_SET);

    return unicode;
}

int ReadString(char *buf, int size, FILE *infile, int unicode)
{
    int num;
    int count = 0;
    char *buf0 = buf;
    unsigned char bytepair[2];

    if (!unicode) {
        if (fgets(buf, size, infile))
            count = strlen(buf);
        else
            count = 0;
    }
    else
    {
        // Read unicode line
        while (count < size - 1)
        {
            num = fread(bytepair, 1, 2, infile);
            if (num != 2) break;
            if (bytepair[1] == 0)
                *buf++ = bytepair[0];
            else if (bytepair[0] == 0xff && bytepair[1] == 0xfe)
                continue;
            else if (bytepair[0] == 0x00 && bytepair[1] == 0x25)
                *buf++ = '-';
            else if (bytepair[0] == 0x02 && bytepair[1] == 0x25)
                *buf++ = '|';
            else
                *buf++ = '+';
            count++;
            if (buf[-1] == '\n') break;
        }
        *buf = 0;
    }
    if (!count)
        fseek(infile, 0, SEEK_SET);
    else
	RemoveCRLF(buf0);
    return count;
}
