//******************************************************************************
// Copyright (c) 2014 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <propeller.h>

void New(void);
void List(void);
void Help(void);
void Dump(void);
void ClearVars(void);
int Expression(int prec);
int Execute(int cmdnum);

/* INLINE SPIN
CON
  _clkmode = xinput
  _xinfreq = $4e495053 ' SPIN
*/
// SPIN OBJECT c   : "cliboslt"
void enter(void);
FILE *getstdin(void);
int  getconfig(void);

// SPIN OBJECT mem : "cmalloc"
#ifdef CSPIN_FLAG
void mallocinit(int num);
void *malloc(int size);
void free(void *ptr);
#endif

#ifdef CSPIN_FLAG
// SPIN OBJECT ste : "streng"
#include "streng.h"
void ste_start(void);
#endif

// SPIN OBJECT

#ifdef CSPIN_FLAG
#define stdin getstdin()

void start(int argc, char **argv)
{
    int temp;

    mallocinit(200);
    enter();
    temp = (getconfig() >> 8) & 255;
    if (temp) numlines = temp;
    ste_start();
    main(argc, argv);
}
#endif

#if 0 //ndef CSPIN_FLAG
#define MAX_LINES    10000
#define MAX_CHARS    200
#define MAX_GOSUBS   100
#define VAR_BUF_SIZE 1000
#define MAX_TOKENS   500
#else
#define MAX_LINES    1000
#define MAX_CHARS    200
#define MAX_GOSUBS   20
#define VAR_BUF_SIZE 200
#define MAX_TOKENS   100
#endif
#define MAX_PREC     999
#define MAX_VARS     32
#define VAR_MASK     (MAX_VARS - 1)
#define DOUBLE_QUOTE 0x22
#define SINGLE_QUOTE 0x27
#define TAB_CHAR     9

#define CMD_RUN      0
#define CMD_LIST     1
#define CMD_NEW      2
#define CMD_BYE      3
#define CMD_SAVE     4
#define CMD_OLD      5
#define CMD_HELP     6
#define CMD_DUMP     7
#define CMD_END      8
#define CMD_STOP     9
#define CMD_REM      10
#define CMD_RETURN   11
#define CMD_INPUT    12
#define CMD_IF       13
#define CMD_PRINT    14
#define CMD_GOTO     15
#define CMD_GOSUB    16
#define CMD_FOR      17
#define CMD_NEXT     18
#define CMD_DIM      19

#ifdef CSPIN_FLAG
char delim[] = {';', SINGLE_QUOTE, ':', '(', ')', ',', '=', '+',
    '-', '*', '/', '<', '>', DOUBLE_QUOTE, ' ', TAB_CHAR, '#', '@', 0;
#else
char *delim = ";':(),=+-*/<>\" \t#@";
#endif
char *ops[] = {"<>", "<=", ">=", 0};
char opprec[] = {1, 1, 2, 2, 2, 2, 3, 3, 4, 4};
char *oplist[] = {"=", "<>", "<", ">", "<=", ">=", "+", "-", "*", "/", 0};
char *commands[] = {"run", "list", "new", "bye", "save", "old", "help", "dump",
    "end", "stop", "rem", "return", "input", "if", "print", "goto", "gosub",
    "for", "next", "dim", 0};

int baseaddr = 0;

int gosub_index = 0;
int gosub_tokenum[MAX_GOSUBS];
int gosub_linenum[MAX_GOSUBS];

int runmode;
int linenum;
int tokenum;
int needline;
//FILE *infile = 0;
int numlines = 24;
char buff[MAX_CHARS];
int var_buf[VAR_BUF_SIZE];
char *program[MAX_LINES+1];
int vars[MAX_VARS], var_limit[MAX_VARS];
int var_linenum[MAX_VARS], var_tokenum[MAX_VARS];

int numtokens;
char *tokens[MAX_TOKENS];
char tokenbuf[MAX_CHARS*2];

int iabs(int val)
{
    if (val >= 0) return val;
    return -val;
}

#ifdef CSPIN_FLAG
int atol(char *str)
{
    int val;
    sscanf(str, "%d", @val);
    return val;
}
#endif

int CheckVar(char *str)
{
    if (!strcmp(str, "@")) return 0;
    if (strlen(str) != 1 || str[0] < 'a' || str[0] > 'z')
    {
        printf("Bad Variable -- %s\n", str);
        return 1;
    }
    return 0;
}

int GetIndex(void)
{
    int idx;
#if 0
    int checkmax = (tokens[tokenum][0] == '@');
    static int maxval = 150;
#endif
    if (CheckVar(tokens[tokenum])) return -1;
    idx = tokens[tokenum++][0] & VAR_MASK;
    if (vars[idx] < 0) vars[idx] = baseaddr++;
    idx = vars[idx];
    if (tokenum < numtokens && tokens[tokenum][0] == '(')
        idx += Expression(MAX_PREC);
    if (idx < 0 || idx >= VAR_BUF_SIZE) printf("GetIndex: idx = %d\n", idx);
#if 0
    if (checkmax && idx > maxval)
    {
        maxval = idx;
        printf("New maxval = %d\n", maxval);
    }
#endif
    return idx;
}

#ifndef CSPIN_FLAG
char *FindChar(char *str, int val)
{
    while (*str)
    {
        if (*str == val) break;
        str++;
    }
    return str;
}

char *SkipChar(char *str, int val)
{
    while (*str)
    {
        if (*str != val) break;
        str++;
    }
    return str;
}

int SearchListN(char **list, char *str)
{
    int i;
    for (i = 0; list[i]; i++)
    {
        if (!strncmp(str, list[i], strlen(list[i]))) return i;
    }
    return -1;
}

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
#endif

void Tokenize(char *ptr)
{
    int i, len;
    char *ptr1;
    int quoteflag;
    char *tokenptr = tokenbuf;
    numtokens = 0;
    while (*ptr)
    {
        quoteflag = 0;
        ptr1 = SkipChar(ptr, ' ');
        if (!*ptr1) break;
        ptr = FindChar(delim, *ptr1);
        if (*ptr)
        {
            if (*ptr1 == DOUBLE_QUOTE)
            {
                quoteflag = 1;
                ptr = FindChar(ptr1 + 1, DOUBLE_QUOTE);
            }
            else
            {
                i = SearchListN(ops, ptr1);
                if (i >= 0)
                    ptr = ptr1 + strlen(ops[i]);
                else
                    ptr = ptr1 + 1;
            }
        }
        else
        {
            ptr = FindChars(ptr1, delim);
        }
        len = ptr - ptr1;
        if (quoteflag && *ptr == DOUBLE_QUOTE) ptr++;
        memcpy(tokenptr, ptr1, len);
        tokens[numtokens++] = tokenptr;
        tokenptr += len;
        *tokenptr++ = 0;
        if (numtokens == 1 && isdigit((int)tokens[0][0]))
        {
            if (*ptr == ' ') ptr++;
            if (*ptr)
            {
                strcpy(tokenptr, ptr);
                tokens[numtokens++] = tokenptr;
            }
            break;
        }
    }
}

#if 0
void PrintTokens()
{
    int i;
    for (i = 0; i < numtokens; i++) printf("%s", tokens[i]);
    printf("\n");
}
#endif

#ifndef CSPIN_FLAG
int SearchList(char **list, char *str)
{
    int i;

    for (i = 0; list[i]; i++)
    {
        if (!strcmp(list[i], str)) return i;
    }

    return -1;
}
#endif

int GetOpPrecedence(char *op)
{
    int i = SearchList(oplist, op);
    if (i < 0) return -1;
    return opprec[i];
}

int EvalBinaryOp(char *op, int l1, int l2)
{
    int value = 0;
    int i = SearchList(oplist, op);

    switch (i)
    {
#ifdef CSPIN_FLAG
        case 0: value = (l1 == l2) & 1; break;
        case 1: value = (l1 != l2) & 1; break;
        case 2: value = (l1 <  l2) & 1; break;
        case 3: value = (l1 >  l2) & 1; break;
        case 4: value = (l1 <= l2) & 1; break;
        case 5: value = (l1 >= l2) & 1; break;
#else
        case 0: value = l1 == l2; break;
        case 1: value = l1 != l2; break;
        case 2: value = l1 <  l2; break;
        case 3: value = l1 >  l2; break;
        case 4: value = l1 <= l2; break;
        case 5: value = l1 >= l2; break;
#endif
        case 6: value = l1 +  l2; break;
        case 7: value = l1 -  l2; break;
        case 8: value = l1 *  l2; break;
        case 9: value = l1 /  l2; break;
    }

    return value;
}

int Expression(int prec)
{
    char *op;
    int value, this_prec;

    if (tokens[tokenum][0] == '-')
    {
        tokenum++;
        value = -Expression(MAX_PREC);
    }
    else if (isdigit((int)tokens[tokenum][0]))
    {
        value = atol(tokens[tokenum++]);
    }
    else if (tokens[tokenum][0] == '(')
    {
        tokenum++;
        value = Expression(0);
        tokenum++;
    }
    else if (!strcmp(tokens[tokenum], "rnd"))
    {
        tokenum++;
        value = Expression(MAX_PREC);
        value = (rand() & 0x7fffffff) % value;
    }
    else if (!strcmp(tokens[tokenum], "abs"))
    {
        tokenum++;
        value = iabs(Expression(MAX_PREC));
    }
    else if (!strcmp(tokens[tokenum], "asc"))
    {
        tokenum += 2;
        value = tokens[tokenum][1];
        tokenum += 2;
    }
    else
    {
        value = var_buf[GetIndex()];
    }

    while (tokenum < numtokens - 1)
    {
        this_prec = GetOpPrecedence(tokens[tokenum]);
        if (this_prec <= 0 || this_prec < prec) break;
        op = tokens[tokenum++];
        value = EvalBinaryOp(op, value, Expression(this_prec + 1));
    }

    return value;
}

void PrintString(char *str)
{
    printf("%s", str+1);
}

int NumDigits(int value)
{
    int digits = 1;

    if (value < 0)
    {
        value = -value;
        digits++;
    }

    while (value >= 10)
    {
        digits++;
        value /= 10;
    }

    return digits;
}

void Print(void)
{
    int width = 1;
    int column = 0;
    int spaces = 0;
    int newline = 1;
    int value, digits;

    while (tokenum < numtokens && tokens[tokenum][0] != ':')
    {
        if (tokens[tokenum][0] == '#')
        {
            tokenum++;
            width = Expression(0);
        }
        else if (tokens[tokenum][0] == DOUBLE_QUOTE)
        {
            column += spaces;
            while (spaces-- > 0) printf(" ");
            PrintString(tokens[tokenum]);
            column += strlen(tokens[tokenum]) - 1;
            spaces = 1;
            newline = 1;
            tokenum++;
        }
        else if (tokens[tokenum][0] == ',')
        {
            spaces = 8 - (column % 8);
            newline = 0;
            tokenum++;
        }
        else if (tokens[tokenum][0] == ';')
        {
            spaces = 0;
            newline = 0;
            tokenum++;
        }
        else
        {
            value = Expression(0);
            digits = NumDigits(value);
            if (digits < width) spaces += width - digits;
            column += spaces + digits;
            while (spaces-- > 0) printf(" ");
            printf("%d", value);
            spaces = 1;
            newline = 1;
            width = 1;
        }
    }

    if (newline)
        printf("\n");
}

void AddLine(void)
{
    int i = atol(tokens[0]);

    //printf("AddLine: %d\n", i);

    if (i <= 0 || i >= MAX_LINES) return;

    if (program[i]) free(program[i]);
    program[i] = 0;

    if (numtokens == 2)
    {
        program[i] = malloc(strlen(tokens[1]) + 1);
        strcpy(program[i], tokens[1]);
    }
    tokenum = numtokens;
}

void RemoveCRLF(char *ptr)
{
    int len = strlen(ptr);

    while (len--)
    {
        if (ptr[len] != 13 && ptr[len] != 10) break;
        ptr[len] = 0;
    }
}

#if 0
void OpenInputFile(char *fname)
{
    if (infile && infile != stdin) fclose(infile);
    infile = fopen(fname, "r");
    if (!infile) infile = stdin;
}

void SaveFile(char *fname)
{
    int i;
    FILE *outfile = fopen(fname, "w");
    for(i = 0; i < MAX_LINES; i++)
    {
        if (program[i])
            fprintf(outfile, "%d %s\n", i, program[i]);
    }
    fclose(outfile);
}
#endif

int EndOfLine(void)
{
    if (tokenum >= numtokens) return 1;

    if (tokens[tokenum][0] == ':')
    {
        tokenum++;
        if (tokenum >= numtokens) return 1;
    }

    return 0;
}

int CheckLine(void)
{
    if (EndOfLine())
    {
        linenum++;
        tokenum = 0;
        return 1;
    }
    return 0;
}

void PrintStatement()
{
    int i;
    printf("\n%d-%d: ", linenum, tokenum);
    for (i = tokenum; i < numtokens && tokens[i][0] != ':'; i++)
        printf("%s", tokens[i]);
    printf("\n");
}

void Run(void)
{
    tokenum = 0;
    linenum = 1;
    runmode = 1;
    needline = 1;

    ClearVars();
}

#if 0
void GetFileName(char *ptr)
{
    *ptr = 0;
    while (tokenum < numtokens)
    {
        if (tokens[tokenum][0] == ';')
        {
            tokenum++;
            break;
        }
        strcat(ptr, tokens[tokenum++]);
    }
}
#endif

int Execute(int cmdnum)
{
    char in_buff[20];
    int i, j, linenew;

    switch (cmdnum)
    {
        case CMD_RUN:
            Run();
            //tokenum++;
            break;
        case CMD_LIST:
            List();
            tokenum++;
            break;
        case CMD_NEW:
            New();
            return 0;
            break;
        case CMD_BYE:
            New();
#ifdef CSPIN_FLAG
            stop();
#endif
            exit(0);
#if 0
        case CMD_SAVE:
            tokenum++;
            GetFileName(in_buff);
            SaveFile(in_buff);
            break;
        case CMD_OLD:
            tokenum++;
            GetFileName(in_buff);
            OpenInputFile(in_buff);
            break;
#endif
        case CMD_HELP:
            Help();
            tokenum++;
            break;
        case CMD_DUMP:
            Dump();
            tokenum++;
            break;
        case CMD_END:
            return 0;
        case CMD_STOP:
            return 0;
        case CMD_REM:
            tokenum = numtokens;
            break;
        case CMD_RETURN:
            if (runmode)
            {
                linenum = gosub_linenum[--gosub_index];
                tokenum = gosub_tokenum[gosub_index];
                needline = 1;
            }
            break;
        case CMD_INPUT:
            if (tokens[++tokenum][0] == DOUBLE_QUOTE)
            {
                PrintString(tokens[tokenum++]);
                if (tokens[tokenum][0] == ',') tokenum++;
            }
            i = GetIndex();
            if (i < 0) return 0;
#if 0
            fgets(in_buff, sizeof(in_buff) - 2, stdin);
#else
            gets(in_buff);
#endif
            var_buf[i] = isdigit((int)*in_buff) ? atol(in_buff) : *in_buff;
            break;
        case CMD_IF:
            tokenum++;
            if (Expression(0))
            {
                if (!strcmp(tokens[tokenum], "then"))
                    tokenum++;
            }
            else
            {
                tokenum = numtokens;
            }
            break;
        case CMD_PRINT:
            tokenum++;
            Print();
            break;
        case CMD_GOTO:
            tokenum++;
            //linenum = Expression(0);
            //needline = 1;
            linenew = Expression(0);
            if (linenew != linenum)
            {
                linenum = linenew;
                needline = 1;
            }
            tokenum = 0;
            runmode = 1;
            break;
        case CMD_GOSUB:
            tokenum++;
            linenew = Expression(0);
            if (runmode)
            {
                CheckLine();
                gosub_linenum[gosub_index] = linenum;
                gosub_tokenum[gosub_index++] = tokenum;
            }
            tokenum = 0;
            linenum = linenew;
            needline = 1;
            runmode = 1;
            break;
        case CMD_FOR:
            i = tokens[++tokenum][0] & VAR_MASK;
            j = GetIndex();
            if (j < 0) return 0;
            if (tokens[tokenum++][0] != '=')
            {
                 printf("Invalid statement in line %d\n", linenum);
                 return 0;
            }
            var_buf[j] = Expression(0);
            if (!strcmp(tokens[tokenum], "to")) tokenum++;
            var_limit[i] = Expression(0);
            needline = CheckLine();
            var_linenum[i] = linenum;
            var_tokenum[i] = tokenum;
            return 1;
        case CMD_NEXT:
            i = tokens[++tokenum][0] & VAR_MASK;
            j = GetIndex();
            if (j < 0) return 0;
            if (runmode && ++var_buf[j] <= var_limit[i])
            {
                linenew = var_linenum[i];
                tokenum = var_tokenum[i];
                if (linenew != linenum)
                {
                    linenum = linenew;
                    needline = 1;
                }
            }
            else
                tokenum++;
            break;
        case CMD_DIM:
            if (CheckVar(tokens[++tokenum])) return 0;
            i = tokens[tokenum++][0] & VAR_MASK;
            if (vars[i] >= 0)
            {
                printf("Variable already defined in line %d\n", linenum);
                return 0;
            }
            vars[i] = baseaddr;
            if (tokens[tokenum][0] == '(')
                baseaddr += Expression(MAX_PREC);
            else
                baseaddr++;
            //printf("baseaddr = %d\n", baseaddr);
            break;
        default:
            if (isdigit((int)tokens[tokenum][0]))
            {
                AddLine();
            }
            else
            {
                if (!strcmp(tokens[tokenum], "let")) tokenum++;
                i = GetIndex();
                if (i < 0) return 0;
                if (tokens[tokenum++][0] != '=')
                {
                     printf("Invalid statement in line %d\n", linenum);
                     return 0;
                }
                var_buf[i] = Expression(0);
            }
    }
    return 1;
}

void List(void)
{
    int i, line, val;

    line = 0;
    for(i = 0; i < MAX_LINES; i++)
    {
        if (program[i])
        {
            printf("%d %s\n", i, program[i]);
            if (++line >= numlines - 1)
            {
                printf("<more>");
                val = getchar();
                printf("\b\b\b\b\b\b      \b\b\b\b\b\b");
                if (val == 'q' || val == 3)
                    break;
                else if (val == 13)
                    line--;
                else
                    line = 0;
            }

        }
    }
}

void ClearVars(void)
{
    int i;

    baseaddr = 0;
    for (i = 0; i < MAX_VARS; i++) vars[i] = -1;
}

void New(void)
{
    int i;

    ClearVars();

    for(i = 0; i < MAX_LINES; i++) 
    {
        if (program[i])
        {
            free(program[i]);
            program[i] = 0;
        }
    }
}

void Help(void)
{
    //printf("Commands are help, run, list, new, bye, save, old or statement\n");
    printf("Commands are help, run, list, new, bye or statement\n");
}

void Dump(void)
{
    int i;
    for (i = 0; i < MAX_VARS; i++)
    {
        if (vars[i] >= 0) printf("%c: %d\n", '@'+i, vars[i]);
    }
    //printf("baseaddr = %d\n", baseaddr);
}

void GetLine(void)
{
    while (1)
    {
        if (!runmode)
        {
#if 0
            if (infile != stdin)
            {
                if (fgets(buff, MAX_CHARS, infile))
                    RemoveCRLF(buff);
                else
                {
                    fclose(infile);
                    infile = stdin;
                }
            }
            if (infile == stdin)
#endif
            {
                puts("Ok");
                gets(buff);
            }
            Tokenize(buff);
            tokenum = 0;
            linenum = 0;
        }
        else
        {
            while(!program[linenum]) linenum++;
            Tokenize(program[linenum]);
            if (numtokens == 0)
            {
                tokenum = 0;
                linenum++;
            }
        }
        if (tokenum < numtokens) break;
    }
    needline = 0;
}

void SetInterpMode(void)
{
    runmode = 0;
    needline = 1;
}

int main(int argc, char **argv)
{
    int i;

    waitcnt(CNT+12000000);
    printf("bas starting up\n");
    for(i = 0; i < MAX_LINES; i++) program[i] = 0;
    //srand(3141592);
    New();
    program[MAX_LINES] = "end";

#if 0
    if (argc > 1)
        OpenInputFile(argv[1]);
    else
        infile = stdin;
#endif

    SetInterpMode();

    while (1)
    {
        if (needline) GetLine();
        if (!Execute(SearchList(commands, tokens[tokenum]))) SetInterpMode();
#ifdef CSPIN_FLAG
        if (!needline) needline = CheckLine();
#else
        needline = (needline || CheckLine());
#endif
    }
}

#if 0
void *malloc(size_t size)
{
    void *ptr;
    static int heap[1000];
    static int index = 0;
    int int_size = (size + 3)/4;

    //printf("malloc %d, %d\n", size, int_size);

    if (index + int_size > 1000)
    {
        printf("malloc failed.  size = %d, index = %d\n", size, index);
        return 0;
    }
    ptr = (void *)&heap[index];
    index += int_size;
    return ptr;
}

void free(void *ptr)
{
}
#endif

/*
+-----------------------------------------------------------------------------+
|                       TERMS OF USE: MIT License                             |
+-----------------------------------------------------------------------------+
|Permission is hereby granted, free of charge, to any person obtaining a copy |
|of this software and associated documentation files (the "Software"), to deal|
|in the Software without restriction, including without limitation the rights |
|to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    |
|copies of the Software, and to permit persons to whom the Software is        |
|furnished to do so, subject to the following conditions:                     |
|                                                                             |
|The above copyright notice and this permission notice shall be included in   |
|all copies or substantial portions of the Software.                          |
|                                                                             |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   |
|IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     |
|FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  |
|AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       |
|LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,|
|OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE|
|SOFTWARE.                                                                    |
+-----------------------------------------------------------------------------+
*/
