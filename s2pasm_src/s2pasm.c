#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

static char buffer1[1000];
static char buffer2[1000];

static int debugflag = 0;
static int twopasses = 0;
static int globalflag = 0;
static int localmode = 0;
static int globalmode = 0;
static char globalname[100];

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

int CheckSourceDest(void)
{
    int len;
    int both = 0;
    char *cptr, *fptr, *pptr, *optr, *sptr;
    char *lptr = FindString(buffer1, "_L");
    char first[100];

    if (!*lptr) return 0;
    if (lptr == buffer1) return 0;

    fptr = SkipWhiteSpace(buffer1);
    if (!strncmp(fptr, "IF_", 3))
    {
        optr = FindWhiteSpace(fptr);
        optr = SkipWhiteSpace(optr);
    }
    else
        optr = fptr;
    if (!*optr) return 0;
    pptr = FindWhiteSpace(optr);
    if (!*pptr) return 0;

    if (!strncmp(optr, "jmp", 3)) return 0;
    if (!strncmp(optr, "djnz", 4)) return 0;
    if (!strncmp(optr, "call", 4)) return 0;
    if (!strncmp(optr, "calld", 5)) return 0;
    if (!strncmp(optr, "long", 4)) return 0;
    if (lptr[-1] == '_' ||
        (lptr[2] != 'C' && !(lptr[2] >= '0' && lptr[2] <= '9')))
    {
        printf("CheckSourceDest: False detection of _L - %s\n", buffer1);
        return 0;
    }

    *pptr++ = 0;

    len = (int)optr - (int)buffer1;
    memcpy(first, buffer1, len);
    first[len] = 0;

    cptr = FindChar(pptr, ',');
    if (*cptr)
    {
        *cptr++ = 0;
        // Check if both source and destination are "_L" labels
        sptr = FindString(cptr, "_L");
        if (*sptr && sptr != lptr)
        {
            both = 1;
            if (debugflag)
            {
                printf("Both source and destination are \"_L\" labels\n");
                pptr[-1] = ' ';
                cptr[-1] = ',';
                printf("%s\n", buffer1);
                pptr[-1] = 0;
                cptr[-1] = 0;
            }
            if (strncmp(optr, "wrlong", 6))
            {
                printf("ERROR: two _L labels, but opcode is not wrlong\n");
                exit(1);
            }
        }
    }

    if (!strcmp(optr, "mov"))
    {
        if (both)
        {
            fprintf(outfile, "%srdlong\t%s, ##%s%s", first, "temp", sptr, NEW_LINE);
            fprintf(outfile, "%swrlong\t%s, ##%s%s", first, "temp", lptr, NEW_LINE);
        }
        else if ((int)lptr >= (int)cptr)
            fprintf(outfile, "%srdlong\t%s, ##%s%s", first, pptr, lptr, NEW_LINE);
        else
            fprintf(outfile, "%swrlong\t%s, ##%s%s", first, pptr, lptr, NEW_LINE);
    }
    else
    {
        char *wptr = FindWhiteSpace(lptr);
        int val = *wptr;
        *wptr = 0;
        fprintf(outfile, "%srdlong\ttemp, ##%s%s", first, lptr, NEW_LINE);
        *wptr = val;
        if (both)
        {
            fprintf(outfile, "%srdlong\ttemp1, ##%s%s", first, sptr, NEW_LINE);
            fprintf(outfile, "%s%s\ttemp, temp1%s", first, optr, NEW_LINE);
            //fprintf(outfile, "%swrlong\ttemp, ##%s%s", first, lptr, NEW_LINE);
        }
        else if ((int)lptr >= (int)cptr)
            fprintf(outfile, "%s%s\t%s, temp%s%s", first, optr, pptr, wptr, NEW_LINE);
        else
            fprintf(outfile, "%s%s\ttemp,%s%s%s", first, optr, cptr, wptr, NEW_LINE);
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
    if (*ptr) *ptr++ = 0;
    if (localmode || !globalflag)
    {
        localmode = 0;
        fprintf(outfile, "%s%s", &buffer1[7], NEW_LINE);
    }
    else
    {
        fprintf(outfile, "%s\tglobal0%s", &buffer1[7], NEW_LINE);
    }
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

int CheckGlobal(void)
{
    if (globalmode && !strcmp(buffer1, globalname))
    {
        globalmode = 0;
        fprintf(outfile, "%s\tglobal%s", buffer1, NEW_LINE);
        return 1;
    }
    if (strncmp(buffer1, "\t.global", 8)) return 0;
    if (globalflag)
    {
        globalmode = 1;
        strcpy(globalname, &buffer1[9]);
#if 0
        fgets(buffer1, 1000, infile);
        RemoveCRLF(buffer1);
        fprintf(outfile, "%s\tglobal%s", buffer1, NEW_LINE);
#endif
    }
    return 1;
}

typedef struct SymbolS {
    struct SymbolS *next;
    char *name;
    char *value;
} SymbolT;

SymbolT *symbols = 0;

SymbolT *GetSymTail(void)
{
    SymbolT *link;
    if (!symbols) return 0;

    link = symbols;
    while (link->next)
        link = link->next;
    return link;
}

void AddSymbol(char *name, char *value)
{
    SymbolT *tail;
    SymbolT *sym = malloc(sizeof(SymbolT));
    sym->next = 0;
    sym->name = malloc(strlen(name)+1);
    sym->value = malloc(strlen(value)+1);
    strcpy(sym->name, name);
    strcpy(sym->value, value);
    if (!symbols)
        symbols = sym;
    else
    {
        tail = GetSymTail();
        tail->next = sym;
    }
}

void DumpSymbols()
{
    SymbolT *link = symbols;

    while (link)
    {
        printf("%s\t%s\n", link->name, link->value);
        link = link->next;
    }
}

SymbolT *FindSymbol(char *name)
{
    SymbolT *link = symbols;

    if (debugflag) printf("DEBUG: FindSymbol %s\n", name);
    while (link)
    {
        if (!strcmp(link->name, name)) break;
        link = link->next;
    }
    if (debugflag)
    {
        if (link)
            printf("DEBUG: Symbol found\n");
        else
            printf("DEBUG: Symbol NOT found\n");
    }
    return link;
}

void GetLCSymbols(char *fname)
{
    char name[100];
    while (fgets(buffer1, 1000, infile))
    {
        RemoveCRLF(buffer1);
        if (!strncmp(buffer1, ".LC", 3))
        {
            buffer1[0] = '_';
            strcpy(name, buffer1);
            fgets(buffer1, 1000, infile);
            RemoveCRLF(buffer1);
            ReplaceString(".L", "_L");
            CheckLocalName();
            if (!strncmp(buffer1, "\tlong\t", 6))
               AddSymbol(name, buffer1+6);
            else if(debugflag)
               printf("Don't add %s%s\n", name, buffer1);
        }
    }
    if (debugflag) DumpSymbols();
    fclose(infile);
    infile = OpenFile(fname, "r");
}

int CheckLCSymbol(void)
{
    int len;
    SymbolT *link;
    char name[100];
    char *ptr, *ptr2, *ptr3;

    ptr = FindString(buffer1, "_LC");
    if (!*ptr) return 0;
    ptr2 = FindWhiteSpace(ptr);
    ptr3 = FindChar(ptr, ',');
    if ((int)ptr3 < (int)ptr2) ptr2 = ptr3;
    len = (int)ptr2 - (int)ptr;
    memcpy(name, ptr, len);
    name[len] = 0;
    if (debugflag) printf("DEBUG: Found _LC - %s\n", name);
    link = FindSymbol(name);
    if (!link) return 0;
    // Check for second _LC reference
    if (*ptr2)
    {
        ptr3 = FindString(ptr2+1, "_LC");
        if (*ptr3)
        {
            SymbolT *link2;
            char name2[100];
            ptr2 = FindWhiteSpace(ptr3);
            len = (int)ptr2 - (int)ptr3;
            memcpy(name2, ptr3, len);
            name2[len] = 0;
            if (debugflag) printf("DEBUG: Found second _LC - %s\n", name2);
            link2 = FindSymbol(name2);
            if (!link2) return 0;
            if (debugflag) printf("CHANGING\n");
            if (debugflag) printf("%s\n", buffer1);
            *ptr = 0;
            if (debugflag) printf("TO\n");
            if (debugflag) printf("\tmov\ttemp, ##%s\n", link->value);
            if (debugflag) printf("%stemp, ##%s\n", buffer1, link2->value);
            fprintf(outfile, "\tmov\ttemp, ##%s%s", link->value, NEW_LINE);
            fprintf(outfile, "%stemp, ##%s%s", buffer1, link2->value, NEW_LINE);
            return 1;
        }
    }
    
    if (ptr == buffer1)
    {
        if (debugflag) printf("Skipping %s\n", buffer1);
        fgets(buffer1, 1000, infile);
        RemoveCRLF(buffer1);
        if (debugflag) printf("Skipping %s\n", buffer1);
    }
    else
    {
        char *ptr4 = FindChar(buffer1, ',');
        int dflag = (int)ptr4 > (int)ptr;
        if (debugflag) printf("CHANGING\n");
        if (debugflag) printf("%s\n", buffer1);
        if (debugflag) printf("TO\n");
        *ptr = 0;
        if (dflag && strcmp(ptr-7, "wrlong\t"))
        {
            if (debugflag) printf("\tmov\ttemp, ##%s\n", link->value);
            if (debugflag) printf("%stemp%s\n", buffer1, ptr2);
            fprintf(outfile, "\tmov\ttemp, ##%s%s", link->value, NEW_LINE);
            fprintf(outfile, "%stemp%s%s", buffer1, ptr2, NEW_LINE);
        }
        else
        {
            if (debugflag) printf("%s##%s%s\n", buffer1, link->value, ptr2);
            fprintf(outfile, "%s##%s%s%s", buffer1, link->value, ptr2, NEW_LINE);
        }
    }
    return 1;
}

void usage(void)
{
    printf("usage: s2pasm [options] filename\n");
    printf("  options are\n");
    printf("  -g      - Generate global directive\n");
    printf("  -t      - Run two passes\n");
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
            if (!strcmp(argv[argi], "-g"))
                globalflag = 1;
            else if (!strcmp(argv[argi], "-t"))
                twopasses = 1;
            else if (!strcmp(argv[argi], "-d"))
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
    if (twopasses) GetLCSymbols(fname);
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
        if (!strncmp(buffer1, "\t.data", 6))
        {
            if (globalflag) fprintf(outfile, "\tdata%s", NEW_LINE);
            continue;
        }
        if (!strncmp(buffer1, "\t.local", 7))
        {
            localmode = 1;
            continue;
        }
        if (!strncmp(buffer1, "\t.text", 6))
        {
            if (globalflag) fprintf(outfile, "\ttext%s", NEW_LINE);
            continue;
        }
        if (CheckGlobal()) continue;
        //if (!strncmp(buffer1, "\t.global", 8)) continue;
        if (!strcmp(buffer1, "\t.section\t.bss"))
        {
            if (globalflag) fprintf(outfile, "\tdata%s", NEW_LINE);
            continue;
        }
        if (!strncmp(buffer1, "\t.section", 9)) continue;
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
        ReplaceString(".L", "_L");
        ReplaceString(".balign\t4", "alignl");
        ReplaceString(".balign\t2", "alignw");
        ReplaceString("0x", "$");
        ReplaceString("jmpret", "calld");
        ReplaceString("__MASK_", "##$");
#if 0
        ReplaceString("IF_NE", "if_ne");
        ReplaceString("IF_E", "if_e");
        ReplaceString("IF_AE", "if_ae");
        ReplaceString("IF_A", "if_a");
        ReplaceString("IF_BE", "if_be");
        ReplaceString("IF_B", "if_b");
#endif
        if (CheckMova()) continue;
        if (CheckWaitcnt()) continue;
        if (CheckCoginit()) continue;
        if (!strncmp(buffer1, "\tlong\t_L", 8))
        {
            fprintf(outfile, "\tlong\t%s%s", &buffer1[6], NEW_LINE);
            continue;
        }
        if (!strcmp(buffer1, "\tlong\t__clkfreq"))
        {
            fprintf(outfile, "\tlong\t%s%s", &buffer1[6], NEW_LINE);
            continue;
        }
        if (twopasses)
        {
            if (CheckLCSymbol()) continue;
        }
        else
        {
	    if (CheckSourceDest()) continue;
        }
        if (CheckNR()) continue;
	if (CheckCNTSource()) continue;
	if (CheckCNTDest()) continue;
        fprintf(outfile, "%s%s", buffer1, NEW_LINE);
    }
    fclose(infile);
    fclose(outfile);
    return 0;
}
