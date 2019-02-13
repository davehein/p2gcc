//******************************************************************************
// Copyright (c) 2015 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "cstrsubs.h"
#include "ctokens.h"
#include "csymbols.h"
#include "taz.h"
#include "gencode.h"

// List of C types
static char *types[] = {"void", "char", "short", "int", "signed", "unsigned",
    0};
static char *typename[] = {"void", "byte", "word", "xxxx", "long"};
static char typesize[] = {1, 1, 2, 4, 4, 4, 0, 0};
static char typesign[] = {0, 0, 1, 1, 1, 0, 0, 0};
//static char size2char[] = {'v', 'b', 'w', 'x', 'l'};

// List of C assignment operators
static char *assign[] = {"=", "+=", "-=", "*=", "/=", "%=", "<<=", ">>=", "&=",
    "|=", "^=", 0};
static char *aopcode[] = {"null", "add", "sub", "mul", "div", "mod", "shl", "shr",
    "and", "or", "xor"};

// List of C operators along with their precedence and opcodes
static char *oplist[] = {"*", "/", "%", "+", "-", "<<", ">>", "<", "<=", ">",
    ">=", "==", "!=", "&", "^", "|", "&&", "||", 0};
static char  opprec[] = {13, 13, 13, 12, 12, 11, 11, 10, 10, 10, 10, 9, 9, 8,
    7, 6, 5, 4, 0, 0};

// C keywords
static char *keywords[] = {"return", "if", "while", "do", "for", "break",
    "continue", "inline", 0};

// Intrinsic functions
static char *intrinsics[] = {"abs", "waitcnt", "waitx", "va_start", "va_arg", "va_end", 0};

// Registers
static char *reglist[] = {"cnt", "ina", "outa", "dira", "inb", "outb", "dirb", 0};

static int labelnum = 1;
int localvars = 0;
int localvaraddr = 0;
int globalvaraddr = 0;
static FILE *infile;
FILE *outfile;
static char _parmstr[4];
static int debugflag = 0;
int reg_indx = 0;
int nopflag = 0;
int mainflag = 0;
int globalflag = 0;
int lastsize = 4;

void CheckMallocSpace(void);

int main(int argc, char **argv)
{
    int i;
    char *fname = 0;

#if __P2GCC__
    sd_mount(58, 61, 59, 60);
    chdir(argv[argc]);
#endif

    for (i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (!strcmp(argv[i], "-d"))
                debugflag = 1;
            else if (!strcmp(argv[i], "-g"))
                globalflag = 1;
            else if (argv[i][1] == 'n')
                nopflag = atoi(&argv[i][2]);
            else
                usage();
        }
        else if (!fname)
            fname = argv[i];
        else
            usage();
    }

    if (!fname) usage();

    OpenFiles(fname);

    // Initialize
    Initialize(infile, outfile, &localvars);
    EmitHeader();
    NeedTokens(1);

    // Process statements until we reach the end of the file
    while (!eof())
        ProcessStatement(0, 0);

    if (!mainflag)
    {
        Emit("\nCON\n");
        Emit("  main = 0\n");
    }

    // Close the input and output files
    fclose(infile);
    fclose(outfile);

    if (debugflag) PrintSymbols();

    exit(0);
}

void usage(void)
{
    printf("usage: taz [-d -g] infile\n");
    exit(0);
}

// Open the input file with a .c extension and the output file with .s
void OpenFiles(char *fname)
{
    char *ptr;
    char fname1[200];
    //printf("OpenFiles: %s\n", fname);
    strcpy(fname1, fname);
    ptr = FindChar(fname1, '.');
    if (!*ptr)
        strcat(fname1, ".c");
    infile = fopen(fname1, "r");
    if (!infile)
    {
        printf("Could not open %s\n", fname1);
        exit(1);
    }
    ptr = FindChar(fname1, '.');
    strcpy(ptr, ".s");
    outfile = fopen(fname1, "w");
}

// Check for a keyword, and if not found assume either a function call or variable assignment
void ProcessStatement(int breaknum, int continuenum)
{
    SymbolT type;
    int keyword = SearchList(keywords, TokenStr());
    int typeidx = SearchList(types, TokenStr());

    CheckEndOfLocalVars(typeidx);

    //printf("ProcessStatement: %d, %d\n", breaknum, continuenum);

    switch (keyword)
    {
        case KEYWORD_RETURN:
            ProcessReturnStatement();
            break;
        case KEYWORD_WHILE:
            ProcessWhileStatement();
            break;
        case KEYWORD_IF:
            ProcessIfStatement(breaknum, continuenum);
            break;
	case KEYWORD_DO:
            ProcessDoStatement();
	    break;
	case KEYWORD_FOR:
            ProcessForStatement();
	    break;
	case KEYWORD_BREAK:
            EmitJump(breaknum);
            NextToken();
            NextToken();
	    break;
	case KEYWORD_CONTINUE:
            EmitJump(continuenum);
            NextToken();
            NextToken();
	    break;
        case KEYWORD_INLINE:
            ProcessInline();
            break;
        default:
            if (typeidx >= 0)
                ProcessDeclaration(typeidx);
            else
            {
                ProcessValue(0, &type);
                NextToken();
            }
    }
}

void SkipParens(StringT *tail)
{
    int count = 0;
    while (1)
    {
        tail->next = DetachToken();
        tail = tail->next;
        if (!strcmp(tail->str, "("))
            count++;
        else if (!strcmp(tail->str, ")"))
            count--;
        if (!count) break;
    }
}

void SkipBrackets(StringT *tail)
{
    int count = 0;
    while (1)
    {
        tail->next = DetachToken();
        tail = tail->next;
        if (!strcmp(tail->str, "["))
            count++;
        else if (!strcmp(tail->str, "]"))
            count--;
        if (!count) break;
    }
}

int DetachValue(StringT *sptr)
{
    int index = -1;
    StringT *tail = sptr;

    while (1)
    {
        if (CompareToken(";") || CompareToken(",") ||
            CompareToken(")") || CompareToken("]"))
            return -1;
        if ((index = SearchList(assign, TokenStr())) >= 0)
        {
            NextToken();
            return index;
        }
        if (SearchList(oplist, TokenStr()) >= 0)
            return -1;
        if (CompareToken("("))
            SkipParens(sptr);
        else if (CompareToken("["))
            SkipBrackets(sptr);
        else
        {
            tail->next = DetachToken();
            tail = tail->next;
            tail->next = 0;
        }
    }
}

char *ParmStr(char *varname, int absolute, int indexed, SymbolT *type)
{
    int i = 0;
    int regindex = SearchList(reglist, varname);
    if (regindex >= 0) return "reg";
    strcpy(_parmstr, "   ");
    _parmstr[i++] = GetParmChar(type);
    if (absolute) _parmstr[i++] = 'a';
    if (indexed) _parmstr[i] = 'x';
    return _parmstr;
}

void GetType(char *varname, SymbolT *type)
{
    SymbolT *symbol = 0;
    int regindex = SearchList(reglist, varname);
    if (regindex < 0) symbol = FindSymbolNeed(varname);
    if (symbol)
        InitType(type, symbol->size, symbol->signflag, symbol->array, symbol->pointer, symbol->local, symbol->value);
    else
        InitType(type, 4, 1, 0, 0, 0, 0);
}

void ProcessVariableLoad(char *varname, SymbolT *type)
{
    int size = 4;
    int array = 0;
    int pointer = 0;
    int signflag = 1;
    int local = 0;
    int value = 0;
    SymbolT *symbol;
    int regindex = SearchList(reglist, varname);

//Emit1a("ProcessVariableLoad: %s\n", varname);

    if (regindex >= 0)
    {
        EmitLoadReg(varname);
        InitType(type, 4, 1, 0, 0, 0, 0);
        return;
    }
    if ((symbol = FindSymbolNeed(varname)))
    {
        size = symbol->size;
        array = symbol->array;
        pointer = symbol->pointer;
        signflag = symbol->signflag;
        local = symbol->local;
        value = symbol->value;
        InitType(type, size, signflag, array, pointer, local, value);
    }
    else
        InitType(type, 4, 1, 0, 0, 0, 0);

    EmitLoadVariable(varname, signflag, size, pointer, array, local, value);
}

void InitType(SymbolT *type, int size, int signflag, int array, int pointer, int local, int value)
{
    type->size = size;
    type->signflag = signflag;
    type->array = array;
    type->pointer = pointer;
    type->local = local;
    type->value = value;
    type->name[0] = 0;
}

int IncrementSize(char *varname, SymbolT *type)
{
    int incrsize = 1;
    SymbolT *symbol = FindSymbolNeed(varname);
    if (symbol)
    {
        InitType(type, symbol->size, symbol->signflag, symbol->array, symbol->pointer, symbol->local, symbol->value);
        if (symbol->pointer > 1)
            incrsize = 4;
        else if (symbol->pointer == 1 && symbol->size > 1)
            incrsize = symbol->size;
    }
    else
        InitType(type, 4, 1, 0, 0, 0, 0);
    return incrsize;
}

int GetParmChar(SymbolT *type)
{
    if (type->array || type->pointer || type->size == 4)
        return 'l';
    if (type->size == 1)
        return 'b';
    if (type->size == 2)
        return 'w';
    return 'x';
}

int Dereference(SymbolT *type)
{
    if (type->pointer)
        type->pointer--;
    else if (type->array)
        type->array = 0;
    else
    {
        printf("%d: ERROR: Can't dereference\n", GetLineNumber());
        PrintLine();
        Emit("ERROR: Can't dereference\n");
    }
    return GetParmChar(type);
}

void MergeTypes(SymbolT *type1, SymbolT *type2)
{
    int pointer1 = type1->pointer;
    int pointer2 = type2->pointer;
    if (type1->array) pointer1++;
    if (type2->array) pointer2++;
    if (pointer2 > pointer1) pointer1 = pointer2;
    type1->pointer = pointer1;
    type1->array = 0;
    if (!pointer1)
    {
       if ((!type1->signflag && type1->size == 4) || (!type2->signflag && type2->size == 4))
           type1->signflag = 0;
       else
           type1->signflag = 1;
    }
}

void PostIncrement(StringT *sptr, SymbolT *type, int plus, int retflag)
{
    char *varname = sptr->str;
    int incrsize = IncrementSize(varname, type);
    EmitIncrement(varname, 1, incrsize, plus, retflag, type->size, type->pointer, type->signflag, 0, 0, GetParmChar(type), type->local, type->value);
}

void PreIncrement(char *varname, SymbolT *type, int plus, int retflag)
{
    int incrsize = IncrementSize(varname, type);
    EmitIncrement(varname, 0, incrsize, plus, retflag, type->size, type->pointer, type->signflag, 0, 0, GetParmChar(type), type->local, type->value);
}

void ProcessValue(int retflag, SymbolT *type)
{
    int index;
    //int incrsize;
    StringT *tail;
    StringT *sptr = DetachToken();
    char *str = sptr->str;
    //char *loadstr = retflag ? " load" : nullstr;
    SymbolT type1;
    int parmchar;

//Emit1a("ProcessValue: %s\n", str);

    if (!strcmp(str, "-"))
    {
        ProcessExpression(MAX_PREC, type);
        EmitNegate();
    }
    else if (!strcmp(str, "!"))
    {
        ProcessExpression(MAX_PREC, type);
        EmitLogicalNot();
    }
    else if (!strcmp(str, "~"))
    {
        ProcessExpression(MAX_PREC, type);
        EmitComplement();
    }
    else if (str[0] == DOUBLE_QUOTE)
    {
        InitType(type, 1, 0, 0, 1, 0, 0);
        ProcessString(str);
    }
    else if (isdigit((int)str[0]))
    {
        InitType(type, 4, 1, 0, 0, 0, 0);
        EmitLoadNumberStr(str);
    }
    else if (*str == SINGLE_QUOTE)
    {
        char tempstr[10];
        InitType(type, 4, 1, 0, 0, 0, 0);
        sprintf(tempstr, "%d", str[1]);
        EmitLoadNumberStr(tempstr);
    }
    else if (!strcmp(str, "("))
    {
        ProcessExpression(0, type);
	NextToken();
    }
    else if (!strcmp(str, "["))
    {
        ProcessExpression(0, type);
	NextToken();
    }
    else if (CompareToken("++"))
    {
        PostIncrement(sptr, type, 1, retflag);
        NextToken();
    }
    else if (CompareToken("--"))
    {
        PostIncrement(sptr, type, 0, retflag);
        NextToken();
    }
    else if (!strcmp(str, "++"))
    {
        PreIncrement(TokenStr(), type, 1, retflag);
        NextToken();
    }
    else if (!strcmp(str, "--"))
    {
        PreIncrement(TokenStr(), type, 0, retflag);
        NextToken();
    }
    else if (!strcmp(str, "&"))
    {
        char varname[80];
        strcpy(varname, TokenStr());
        //str = TokenStr();
        NextToken();
        if (CompareToken("["))
        {
	    NextToken();
            ProcessVariableLoad(varname, type);
            ProcessExpression(0, &type1);
            //EmitAddAbsoluteIndexed(GetParmChar(type));
            EmitAddAbsoluteIndexed(Dereference(type));
	    NextToken();
        }
        else
        {
            GetType(varname, type);
            EmitLoadVarAddress(varname, type->value, type->local);
        }
        type->pointer++;
    }
    else if (CompareToken("(") && strcmp(str, "*"))
    {
        InitType(type, 4, 1, 0, 0, 0, 0);
        ProcessFunctionCall(str, retflag);
    }
    else
    {
        index = DetachValue(sptr);
        tail = GetTail(sptr);
        if (index < 0)
        {
            if (!sptr->next)
            {
                ProcessVariableLoad(str, type);
            }
            else if (!strcmp(str, "*"))
            {
                str = sptr->next->str;
                if (!strcmp(str, "("))
                {
                    AttachTokens(sptr->next);
                    sptr->next = 0;
                    ProcessExpression(0, type);
                    EmitLoadAbsolute(Dereference(type));
                }
                else
                {
                    if (!strcmp(tail->str, "++"))
                        PostIncrement(sptr->next, type, 1, 1);
                    else if (!strcmp(tail->str, "--"))
                        PostIncrement(sptr->next, type, 0, 1);
                    else
                        ProcessVariableLoad(str, type);
                    Dereference(type);
                    EmitLoadAbsolute(GetParmChar(type));
                }
            }
            else if (!strcmp(sptr->next->str, "["))
            {
                AttachTokens(sptr->next);
                sptr->next = 0;
                ProcessVariableLoad(str, type);
                ProcessValue(1, &type1);
                Dereference(type);
                parmchar = GetParmChar(type);
                EmitLoadAbsoluteIndexed(parmchar);
                if (parmchar != 'l' && type->signflag)
                    EmitSignExtend(parmchar, reg_indx-1);
            }
            else
            {
                printf("%d: ERROR 1\n", GetLineNumber());
                PrintLine();
                Emit("ERROR 1\n");
                Emit2aa("  ld%s %s\n", ParmStr(str, 0, 0, type), str);
            }
        }
        else if (strcmp(str, "*"))
        {
            if (sptr->next && !strcmp(sptr->next->str, "["))
            {
                ProcessExpression(0, &type1);
                ProcessVariableLoad(str, type);
                AttachTokens(sptr->next);
                sptr->next = 0;
                ProcessValue(1, &type1);
                Dereference(type);
                ProcessVariableAssignment(str, index, retflag, 1, 1, type);
            }
            else
            {
                ProcessExpression(0, &type1);
                GetType(str, type);
                ProcessVariableAssignment(str, index, retflag, 0, 0, type);
            }
        }
        else
        {
            ProcessExpression(0, &type1);
            if (!strcmp(sptr->next->str, "("))
            {
                AttachTokens(sptr->next);
                sptr->next = 0;
                ProcessExpression(0, type);
                ProcessAbsoluteAssignment(Dereference(type), index, retflag, type);
            }
            else
            {
                str = sptr->next->str;
                if (!strcmp(tail->str, "++"))
                    PostIncrement(sptr->next, type, 1, 1);
                else if (!strcmp(tail->str, "--"))
                    PostIncrement(sptr->next, type, 0, 1);
                else
                    ProcessVariableLoad(str, type);
                Dereference(type);
                ProcessVariableAssignment(str, index, retflag, 1, 0, type);
            }
        }
    }
    FreeList(sptr);
}

void ProcessStatementOrBraces(int breaknum, int continuenum)
{
    if (CompareToken("{"))
        ProcessBraces(breaknum, continuenum);
    else
        ProcessStatement(breaknum, continuenum);
}

// Recursively evaluate an expression of the form "value operator expression"
void ProcessExpression(int prec, SymbolT *type)
{
    int merge_types = 1;
    int i, this_prec;
    SymbolT type1;

    ProcessValue(1, type);

    while (1)
    {
        if ((i = SearchList(oplist, TokenStr())) < 0) break;
        this_prec = opprec[i];
        if (this_prec <= 0 || this_prec < prec) break;
	NextToken();
        ProcessExpression(this_prec + 1, &type1);
        if (i == OP_PLUS || i == OP_MINUS)
        {
            if ((type->pointer || type->array) &&
                !type1.pointer && !type1.array)
            {
                if (type->size > 1)
                {
                    if (type->size == 2)
                        EmitLoadNumberStr("1");
                    else
                        EmitLoadNumberStr("2");
                    EmitOpcode(OP_SHIFTL, 0);
                }
                merge_types = 0;
            }
            else if (i == OP_MINUS &&
                (type->pointer || type->array) &&
                (type1.pointer || type1.array))
            {
                merge_types = 0;
                type->array = 0;
                type->pointer = 0;
                type->size = 4;
                type->signflag = 1;
            }
        }
        else if (i == OP_SHIFTR)
        {
            merge_types = 0;
        }
        else if (i == OP_SHIFTL)
        {
            merge_types = 0;
        }
        if (merge_types) MergeTypes(type, &type1);
        EmitOpcode(i, type->signflag);
    }
}

// Process either a simple return or a return with a value
void ProcessReturnStatement(void)
{
    SymbolT type;
    NextToken();
    if (CompareToken(";"))
        EmitReturn(localvaraddr*4);
    else
    {
        ProcessExpression(0, &type);
        EmitReturnValue(localvaraddr*4);
    }
    NextToken();
}

// Process a statment of the form "while ( expression ) statement"
void ProcessWhileStatement(void)
{
    SymbolT type;
    int labelnum1 = labelnum++;
    int labelnum2 = labelnum++;
    EmitLabel(labelnum1);
    NextToken();
    if (CheckExpect("(")) NextToken();
    ProcessExpression(0, &type);
    if (CheckExpect(")")) NextToken();
    EmitJumpOnZero(labelnum2);
    ProcessStatementOrBraces(labelnum2, labelnum1);
    EmitJump(labelnum1);
    EmitLabel(labelnum2);
}

void ProcessInline(void)
{
    NextToken();
    if (CheckExpect("(")) NextToken();
    EmitQuotedString(TokenStr());
    NextToken();
    if (CheckExpect(")")) NextToken();
    if (CheckExpect(";")) NextToken();
}

// Process a statment of the form "do statement while ( expression )"
void ProcessDoStatement(void)
{
    SymbolT type;
    int labelnum1 = labelnum++;
    int labelnum2 = labelnum++;
    int labelnum3 = labelnum++;
    NextToken();
    EmitLabel(labelnum1);
    ProcessStatementOrBraces(labelnum2, labelnum3);
    EmitLabel(labelnum3);
    if (CheckExpect("while")) NextToken();
    if (CheckExpect("(")) NextToken();
    ProcessExpression(0, &type);
    if (CheckExpect(")")) NextToken();
    EmitJumpOnNonZero(labelnum1);
    EmitLabel(labelnum2);
}

// Process a statment of the form "for ( expression; expression; expression ) statement"
void ProcessForStatement(void)
{
    SymbolT type;
    int labelnum1 = labelnum++;
    int labelnum2 = labelnum++;
    int labelnum3 = labelnum++;
    int labelnum4 = labelnum++;
    NextToken();
    if (CheckExpect("(")) NextToken();
    ProcessStatement(0, 0);
    EmitLabel(labelnum1);
    ProcessExpression(0, &type);
    if (CheckExpect(";")) NextToken();
    EmitJumpOnNonZero(labelnum3);
    EmitJump(labelnum4);
    EmitLabel(labelnum2);
    ProcessStatement(0, 0);
    EmitJump(labelnum1);
    EmitLabel(labelnum3);
    ProcessStatementOrBraces(labelnum4, labelnum2);
    EmitJump(labelnum2);
    EmitLabel(labelnum4);
}

// Process a statment of the form "if ( expression ) statement [else statement]"
void ProcessIfStatement(int breaknum, int continuenum)
{
    SymbolT type;
    int labelnum1 = labelnum++;
    int labelnum2;
    //printf("ProcessIfStatement: %d\n", breaknum);
    NextToken();
    if (CheckExpect("(")) NextToken();
    ProcessExpression(0, &type);
    if (CheckExpect(")")) NextToken();
    EmitJumpOnZero(labelnum1);
    ProcessStatementOrBraces(breaknum, continuenum);
    if (CompareToken("else"))
    {
        labelnum2 = labelnum++;
        NextToken();
        EmitJump(labelnum2);
        EmitLabel(labelnum1);
        ProcessStatementOrBraces(breaknum, continuenum);
        EmitLabel(labelnum2);
    }
    else
        EmitLabel(labelnum1);
}

void CheckAlignment(int newsize)
{
    if (newsize > lastsize)
        EmitAlignment(newsize);
    lastsize = newsize;
}

// Generate a PUB statment, and then process all of the
// statements between the following braces.
void ProcessFunctionDeclaration(SymbolT *type)
{
    int typeidx;
    int numparms = 0;
    localvars = 1;
    localvaraddr = 0;
    if (debugflag) printf("Function %s\n", TokenStr());
    CheckAlignment(4);
    EmitFunctionStart(TokenStr());
    if (!strcmp(TokenStr(), "main")) mainflag = 1;
    NextToken();
    NextToken();
    if (CompareToken(")"))
    {
        NextToken();
    }
    else if (CompareToken("void") && CompareTokenIdx(")", 1))
    {
        NextToken();
        NextToken();
    }
    else
    {
        EmitParmStart();
        while(1)
        {
            NeedTokens(2);
            if (CompareToken(")"))
            {
                EmitParmEnd();
                NextToken();
                break;
            }
            numparms++;
            typeidx = SearchList(types, TokenStr());
            if (typeidx < 0)
                InitType(type, 4, 1, 0, 0, 0, 0);
            else
                ProcessType(typeidx, type);
            AddSymbol(TokenStr(), type->size, type->signflag, 0, type->pointer, localvars, localvaraddr++);
            EmitLocalVar(TokenStr());
            NextToken();
            if (CompareToken(","))
            {
                NextToken();
            }
        }
    }
    localvaraddr = 0;
    EmitNumParmsCode(numparms);
    if (CheckExpect("{")) NextToken();
    while (strcmp(TokenStr(), "}"))
    {
        if (eof())
        {
            CheckExpect("}");
            EmitReturn(localvaraddr*4);
            reg_indx = 0;
            //PrintSymbols();
            RemoveLocals();
            return;
        }
        ProcessStatement(0, 0);
    }
    EmitReturn(localvaraddr*4);
    NextToken();
    if (debugflag) PrintSymbols();
    RemoveLocals();
    localvars = 0;
    localvaraddr = 0;
}

int ArraySize(SymbolT *type)
{
    int numelem = type->array;
    if (!type->pointer && localvars)
    {
        if (type->size == 1) return (numelem + 3) >> 2;
        else if (type->size == 2) return (numelem + 1) >> 1;
    }
    return numelem;
}

void ProcessType(int typeidx, SymbolT *type)
{
    InitType(type, typesize[typeidx], typesign[typeidx], 0, 0, 0, 0);
    NextToken();
    typeidx = SearchList(types, TokenStr());
    if (typeidx >= 0)
    {
        type->size = typesize[typeidx];
        NextToken();
    }
    while (CompareToken("*"))
    {
        type->pointer++;
        NextToken();
    }
}

void ProcessDeclaration(int typeidx)
{
    SymbolT type;
    ProcessType(typeidx, &type);
    NeedTokens(2);
    if (!strcmp(TokenIdx(1), "("))
        ProcessFunctionDeclaration(&type);
    else
        ProcessVariableDeclaration(&type);
}

// Process variable declarations of the form "int var1, var2, ...;"
// If the localvars flag is set generate a list of variable names on
// the same line.  Otherwise, generate one variable per line.
void ProcessVariableDeclaration(SymbolT *type)
{
    char *str;
    char *typestr;
    int numelem = 0;
    int newline = 0;
    StringT *sptr;
    if (localvars == 1)
    {
        localvars = 2;
        localvaraddr = 0;
    }
    while (1)
    {
        while (CompareToken("*"))
        {
            type->pointer++;
            NextToken();
        }
        sptr = DetachToken();
        str = sptr->str;
        if (CompareToken("["))
        {
            SkipBrackets(sptr);
            if (!strcmp(sptr->next->next->str, "]"))
                type->array = -1;
            else
                type->array = atol(sptr->next->next->str);
        }
        if (localvars)
        {
            AddSymbol(str, type->size, type->signflag, type->array, type->pointer, localvars, localvaraddr);
            if (type->array <= 0)
                localvaraddr++;
            else
            {
                int size = type->size;
                if (type->pointer) size = 4;
                size *= type->array;
                size = (size + 3) / 4;
                localvaraddr += size;
            }
        }
        else
            AddSymbol(str, type->size, type->signflag, type->array, type->pointer, localvars, globalvaraddr++);
        typestr = "long";
        if (!localvars)
        {
            if (type->pointer)
            {
                CheckAlignment(4);
                Emit1a("%s long", str);
            }
            else
            {
                CheckAlignment(type->size);
                typestr = typename[type->size];
                Emit2aa("%s %s", str, typestr);
            }
        }
        //printf("Token = %s\n", TokenStr());
        if (CompareToken("="))
        {
            if (TokenLast())
            {
                newline = 1;
            }
            NextToken();
            //printf("Token2 = %s\n", TokenStr());
            if (CompareToken("{"))
            {
                if (TokenLast())
                {
                    newline = 1;
                }
                NextToken();
                //printf("Token3 = %s\n", TokenStr());
                while (!CompareToken("}"))
                {
                    if (newline)
                    {
                        newline = 0;
                        Emit1a("  %s", typestr);
                    }
                    numelem++;
                    str = TokenStr();
                    if (str[0] == '0' && str[1] == 'x')
                        Emit1a(" $%s", str+2);
                    else
                        Emit1a(" %s", str);
                    if (TokenLast())
                    {
                        Emit("\n");
                        newline = 1;
                    }
                    NextToken();
                    if (TokenLast())
                    {
                        Emit("\n");
                        newline = 1;
                    }
                    if (CompareToken(","))
                    {
                        if (!newline) Emit(",");
                        NextToken();
                    }
                }
                type->array = numelem;
            }
            else
                Emit1i(" %d", atol(TokenStr()));
            NextToken();
        }
        else
        {
            if (!localvars) Emit(" 0");
            if (!localvars && type->array) Emit1i("[%d]", ArraySize(type));
        }
        type->array = 0;
        type->pointer = 0;
        if (!localvars) Emit("\n");
        FreeList(sptr);
        if (CompareToken(","))
        {
            NextToken();
            continue;
        }
        if (CompareToken(";")) break;
        printf("Expected ',' or ';' but encountered %s\n", TokenStr());
        break;
    }
    NextToken();
}

// Generate the Spasm code for calling a function
void ProcessFunctionCall(char *fname, int retflag)
{
    //int numparms;
    SymbolT type1, type2;

    //if (!strcmp(fname, "strlen")) fname = "strsize";

    if (SearchList(intrinsics, fname) >= 0)
    {
        if (!strcmp(fname, "va_start"))
        {
            char varname[80];
            if (!CheckExpect("(")) return;
            NextToken();
            strcpy(varname, TokenStr());
            GetType(varname, &type1);
            NextToken();
            if (!CheckExpect(",")) return;
            NextToken();
            GetType(TokenStr(), &type2);
            EmitLoadNumber(type2.value);
            EmitLoadVarAddress(varname, type1.value, type1.local);
            ProcessAbsoluteAssignment(GetParmChar(&type1), 0, retflag, &type1);
            NextToken();
            if (!CheckExpect(")")) return;
            NextToken();
        }
        else if (!strcmp(fname, "va_arg"))
        {
            if (!CheckExpect("(")) return;
            NextToken();
            PreIncrement(TokenStr(), &type1, 1, 1);
            EmitLoadRegIndexed();
            NextToken();
            if (!CheckExpect(",")) return;
            NextToken();
            CheckExpect("int");
            NextToken();
            if (!CheckExpect(")")) return;
            NextToken();
        }
        else if (!strcmp(fname, "va_end"))
        {
            if (!CheckExpect("(")) return;
            NextToken();
            NextToken();
            if (!CheckExpect(")")) return;
            NextToken();
            Emit("\n");
        }
        else
        {
            ProcessCallParms();
            EmitIntrinsic(fname);
        }
        return;
    }

    EmitCallPrep(retflag);
    //numparms = ProcessCallParms();
    ProcessCallParms();
    EmitCall(retflag, fname);
}

char *CheckAssignmentOp(int index, SymbolT *type)
{
    char *opstr1 = aopcode[index];
    if (index == AS_SHIFTR)
    {
        if (type->signflag) opstr1 = "sar";
    }
    else if (index == AS_PLUS || index == AS_MINUS)
    {
        if (type->pointer || type->array)
        {
            if (type->size > 1)
            {
                if (type->size == 2)
                    EmitLoadNumberStr("1");
                else
                    EmitLoadNumberStr("2");
                EmitOpcode(OP_SHIFTL, 0);
            }
        }
    }
    return opstr1;
}

// Process a statment of the form "variable = expression"
void ProcessVariableAssignment(char *varname, int index, int retflag, int absolute, int indexed, SymbolT *type)
{
    char *parmstr = ParmStr(varname, absolute, indexed, type);
    EmitVariableAssignment(varname, index, retflag, absolute, indexed, parmstr[0], type->signflag, type->local, type->value);
}

void ProcessAbsoluteAssignment(int parmchar, int index, int retflag, SymbolT *type)
{
    EmitVariableAssignment(0, index, retflag, 1, 0, parmchar, 0, type->local, type->value);
}

// Check if localvars is set and statment does not begin with a type
void CheckEndOfLocalVars(int typeidx)
{
    if (localvars && typeidx < 0)
    {
        localvars = 0;
        Emit("\n");
        EmitAllocateStackSpace(localvaraddr*4);
    }
}

// Generate the Spasm code for calling parameter between paretheses,
// and separated by commas
int ProcessCallParms(void)
{
    SymbolT type;
    int numparms = 0;
    NextToken();
    while(1)
    {
        if (CompareToken(")"))
        {
	    NextToken();
	    break;
	}
        numparms++;
        ProcessExpression(0, &type);
        if (CompareToken(","))
	    NextToken();
    }
    return numparms;
}

// Generate the Spasm code to embed a string and load its address
void ProcessString(char *str)
{
    EmitEmbeddedString(str, labelnum, labelnum+1);
    labelnum += 2;
}

// Check if current token matches the passed string, and return 1 for a match.
// Otherwise, print an error message and return 0;
int CheckExpect(char *str)
{
    if (strcmp(TokenStr(), str))
    {
        printf("Expected '%s' but encountered %s\n", str, TokenStr());
        PrintLine();
        return 0;
    }
    return 1;
}

// Proccess all of the statements between braces
void ProcessBraces(int breaknum, int continuenum)
{
    NextToken();
    while (strcmp(TokenStr(), "}"))
    {
        if (eof())
        {
            CheckExpect("}");
            return;
        }
        ProcessStatement(breaknum, continuenum);
    }
    NextToken();
}

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
