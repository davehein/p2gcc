/*
 *
 * Copyright (c) 2018 - 2019 by Dave Hein
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

static char buffer1[1000];
static char buffer2[1000];

static int debugflag = 0;

FILE *infile;
FILE *outfile;

#ifdef __WATCOMC__
#define NEW_LINE "\n"
#else
#define NEW_LINE "\r\n"
#endif

void ReplaceString(char *str1, char *str2)
{
    char *instr = buffer1;
    char *outstr = buffer2;
    while (*instr)
    {
        if (!strncmp(instr, str1, strlen(str1)))
        {
            strcpy(outstr, str2);
            instr += strlen(str1);
            outstr += strlen(str2);
        }
        else
            *outstr++ = *instr++;
    }
    *outstr = 0;
    strcpy(buffer1, buffer2);
}

void ProcessAscii(void)
{
    int quote = 0;
    int comma = 0;
    char *instr = buffer1;
    char *outstr = buffer2;

    strcpy(outstr, "\tbyte ");
    outstr += 6;
    instr += 8;

    while (*instr)
    {
        if (*instr == '"')
        {
            if (quote)
            {
                quote = 0;
                *outstr++ = *instr++;
                continue;
            }
            else
            {
                instr++;
                continue;
            }
        }
        if (*instr == '\\')
        {
            int value = 0;
            if (quote)
            {
                *outstr++ = '"';
                quote = 0;
                comma = 1;
            }
            if (comma)
            {
                comma = 0;
                *outstr++ = ',';
                *outstr++ = ' ';
            }
            instr++;
            if (*instr >= '0' && *instr <= '7')
            {
                while (*instr >= '0' && *instr <= '7')
                {
                    value = (value << 3) + *instr - '0';
                    instr++;
                }
            }
            else
            {
                if (*instr == 't') value = 9;
                else if (*instr == 'n') value = 10;
                else if (*instr == 'r') value = 13;
                else value = *instr;
                instr++;
            }
            sprintf(outstr, "%d", value);
            outstr += strlen(outstr);
            comma = 1;
            continue;
        }
        if (!quote)
        {
            quote = 1;
            if (comma)
            {
                *outstr++ = ',';
                comma = 0;
            }
            *outstr++ = '"';
        }
        *outstr++ = *instr++;
    }
    *outstr = 0;
    strcpy(buffer1, buffer2);
}

char *FindChar(char *str, int val)
{
    while (*str)
    {
        if (*str == val) break;
        str++;
    }
    return str;
}

char *FindString(char *str1, char *str2)
{
    while (*str1)
    {
        if (!strncmp(str1, str2, strlen(str2))) break;
        str1++;
    }
    return str1;
}

char *SkipWhiteSpace(char *ptr)
{
    while (*ptr)
    {
        if (*ptr != ' ' && *ptr != '\t') break;
        ptr++;
    }
    return ptr;
}

char *FindWhiteSpace(char *ptr)
{
    while (*ptr)
    {
        if (*ptr == ' ' || *ptr == '\t') break;
        ptr++;
    }
    return ptr;
}

int CheckMova(void)
{
    char *ptr1, *ptr2;

    ptr1 = FindString(buffer1, "mova");
    if (!*ptr1) return 0;

    ptr2 = FindChar(ptr1, '#');
    if (!*ptr2) return 0;
    ptr1[3] = 0;
    ptr2[0] = 0;
    fprintf(outfile, "%s%s##%s%s", buffer1, ptr1+4, ptr2+1, NEW_LINE);
    return 1;
}

int CheckWaitcnt(void)
{
    char *ptr1;

    ptr1 = FindString(buffer1, "waitcnt");
    if (!*ptr1) return 0;
    ReplaceString("waitcnt", "addct1");
    fprintf(outfile, "%s%s", buffer1, NEW_LINE);
    fprintf(outfile, "\twaitct1%s", NEW_LINE);
    return 1;
}

int CheckCoginit(void)
{
    char *ptr1, *ptr2;

    ptr1 = FindString(buffer1, "coginit");
    if (!*ptr1) return 0;
    ptr1 += 8;
    ptr2 = FindWhiteSpace(ptr1);
    *ptr2 = 0;
    fprintf(outfile, "\tmov\ttemp, %s%s", ptr1, NEW_LINE);
    fprintf(outfile, "\tmov\ttemp1, %s%s", ptr1, NEW_LINE);
    fprintf(outfile, "\tmov\ttemp2, %s%s", ptr1, NEW_LINE);
    fprintf(outfile, "\tand\ttemp2, #7%s", NEW_LINE);
    fprintf(outfile, "\tshr\ttemp1, #2%s", NEW_LINE);
    fprintf(outfile, "\tand\ttemp1, ##$fffc%s", NEW_LINE);
    fprintf(outfile, "\tshr\ttemp, #16%s", NEW_LINE);
    fprintf(outfile, "\tand\ttemp, ##$fffc%s", NEW_LINE);
    fprintf(outfile, "\tsetq\ttemp%s", NEW_LINE);
    fprintf(outfile, "\tcoginit\ttemp2, temp1%s", NEW_LINE);
    return 1;
}

int CheckCNTSource(void)
{
    int len = strlen(buffer1);

    if (len < 7) return 0;
    if (strcmp(&buffer1[len-5], ", CNT")) return 0;
    buffer1[len-5] = 0;
    if (!strncmp(buffer1, "\tmov\t", 5))
    {
        fprintf(outfile, "\tgetct\t%s%s", &buffer1[5], NEW_LINE);
    }
    else
    {
        fprintf(outfile, "\tgetct\ttemp%s", NEW_LINE);
        fprintf(outfile, "%s, temp%s", buffer1, NEW_LINE);
    }
    return 1;
}

int CheckCNTDest(void)
{
    char *ptr1;

    ptr1 = FindString(buffer1, "wrlong\tCNT,");
    if (!*ptr1) return 0;
    ptr1[7] = 0;
    ptr1 += 10;

    fprintf(outfile, "\tgetct\ttemp%s", NEW_LINE);
    fprintf(outfile, "%stemp%s%s", buffer1, ptr1, NEW_LINE);

    return 1;
}

int CheckNR(void)
{
    char *ptr1, *ptr2;
    int len = strlen(buffer1);

    if (len < 5) return 0;
    if (strcmp(&buffer1[len-3], ",nr")) return 0;

    ptr1 = SkipWhiteSpace(buffer1);
    if (!*ptr1) return 0;
    if (!strncmp(ptr1, "IF_", 3))
    {
        ptr1 = FindWhiteSpace(ptr1);
        ptr1 = SkipWhiteSpace(ptr1);
        if (!*ptr1) return 0;
    }
    ptr1 = FindWhiteSpace(ptr1);
    ptr1 = SkipWhiteSpace(ptr1);
    if (!*ptr1) return 0;
    ptr2 = FindChar(ptr1, ',');
    if (!*ptr2) return 0;
    *ptr2++ = 0;
    buffer1[len-3] = 0;
    fprintf(outfile, "\tmov\ttemp, %s%s", ptr1, NEW_LINE);
    *ptr1 = 0;
    fprintf(outfile, "%stemp,%s%s", buffer1, ptr2, NEW_LINE);
    return 1;
}

int IsHubVariable(char *ptr)
{
    int i;
    char *regname[] = {
        "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11",
        "r12", "r13", "r14", "sp", "lr", "temp", "temp1", "temp2", "__has_cordic",
        "CNT", "INA", "INB", "OUTA", "OUTB", "DIRA", "DIRB",
        "cnt", "ina", "inb", "outa", "outb", "dira", "dirb",
        "ijmp1", "ijmp2", "ijmp3", "iret1", "iret2", "iret3",
        "ptra", "ptrb",  "pa", "pb", 0};

    if (*ptr == '#') return 0;

    for (i = 0; regname[i]; i++)
    {
        if (!strcmp(ptr, regname[i])) return 0;
    }
    return 1;
}

int CheckSourceDest(void)
{
    int len;
    int both = 0;
    char *com_ptr, *temp_ptr, *op_ptr, *src_ptr, *dst_ptr, *rem_ptr;
    char first[100];
    char last[100];
    char buffer3[1000];
    int srcflag = 0;
    int dstflag = 0;

    strcpy(buffer3, buffer1);
    temp_ptr = SkipWhiteSpace(buffer3);
    if (temp_ptr == buffer3) return 0;
    if (!strncmp(temp_ptr, "IF_", 3) || !strncmp(temp_ptr, "if_", 3))
    {
        op_ptr = FindWhiteSpace(temp_ptr);
        op_ptr = SkipWhiteSpace(op_ptr);
    }
    else
        op_ptr = temp_ptr;
    if (!*op_ptr) return 0;
    temp_ptr = FindWhiteSpace(op_ptr);
    if (!*temp_ptr) return 0;
    *temp_ptr++ = 0;
    dst_ptr = SkipWhiteSpace(temp_ptr);
    if (!*dst_ptr) return 0;
    com_ptr = FindChar(dst_ptr, ',');
    if (!*com_ptr) return 0;
    temp_ptr = FindWhiteSpace(dst_ptr);
    if (com_ptr - temp_ptr < 0) temp_ptr = com_ptr;
    src_ptr = SkipWhiteSpace(com_ptr+1);
    if (!*src_ptr) return 0;
    *temp_ptr = 0;
    rem_ptr = FindWhiteSpace(src_ptr);
    if (*rem_ptr)
    {
        *rem_ptr++ = 0;
        rem_ptr = SkipWhiteSpace(rem_ptr);
    }
    if (*rem_ptr)
    {
        strcpy(last, " ");
        strcat(last, rem_ptr);
    }
    else
        last[0] = 0;
    len = op_ptr - buffer3;
    memcpy(first, buffer3, len);
    first[len] = 0;

    //printf("<%s><%s> <%s>,<%s> %s\n", first, op_ptr, dst_ptr, src_ptr, rem_ptr);

    srcflag = IsHubVariable(src_ptr);
    dstflag = IsHubVariable(dst_ptr);
    both = srcflag & dstflag;
    if (!srcflag && !dstflag) return 0;

    if (!strcmp(op_ptr, ".set")) return 0;
    if (!strcmp(op_ptr, ".equ")) return 0;
    if (!strcmp(op_ptr, "jmp")) return 0;
    if (!strcmp(op_ptr, "djnz")) return 0;
    if (!strcmp(op_ptr, "call")) return 0;
    if (!strcmp(op_ptr, "calld")) return 0;
    if (!strcmp(op_ptr, "long")) return 0;
    if (both && strcmp(op_ptr, "wrlong"))
    {
        printf("ERROR: two .L labels, but opcode is not wrlong\n");
        exit(1);
    }

    if (!strcmp(op_ptr, "mov"))
    {
        if (both)
        {
            fprintf(outfile, "%srdlong\t%s, ##%s%s", first, "temp", src_ptr, NEW_LINE);
            fprintf(outfile, "%swrlong\t%s, ##%s%s", first, "temp", dst_ptr, NEW_LINE);
        }
        else if (srcflag)
            fprintf(outfile, "%srdlong\t%s, ##%s%s%s", first, dst_ptr, src_ptr, last, NEW_LINE);
        else
            fprintf(outfile, "%swrlong\t%s, ##%s%s%s", first, src_ptr, dst_ptr, last, NEW_LINE);
    }
    else
    {
        if (both)
        {
            fprintf(outfile, "%srdlong\ttemp, ##%s%s", first, dst_ptr, NEW_LINE);
            fprintf(outfile, "%srdlong\ttemp1, ##%s%s", first, src_ptr, NEW_LINE);
            fprintf(outfile, "%s%s\ttemp, temp1%s%s", first, op_ptr, last, NEW_LINE);
            //fprintf(outfile, "%swrlong\t%s, ##%s%s", first, "temp", dst_ptr, NEW_LINE);
        }
        else if (srcflag)
        {
            fprintf(outfile, "%srdlong\ttemp, ##%s%s", first, src_ptr, NEW_LINE);
            fprintf(outfile, "%s%s\t%s, temp%s%s", first, op_ptr, dst_ptr, last, NEW_LINE);
        }
        else
        {
            fprintf(outfile, "%srdlong\ttemp, ##%s%s", first, dst_ptr, NEW_LINE);
            fprintf(outfile, "%s%s\ttemp, %s%s%s", first, op_ptr, src_ptr, last, NEW_LINE);
            //fprintf(outfile, "%swrlong\t%s, ##%s%s", first, "temp", dst_ptr, NEW_LINE);
        }
    }

    return 1;
}

FILE *OpenFile(char *fname, char *mode)
{
    FILE *iofile;

    iofile = fopen(fname, mode);
    if (iofile) return iofile;

    printf("Could not open %s\n", fname);
    exit(1);
    return 0;
}

void RemoveCRLF(char *str)
{
    int len = strlen(str);
    str += len - 1;
    while (len-- && (*str == 10 || *str == 13)) *str-- = 0;
}

void ProcessComm(void)
{
    int len;
    char *ptr = FindChar(buffer1, ',');
    fprintf(outfile, "%s%s", buffer1, NEW_LINE);
    if (*ptr) *ptr++ = 0;
    fprintf(outfile, "%s%s", &buffer1[7], NEW_LINE);
    sscanf(ptr, "%d", &len);
    if (len <= 4)
        fprintf(outfile, "\tlong\t0%s", NEW_LINE);
    else
        fprintf(outfile, "\tlong\t0[%d]%s", (len+3)/4, NEW_LINE);
}

void ProcessZero(void)
{
    int len;
    sscanf(&buffer1[6], "%d", &len);
    if (len <= 4)
        fprintf(outfile, "\tlong\t0%s", NEW_LINE);
    else
        fprintf(outfile, "\tlong\t0[%d]%s", (len+3)/4, NEW_LINE);
}

void CheckLocalName(void)
{
    char *ptr = buffer1;

    while (*ptr)
    {
        ptr = FindChar(ptr, '.');
        if (!*ptr) break;
        if (ptr != buffer1 && isdigit((int)ptr[1]) &&
            (ptr[-1] == '_' || isdigit((int)ptr[-1]) || isalpha((int)ptr[-1]))) *ptr = '_';
        ptr++;
    }
}

void usage(void)
{
    printf("s2pasm - a utility to convert from P1 to P2 assembly - version 0.005, 2019-1-12\n");
    printf("usage: s2pasm [options] filename\n");
    printf("  options are\n");
    printf("  -d      - Debug mode\n");
    printf("  -p file - Specify prefix file name\n");
    exit(1);
}

int main(int argc, char **argv)
{
    int argi;
    char *extptr;
    FILE *prefile;
    char fname[100];
    char *pfname = 0;

    fname[0] = 0;
    for (argi = 1; argi < argc; argi++)
    {
        if (argv[argi][0] == '-')
        {
            if (!strcmp(argv[argi], "-d"))
                debugflag = 1;
            else if (argv[argi][1] == 'p')
            {
                if (argv[argi][2])
                    pfname = &argv[argi][2];
                else if (argi < argc - 1)
                    pfname = argv[++argi];
                else
                    usage();
            }
            else
                usage();
        }
        else
        {
            if (fname[0]) usage();
            strcpy(fname, argv[argi]);
        }
    }
    if (!fname[0]) usage();

    extptr = FindChar(fname, '.');
    if (!*extptr) strcpy(extptr, ".s");
    infile = OpenFile(fname, "r");
    strcpy(extptr, ".spin2");
    outfile = OpenFile(fname, "w");

    if (pfname)
    {
        prefile = OpenFile(pfname, "r");
        while (fgets(buffer1, 1000, prefile))
        {
            RemoveCRLF(buffer1);
            fprintf(outfile, "%s%s", buffer1, NEW_LINE);
        }
        fclose(prefile);
    }

    while (fgets(buffer1, 1000, infile))
    {
        RemoveCRLF(buffer1);
        if (!strncmp(buffer1, "\t.ascii \"", 8))
        {
            ProcessAscii();
            fprintf(outfile, "%s%s", buffer1, NEW_LINE);
            continue;
        }
        CheckLocalName();
        if (!strncmp(buffer1, "\t.comm\t", 7))
        {
            ProcessComm();
            continue;
        }
        if (!strncmp(buffer1, "\t.zero\t", 7))
        {
            ProcessZero();
            continue;
        }
        ReplaceString("wz,wc", "wcz");
        ReplaceString("\tmax\t", "\tfle\t");
        ReplaceString("\tmaxs\t", "\tfles\t");
        ReplaceString("\tmin\t", "\tfge\t");
        ReplaceString("\tmins\t", "\tfges\t");
        ReplaceString(" max\t", " fle\t");
        ReplaceString(" maxs\t", " fles\t");
        ReplaceString(" min\t", " fge\t");
        ReplaceString(" mins\t", " fges\t");
        //ReplaceString(".L", "_L");
        //ReplaceString(".balign\t4", "alignl");
        //ReplaceString(".balign\t2", "alignw");
        ReplaceString("0x", "$");
        ReplaceString("jmpret", "calld");
        ReplaceString("__MASK_", "##$");
        if (CheckMova()) continue;
        if (CheckWaitcnt()) continue;
        if (CheckCoginit()) continue;
        if (!strncmp(buffer1, "\tlong\t.L", 8))
        {
            fprintf(outfile, "\tlong\t%s%s", &buffer1[6], NEW_LINE);
            continue;
        }
        if (!strcmp(buffer1, "\tlong\t__clkfreq"))
        {
            fprintf(outfile, "\tlong\t%s%s", &buffer1[6], NEW_LINE);
            continue;
        }
        if (CheckSourceDest()) continue;
        if (CheckNR()) continue;
	if (CheckCNTSource()) continue;
	if (CheckCNTDest()) continue;
        fprintf(outfile, "%s%s", buffer1, NEW_LINE);
    }
    fclose(infile);
    fclose(outfile);
    return 0;
}
