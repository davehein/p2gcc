//******************************************************************************
// Copyright (c) 2015 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#ifdef CSPIN_FLAG
// SPIN OBJECT mem : "cmalloc"
void *malloc(int size);
void free(void *ptr);
#endif
// SPIN OBJECT sts : "cstrsubs"
#include "cstrsubs.h"
// SPIN OBJECT c   : "cliboslt"
// SPIN OBJECT
#include "ctokens.h"

#define MAX_CHARS    200
#define DOUBLE_QUOTE 0x22
#define SINGLE_QUOTE 0x27
#define TAB_CHAR     9

static int *plocalvars;
static FILE *outfile;
static int printnl=0;

static char *ops[] = {
    "<<=", ">>=", "==", "!=", "<=", ">=", ">>", "<<", "&&", "||", "++", "--",
    "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", 0};
static char *delim = ";':()[],=+-*/<>\" \t#@!&|~%{}^";

static int linenum = 0;
static FILE *infile = 0;
static char buff[MAX_CHARS];
static int eofflag = 0;
StringT *tokens = 0;

#ifdef CSPIN_FLAG
/* INLINE SPIN
PUB Initialize(infile0, outfile0, plocalvars0) | i
  infile := infile0
  outfile := outfile0
  plocalvars := plocalvars0
  mem.mallocinit(600)
  delim += @@0 - 16
  i := 0
  repeat while long[@ops][i]
    long[@ops][i] += @@0 - 16
    i++
*/
#else
void Initialize(FILE *infile0, FILE *outfile0, int *localvars0)
{
    infile = infile0;
    outfile = outfile0;
    plocalvars = localvars0;
}
#endif

// Advance the token read index and ensure there
// is at least one token in the queue
void NextToken(void)
{
    StringT *next = tokens->next;
    free(tokens);
    tokens = next;
    while (!tokens) GetLine();
}

StringT *DetachToken(void)
{
    StringT *curr = tokens;
    tokens = tokens->next;
    while (!tokens) GetLine();
    curr->next = 0;
    return curr;
}

int TokensLeft(void)
{
    int numtokens = 0;
    StringT *sptr = tokens;

    while (sptr)
    {
        numtokens++;
        sptr = sptr->next;
    }

    return numtokens;
}

// Ensure that there are at least "num" tokens in the queue
void NeedTokens(int num)
{
    while (TokensLeft() < num) GetLine();
}

// Return the value of the current token
char *TokenStr(void)
{
    return tokens->str;
}

// Return the pointer to the next token
int TokenLast(void)
{
    return (tokens->next == 0);
}

// Return the value of the "idx" token in the queue
char *TokenIdx(int idx)
{
    StringT *sptr = tokens;
    while (idx-- > 0) sptr = sptr->next;
    return sptr->str;
}

// Compare the current token to the string in "str"
int CompareToken(char *str)
{
    return (strcmp(TokenStr(), str) == 0);
}

int CompareTokenIdx(char *str, int idx)
{
    return (strcmp(TokenIdx(1), str) == 0);
}

StringT *GetTail(StringT *list)
{
    //if (!list) { printf("GetTail: NULL\n"); return list; }
    //printf("GetTail: %s", list->str);
    if (list)
    {
        while (list->next) list = list->next;
    }
    //printf(" %s\n", list->str);
    return list;
}

// Convert the string in "ptr" to a series of tokens
void Tokenize(char *ptr)
{
    int i, len;
    char *ptr1;
    StringT *sptr;
    StringT *tail = GetTail(tokens);
    while (*ptr)
    {
        ptr1 = SkipChar(ptr, ' ');
        if (!*ptr1) break;
        ptr = FindChar(delim, *ptr1);
        if (*ptr)
        {
            if (*ptr1 == DOUBLE_QUOTE)
            {
                ptr = FindChar(ptr1 + 1, DOUBLE_QUOTE);
                if (*ptr) ptr++;
            }
            else if (*ptr1 == SINGLE_QUOTE)
            {
                ptr = FindChar(ptr1 + 1, SINGLE_QUOTE);
                if (*ptr) ptr++;
            }
            else if (*ptr1 == '/' && ptr1[1] == '/')
            {
                break;
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
        sptr = (StringT *)malloc(sizeof(StringT) + len);
        if (!sptr)
        {
            printf("ERROR: Could not allocate string buffer\n");
            exit(1);
        }
        sptr->next = 0;
        memcpy(sptr->str, ptr1, len);
        sptr->str[len] = 0;
        if (tail)
        {
            tail->next = sptr;
            tail = sptr;
        }
        else
            tokens = tail = sptr;
    }
}

#if 1
void PrintList(StringT *sptr)
{
    printf("PrintList: ");
    while (sptr)
    {
        printf("%s ", sptr->str);
        sptr = sptr->next;
    }
    printf("\n");
}
#endif

#if 0
void EmitLine(void)
{
    fprintf(outfile, "\n' %s\n", buff);
}
#endif

int GetLineNumber(void)
{
    return linenum;
}

void SetPrintNL(void)
{
    printnl = 1;
}

#if 0
void DumpTokens(void)
{
    StringT *link = tokens;
    printf("%d: %s\n", linenum, buff);
    while (link)
    {
        printf("<%s>", link->str);
        link = link->next;
    }
    printf("\n");
}
#endif

// Read a line from the input file and convert it to tokens
int GetLine(void)
{
    if (!fgets(buff, MAX_CHARS, infile))
    {
        if (eofflag)
        {
	    printf("Encountered unexpected EOF\n");
	    exit(0);
        }
        else
        {
            strcpy(buff, "EOF");
            eofflag = 1;
        }
    }
    linenum++;
    RemoveCRLF(buff);
#if 0
    if (!*plocalvars)
    {
        if (printnl) fprintf(outfile, "\n");
        fprintf(outfile, "' %s\n", buff);
        printnl = 0;
    }
#else
    if (printnl) fprintf(outfile, "\n");
    fprintf(outfile, "' %s\n", buff);
    printnl = 0;
#endif
    Tokenize(buff);
    //DumpTokens();
    return 1;
}

// Return the value of eofflag
int eof(void)
{
    return eofflag;
}

void AttachTokens(StringT *sptr)
{
    StringT *tail = GetTail(sptr);
    tail->next = tokens;
    tokens = sptr;
}

void PrintLine(void)
{
    printf("%d: %s\n", linenum, buff);
}

void FreeList(StringT *list)
{
    StringT *next;

    while (list)
    {
        next = list->next;
        free(list);
        list = next;
    }
}
