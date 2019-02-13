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
// Symbol types
#define TYPE_OP0      0
#define TYPE_OP1D     1
#define TYPE_OP2      2
#define TYPE_OP1DOPT  3

#define TYPE_BYTE     4
#define TYPE_LONG     5
#define TYPE_ORG      6
#define TYPE_RES      7
#define TYPE_ORGF     8
#define TYPE_FILE     13
#define TYPE_ORGH     14
#define TYPE_WORD     15
#define TYPE_IF       16
#define TYPE_CON      17
#define TYPE_WX       18
#define TYPE_WLX      19
#define TYPE_HUB_ADDR 20
#define TYPE_FIT      21

#define TYPE_OP2B     23
#define TYPE_OP1B     26
#define TYPE_OP1C     27
#define TYPE_OP2XY    28
#define TYPE_OP3BX    29
#define TYPE_AKPIN    30
#define TYPE_OP3AX    31
#define TYPE_OP2PX    32
#define TYPE_OP2AX    33
#define TYPE_OP2EX    34
#define TYPE_OP2CX    35
#define TYPE_OP2DX    36
#define TYPE_OP1AX    37
#define TYPE_OPSREL9  38
#define TYPE_COG_ADDR 39
#define TYPE_OP2XX    40
#define TYPE_REPXX    41

#define TYPE_TESTB    42
#define TYPE_BITL     43
#define TYPE_POLL     44
#define TYPE_DIRL     45
#define TYPE_RCZR     46
#define TYPE_MODCZ    47
#define TYPE_TESTP    48
#define TYPE_MODC     49
#define TYPE_MODZ     50

#define TYPE_ALIGNL   52
#define TYPE_ALIGNW   53
#define TYPE_FLOAT    54
#define TYPE_GLOBAL   55

#define TYPE_SECTION  56
#define TYPE_TEXT     57
#define TYPE_DATA     58
#define TYPE_MODCZP   59
#define TYPE_UCON     60
#define TYPE_SET      61
#define TYPE_LOCAL    62
#define TYPE_COMM     63
#define TYPE_EQU      64
#define TYPE_WEAK     65
#define TYPE_UNDEF    66
#define TYPE_BALIGN   67

#ifdef __P2GCC__
#define MAX_SYMBOLS    1000
#else
#define MAX_SYMBOLS    5000
#endif
#define MAX_SYMBOL_LEN   39

#define SCOPE_NULL        0
#define SCOPE_LOCAL       1
#define SCOPE_GLOBAL      2
#define SCOPE_GLOBAL_COMM 3
#define SCOPE_UNDECLARED  4
#define SCOPE_WEAK        5

// Symbol table entry
typedef struct SymbolS {
    unsigned int value;
    unsigned int value2;
    int type;
    int objsect;
    int section;
    int scope;
    char name[MAX_SYMBOL_LEN+1];
} SymbolT;

int FindSymbol(char *symbol);
void ReadSymbolTable(void);
void PrintSymbolTable(int mode);
void AddSymbol(char *symbol, int objsect, int value, int type, int section);
void AddSymbol2(char *symbol, int objsect, int value, int value2, int type, int section);
void PurgeLocalLabels(int index);
SymbolT *GetSymbolPointer(char *str);
int EvaluateExpression(int precedence, int *pindex, char **tokens, int num, int *pval, int *is_float);
