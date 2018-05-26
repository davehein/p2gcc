#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include "strsubs.h"
#include "symsubs.h"
#include "p2asmsym.h"

extern int hubmode;
extern int hub_addr;
extern int cog_addr;
extern int numsym;
extern int case_sensative;
extern FILE *lstfile;
static int numsym1 = 0;

extern SymbolT SymbolTable[MAX_SYMBOLS];

void PrintError(char *str, void *parm1, void *parm2);
int StrToDec1(char *str, int *is_float);
int CheckExpected(char *str, int i, char **tokens, int num);
int CheckForEOL(int i, int num);

void ReadSymbolTable(void)
{
    int i;
    SymbolT *s;

    s = &SymbolTable[0];
    s->name[0] = 0;
    s->value = 0;
    s->type = TYPE_CON;
    numsym = 1;
    s = &SymbolTable[1];

    for (i = 0; p2asmsym[i]; i++)
    {
        sscanf(p2asmsym[i], "%x %d %s", &s->value, &s->type, s->name);
	s = &SymbolTable[++numsym];
    }
    numsym1 = numsym;
}

int FindSymbol(char *symbol)
{
    int i;

    if (*symbol == '$')
    {
	if (symbol[1] == 0)
        {
            if (hubmode)
	        SymbolTable[0].value = hub_addr;
            else
                SymbolTable[0].value = cog_addr >> 2;
        }
	else
	    SymbolTable[0].value = StrToHex(symbol+1);
        SymbolTable[0].type = TYPE_CON;
	return 0;
    }
    else if (*symbol == '%')
    {
        if (symbol[1] == '%')
	    SymbolTable[0].value = StrToQuad(symbol+2);
        else
	    SymbolTable[0].value = StrToBin(symbol+1);
        SymbolTable[0].type = TYPE_CON;
	return 0;
    }
    else if (*symbol == '"')
    {
	SymbolTable[0].value = symbol[1];
        SymbolTable[0].type = TYPE_CON;
	return 0;
    }
    else if ((*symbol == '-' && symbol[1] != '-') || (*symbol >= '0' && *symbol <= '9'))
    {
        int is_float;
        SymbolTable[0].value = StrToDec1(symbol, &is_float);
        SymbolTable[0].type = (is_float ? TYPE_FLOAT : TYPE_CON);
	return 0;
    }

    // Do case insensative search for PASM symbols
    for (i = 0; i < numsym1; i++)
    {
        if (StrCompNoCase(symbol, SymbolTable[i].name)) return i;
    }

    // Search remaining program symbols based on case_insensative flag
    if (case_sensative)
    {
        for (; i < numsym; i++)
        {
            if (!strcmp(symbol, SymbolTable[i].name)) return i;
        }
    }
    else
    {
        for (; i < numsym; i++)
        {
            if (StrCompNoCase(symbol, SymbolTable[i].name)) return i;
        }
    }

    return -1;
}

void PrintSymbolTable(int mode)
{
    int i;
    SymbolT *s;

    for (i = 0; i < numsym; i++)
    {
        s = &SymbolTable[i];
        if (mode || s->type == 20 || s->type == 39)
	    printf("%d: %s %d %8.8x %8.8x\n", i, s->name, s->type, s->value, s->value2);
    }
}

void AddSymbol(char *symbol, int value, int type)
{
    if (numsym >= MAX_SYMBOLS)
    {
	printf("Symbol table is full\n");
	exit(1);
    }
    if (strlen(symbol) > MAX_SYMBOL_LEN)
    {
        fprintf(lstfile, "Truncating %s to %d characters\n", symbol, MAX_SYMBOL_LEN);
        symbol[MAX_SYMBOL_LEN] = 0;
    }
    strcpy(SymbolTable[numsym].name, symbol);
    SymbolTable[numsym].value = value;
    SymbolTable[numsym].value2 = 0;
    SymbolTable[numsym].type = type;
    numsym++;
}

void AddSymbol2(char *symbol, int value, int value2, int type)
{
    if (numsym >= MAX_SYMBOLS)
    {
	printf("Symbol table is full\n");
	exit(1);
    }
    if (strlen(symbol) > MAX_SYMBOL_LEN)
    {
        fprintf(lstfile, "Truncating %s to %d characters\n", symbol, MAX_SYMBOL_LEN);
        symbol[MAX_SYMBOL_LEN] = 0;
    }
    strcpy(SymbolTable[numsym].name, symbol);
    SymbolTable[numsym].value = value;
    SymbolTable[numsym].value2 = value2;
    SymbolTable[numsym].type = type;
    numsym++;
}

void PurgeLocalLabels(int index)
{
    int i;

    for (i = 0; i < index; i++)
    {
	if (SymbolTable[i].name[0] == '.') SymbolTable[i].name[0] = ';';
    }
}

#if 0
int FindNeededSymbol(char *str)
{
    int index = FindSymbol(str);
    if (index < 0)
    {
	fprintf(lstfile, "ERROR: %s is undefined\n", str);
	return 0;
    }
    return index;
}
#endif

SymbolT *GetSymbolPointer(char *str)
{
    int index = FindSymbol(str);
    if (index < 0)
    {
	fprintf(lstfile, "ERROR: %s is undefined\n", str);
	return 0;
    }
    return &SymbolTable[index];
}

int CheckFloat(int *is_float, int is_float1)
{
    if (*is_float == -1)
    {
        *is_float = is_float1;
        return 0;
    }
    if (*is_float != is_float1)
    {
        PrintError("ERROR: Cannot mix float and fix\n", 0, 0);
        return 1;
    }
    return 0;
}

int EvaluateParenExpression(int *pindex, char **tokens, int num, int *pval, int *is_float)
{
    int errnum;
    int i = *pindex;

    if (CheckExpected("(", ++i, tokens, num)) { *pindex = i; return 1; }
    i++;
    if ((errnum = EvaluateExpression(12, &i, tokens, num, pval, is_float))) { *pindex = i; return errnum; }
    if (CheckExpected(")", ++i, tokens, num)) { *pindex = i; return 1; }

    *pindex = i;
    return 0;
}

static int bitrev(unsigned int val, int num)
{
    int i;
    int retval = 0;

    for (i = 0; i < num; i++)
    {
        retval = (retval << 1) | (val & 1);
        val >>= 1;
    }

    return retval;
}

int EvaluateExpression(int prevprec, int *pindex, char **tokens, int num, int *pval, int *is_float)
{
    int index;
    SymbolT *s;
    int i = *pindex;
    static char *oplist[] = {"+", "-", "*", "/", "&", "|", "<<", ">>", "^", "><", 0};
    static int precedence[] = {6, 6, 5, 5, 3, 4, 2, 2, 4, 2};
    int value = 0;
    int currprec;
    int value2;
    int errnum;
    int is_float1;

    if (CheckForEOL(i, num)) return 1;

    if (!strcmp(tokens[i], "("))
    {
        i--;
        if ((errnum = EvaluateParenExpression(&i, tokens, num, &value, is_float))) return errnum;
    }
    else
    {
        int negate = 0;
        int getvalue = 1;
        int hub_addr_flag = 0;
        if (!strcmp(tokens[i], "@@@") || !strcmp(tokens[i], "@"))
        {
            if (CheckForEOL(++i, num))
            {
                *pindex = i;
                return 1;
            }
            hub_addr_flag = 1;
        }
        else if (!strcmp(tokens[i], "-"))
        {
            negate = 1;
            if (CheckForEOL(++i, num))
            {
                *pindex = i;
                return 1;
            }
        }
        else if (!strcmp(tokens[i], "+"))
        {
            if (++i >= num)
            {
                printf("Encountered EOL\n");
                *pindex = i;
                return 1;
            }
        }
        else if (!strcmp(tokens[i], "float"))
        {
            float fvalue;
            int is_float1 = 0;

            if (CheckFloat(is_float, 1)) { *pindex = i; return 1; }
            if ((errnum = EvaluateParenExpression(&i, tokens, num, &value, &is_float1))) return errnum;
            fvalue = (float)value;
            memcpy(&value, &fvalue, 4);
            getvalue = 0;
        }
        else if (!strcmp(tokens[i], "trunc") || !strcmp(tokens[i], "round"))
        {
            float fvalue, fvalue1 = 0.0;
            int is_float1 = 1;

            if (tokens[i][0] == 'r') fvalue1 = 0.5;
            if (CheckFloat(is_float, 0)) { *pindex = i; return 1; }
            if ((errnum = EvaluateParenExpression(&i, tokens, num, &value, &is_float1))) return errnum;
            memcpy(&fvalue, &value, 4);
            value = (int)floor((double)(fvalue + fvalue1));
            getvalue = 0;
        }
        else if (!strcmp(tokens[i], "|<"))
        {
            int is_float1 = 0;
            i++;
            if ((errnum = EvaluateExpression(12, &i, tokens, num, &value, &is_float1))) return errnum;
            value = 1 << value;
            getvalue = 0;
        }
        if (getvalue)
        {
            index = FindSymbol(tokens[i]);
            if (index < 0)
            {
                printf("EvaluateExpression: Symbol %s is undefined\n", tokens[i]);
                return 3;
            }
            s = &SymbolTable[index];
            is_float1 = (s->type == TYPE_FLOAT);
            if (CheckFloat(is_float, is_float1)) { *pindex = i; return 1; }
            if (hub_addr_flag || s->type == TYPE_HUB_ADDR)
                value = s->value2;
            else if (negate)
            {
                if (is_float1)
                    value ^= 0x80000000;
                else
                    value = -s->value;
            }
            else
                value = s->value;
        }
    }

    while (i < num - 2)
    {
        index = SearchList(oplist, tokens[i+1]);
        if (index < 0) break;
        currprec = precedence[index];
        if (currprec >= prevprec) break;
        i += 2;
        if ((errnum = EvaluateExpression(currprec, &i, tokens, num, &value2, is_float)))
            return errnum;
        if (*is_float)
        {
            float fvalue, fvalue2;
            memcpy(&fvalue, &value, 4);
            memcpy(&fvalue2, &value2, 4);
	    if (index == 0)      fvalue += fvalue2;
	    else if (index == 1) fvalue -= fvalue2;
	    else if (index == 2) fvalue *= fvalue2;
	    else if (index == 3) fvalue /= fvalue2;
	    else break;
            memcpy(&value, &fvalue, 4);
        }
        else
        {
	    if (index == 0)      value += value2;
	    else if (index == 1) value -= value2;
	    else if (index == 2) value *= value2;
	    else if (index == 3) value /= value2;
	    else if (index == 4) value &= value2;
	    else if (index == 5) value |= value2;
	    else if (index == 6) value <<= value2;
	    else if (index == 7) value >>= value2;
	    else if (index == 8) value ^= value2;
	    else if (index == 9) value = bitrev(value, value2);
	    else break;
        }
    }

    *pval = value;
    *pindex = i;
    return 0;
}
