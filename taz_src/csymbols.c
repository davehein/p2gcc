#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "csymbols.h"
#include "ctokens.h"
#include "gencode.h"

#ifdef CSPIN_FLAG
// SPIN OBJECT mem : "cmalloc"
void *malloc(int size);
void free(void *ptr);
// SPIN OBJECT c : "cliboslt"
// SPIN OBJECT tok : "ctokens"
int GetLineNumber(void);
// SPIN OBJECT
#endif

static SymbolT *symtable = 0;

void AddSymbol(char *name, int size, int signflag, int array, int pointer, int local, int value)
{
    SymbolT *tail;
    SymbolT *symbol = malloc(sizeof(SymbolT) + strlen(name));
    //printf("AddSymbol: %s\n", name);
    symbol->next = 0;
    symbol->size = size;
    symbol->signflag = signflag;
    symbol->array = array;
    symbol->pointer = pointer;
    symbol->local = local;
    symbol->value = value;
    strcpy(symbol->name, name);
    if (!symtable)
        symtable = symbol;
    else
    {
        tail = symtable;
        while (tail->next) tail = tail->next;
        tail->next = symbol;
    }
}

SymbolT *FindSymbol(char *name)
{
    SymbolT *found = 0;
    SymbolT *symbol = symtable;
    while (symbol)
    {
        if (!strcmp(symbol->name, name)) found = symbol;
        symbol = symbol->next;
    }
    return found;
}

SymbolT *FindSymbolNeed(char *name)
{
    SymbolT *symbol = FindSymbol(name);
    if (!symbol)
    {
        printf("%d: %s is not declared\n", GetLineNumber(), name);
    }
    return symbol;
}

void PrintSymbols(void)
{
    SymbolT *symbol = symtable;

    printf("PrintSymbols\n");
    while (symbol)
    {
        printf("%d %d %4d %d %d %d %s\n", symbol->size, symbol->signflag,
            symbol->array, symbol->pointer, symbol->local, symbol->value, symbol->name);
        symbol = symbol->next;
    }
}

void RemoveLocals(void)
{
    SymbolT *next;
    SymbolT *prev = 0;
    SymbolT *symbol = symtable;
    while (symbol)
    {
        next = symbol->next;
        if (symbol->local)
        {
            free(symbol);
            if (prev)
                prev->next = next;
            else
                symtable = next;
        }
        else
            prev = symbol;
        symbol = next;
    }
}
