//******************************************************************************
// Copyright (c) 2015 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "gencode.h"
#include "cstrsubs.h"
#include "ctokens.h"

FILE *outfile;
int reg_indx;
char callstack[100];
int cs_index = 0;
int nopflag;
int globalflag;

static char size2char[] = {'v', 'b', 'w', 'x', 'l', 0, 0, 0};

#define USE_CALLD

// Write the Spasm header
void EmitHeader(void)
{
    char buffer[200];
#ifdef __P2GCC__
    FILE *prefile = fopen("/lib/prefix.spi", "r");
#else
    FILE *prefile = fopen("prefix.spin2", "r");
#endif
    while (fgets(buffer, 200, prefile))
        Emit(buffer);
    fclose(prefile);
}

static char *GetTypeStrFromChar(int val)
{
    char *typestr = "????";
    if (val == 'b') typestr = "byte";
    else if (val == 'w') typestr = "word";
    else if (val == 'l') typestr = "long";
    return typestr;
}

void Emit(char *str)
{
    fputs(str, outfile);
    SetPrintNL();
}

void Emit1a(char *fmtstr, char *parm1)
{
    fprintf(outfile, fmtstr, parm1);
    SetPrintNL();
}

void Emit1i(char *fmtstr, int parm1)
{
    fprintf(outfile, fmtstr, parm1);
    SetPrintNL();
}

void Emit2aa(char *fmtstr, char *parm1, char *parm2)
{
    fprintf(outfile, fmtstr, parm1, parm2);
    SetPrintNL();
}

void Emit2ii(char *fmtstr, int parm1, int parm2)
{
    fprintf(outfile, fmtstr, parm1, parm2);
    SetPrintNL();
}

void Emit2ia(char *fmtstr, int parm1, char *parm2)
{
    fprintf(outfile, fmtstr, parm1, parm2);
    SetPrintNL();
}

void Emit2ai(char *fmtstr, char *parm1, int parm2)
{
    fprintf(outfile, fmtstr, parm1, parm2);
    SetPrintNL();
}

void Emit3aii(char *fmtstr, char *parm1, int parm2, int parm3)
{
    fprintf(outfile, fmtstr, parm1, parm2, parm3);
    SetPrintNL();
}

void Emit3aia(char *fmtstr, char *parm1, int parm2, char *parm3)
{
    fprintf(outfile, fmtstr, parm1, parm2, parm3);
    SetPrintNL();
}

void EmitNops(int num)
{
    int i;

    if (!num) num = nopflag;

    for (i = 0; i < num; i++)
        Emit("        nop\n");
}

void EmitJump(int num)
{
    Emit1i("        jmp     #label%04d\n", num);
    EmitNops(0);
}

void EmitJumpOnZero(int num)
{
    Emit1i("        cmp     r%d, #0  wz\n", --reg_indx);
    Emit1i(" if_z   jmp     #label%04d\n", num);
    EmitNops(0);
}

void EmitJumpOnNonZero(int num)
{
    Emit1i("        cmp     r%d, #0  wz\n", --reg_indx);
    Emit1i(" if_nz  jmp     #label%04d\n", num);
    EmitNops(0);
}

void EmitLabel(int num)
{
    Emit1i("label%04d\n", num);
}

void EmitLoadReg(char *varname)
{
    Emit2ia("        mov     r%d, %s\n", reg_indx++, varname);
}

void EmitLoadVarAddress(char *varname, int value, int local)
{
    if (local == 1)
    {
        printf("%d: ERROR: Can't get address of register variable %s\n", GetLineNumber(), varname);
        PrintLine();
        Emit1a("ERROR: Can't get address of register variable %s\n", varname);
        Emit1i("        mov     r%d, #0\n", reg_indx++);
    }
    else if (local == 2)
    {
        if (value*4 < 512)
            Emit2ii("        mov     r%d, #%d\n", reg_indx, value*4);
        else
            Emit2ii("        mov     r%d, ##%d\n", reg_indx, value*4);
        Emit1i("        add     r%d, sp\n", reg_indx++);
    }
    else
    {
        Emit2ia("        mov     r%d, ##%s\n", reg_indx++, varname);
    }
}

void EmitLoadRegIndexed(void)
{
    Emit1i("        alts    r%d, #r0\n", reg_indx-1);
    Emit1i("        mov     r%d, 0-0\n", reg_indx-1);
}

void EmitLoadNumberStr(char *numstr)
{
    int val;
    if (strlen(numstr) >= 2 && numstr[1] == 'x')
    {
        sscanf(numstr+2, "%x", &val);
        if (val < 512 && val >= 0)
            Emit2ia("        mov     r%d, #$%s\n", reg_indx++, numstr+2);
        else
            Emit2ia("        mov     r%d, ##$%s\n", reg_indx++, numstr+2);
    }
    else
    {
        sscanf(numstr, "%d", &val);
        if (val < 512 && val >= 0)
            Emit2ia("        mov     r%d, #%s\n", reg_indx++, numstr);
        else
            Emit2ia("        mov     r%d, ##%s\n", reg_indx++, numstr);
    }
}

void EmitLoadNumber(int val)
{
    if (val < 512 && val >= 0)
        Emit2ii("        mov     r%d, #%d\n", reg_indx++, val);
    else
        Emit2ii("        mov     r%d, ##%d\n", reg_indx++, val);
}

void EmitNegate(void)
{
    Emit2ii("        neg     r%d, r%d\n", reg_indx-1, reg_indx-1);
}

void EmitLogicalNot(void)
{
    Emit1i("        cmp     r%d, #0  wz\n", reg_indx-1);
    Emit1i(" if_z   mov     r%d, #1\n", reg_indx-1);
    Emit1i(" if_nz  mov     r%d, #0\n", reg_indx-1);
}

void EmitComplement(void)
{
    Emit1i("        xor     r%d, ##$ffffffff\n", reg_indx-1);
}

void EmitLoadVar(char *varname, int signflag, int size, int pointer, int value)
{
    int parmchar = 'l';

    if (!pointer)
        parmchar = size2char[size];

    Emit3aia("        rd%s  r%d, ##%s\n", GetTypeStrFromChar(parmchar), reg_indx++, varname);
    if (parmchar != 'l' && signflag)
            EmitSignExtend(parmchar, reg_indx-1);
}

void EmitLoadVariable(char *varname, int signflag, int size, int pointer, int array, int local, int value)
{
    if (array)
        EmitLoadVarAddress(varname, value, local);
    else if (local == 1)
        EmitLoadParm(value);
    else if (local == 2)
        EmitLoadLocal(value);
    else
        EmitLoadVar(varname, signflag, size, pointer, value);
}

void EmitLoadParm(int num)
{
    Emit2ii("        mov     r%d, r%d\n", reg_indx++, num);
}

void EmitLoadLocal(int num)
{
    if (num*4 < 512)
        Emit2ii("        mov     r%d, #%d\n", reg_indx, num * 4);
    else
        Emit2ii("        mov     r%d, ##%d\n", reg_indx, num * 4);
    Emit1i("        add     r%d, sp\n", reg_indx);
    Emit2ii("        rdlong  r%d, r%d\n", reg_indx, reg_indx);
    reg_indx++;
}

void EmitLoadAbsolute(int parmchar)
{
    Emit3aii("        rd%s  r%d, r%d\n", GetTypeStrFromChar(parmchar), reg_indx-1, reg_indx-1);
}

void EmitAddAbsoluteIndexed(int parmchar)
{
    int shiftval = 0;
    if (parmchar == 'l') shiftval = 2;
    else if (parmchar == 'w') shiftval = 1;
    if (shiftval)
        Emit2ii("        shl     r%d, #%d\n", reg_indx-1, shiftval);
    reg_indx--;
    Emit2ii("        add     r%d, r%d\n", reg_indx-1, reg_indx);
}

void EmitLoadAbsoluteIndexed(int parmchar)
{
    int shiftval = 0;
    if (parmchar == 'l') shiftval = 2;
    else if (parmchar == 'w') shiftval = 1;
    if (shiftval)
        Emit2ii("        shl     r%d, #%d\n", reg_indx-1, shiftval);
    reg_indx--;
    Emit2ii("        add     r%d, r%d\n", reg_indx-1, reg_indx);
    Emit3aii("        rd%s  r%d, r%d\n", GetTypeStrFromChar(parmchar), reg_indx-1, reg_indx-1);
}

void EmitSignExtend(int parmchar, int reg_indx1)
{
    int shlen = (parmchar == 'b') ? 24 : 16;
    Emit2ii("        shl     r%d, #%d\n", reg_indx1, shlen);
    Emit2ii("        sar     r%d, #%d\n", reg_indx1, shlen);
}

void CallFunc(char *funcname)
{
#ifdef USE_CALLD
    Emit1a("        calld   lr, #_%s\n", funcname);
#else
    Emit1a("        call    #%s\n", funcname);
#endif
    EmitNops(0);
}

void EmitOpcode(int opdex, int signflag)
{
    reg_indx--;
    switch (opdex)
    {
        case OP_MULTIPY:
            Emit2ii("        qmul    r%d, r%d\n", reg_indx-1, reg_indx);
            Emit1i("        getqx   r%d\n", reg_indx-1);
            break;
        case OP_DIVIDE:
            // TODO: Handle unsigned divide
#if 1
            if (reg_indx-1 != 0)
            {
                Emit("        sub     sp, #4\n");
                Emit("        wrlong  r0, sp\n");
                Emit1i("        mov     r0, r%d\n", reg_indx-1);
            }
            if (reg_indx-1 != 1)
            {
                Emit("        sub     sp, #4\n");
                Emit("        wrlong  r1, sp\n");
            }
            if (reg_indx != 1)
                Emit1i("        mov     r1, r%d\n", reg_indx);
            Emit("        call    #__DIVSI\n");
            if (reg_indx-1 != 1)
            {
                Emit("        rdlong  r1, sp\n");
                Emit("        add     sp, #4\n");
            }
            if (reg_indx-1 != 0)
            {
                Emit1i("        mov     r%d, r0\n", reg_indx-1);
                Emit("        rdlong  r0, sp\n");
                Emit("        add     sp, #4\n");
            }
#else
            Emit1i("        mov     parm1, r%d\n", reg_indx-1);
            Emit1i("        mov     parm2, r%d\n", reg_indx);
            Emit("        call    #_divide_\n");
            Emit1i("        mov     r%d, parm1\n", reg_indx-1);
#endif
            break;
        case OP_MOD:
            // TODO: Handle unsigned modulus
#if 1
            if (reg_indx-1 != 0)
            {
                Emit("        sub     sp, #4\n");
                Emit("        wrlong  r0, sp\n");
                Emit1i("        mov     r0, r%d\n", reg_indx-1);
            }
            if (reg_indx-1 != 1)
            {
                Emit("        sub     sp, #4\n");
                Emit("        wrlong  r1, sp\n");
            }
            if (reg_indx != 1)
                Emit1i("        mov     r1, r%d\n", reg_indx);
            Emit("        call    #__DIVSI\n");
            if (reg_indx-1 != 1)
            {
                Emit1i("        mov     r%d, r1\n", reg_indx-1);
                Emit("        rdlong  r1, sp\n");
                Emit("        add     sp, #4\n");
            }
            if (reg_indx-1 != 0)
            {
                Emit("        rdlong  r0, sp\n");
                Emit("        add     sp, #4\n");
            }
#else
            Emit1i("        mov     parm1, r%d\n", reg_indx-1);
            Emit1i("        mov     parm2, r%d\n", reg_indx);
            Emit("        call    #_modulus_\n");
            Emit1i("        mov     r%d, parm1\n", reg_indx-1);
#endif
            break;
        case OP_PLUS:
            Emit2ii("        add     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_MINUS:
            Emit2ii("        sub     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_SHIFTL:
            Emit2ii("        shl     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_SHIFTR:
            if (signflag)
                Emit2ii("        sar     r%d, r%d\n", reg_indx-1, reg_indx);
            else
                Emit2ii("        shr     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_CMPLT:
            if (signflag)
                Emit2ii("        cmps    r%d, r%d  wc\n", reg_indx-1, reg_indx);
            else
                Emit2ii("        cmp     r%d, r%d  wc\n", reg_indx-1, reg_indx);
            Emit1i(" if_c   mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_nc  mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_CMPLE:
            if (signflag)
                Emit2ii("        cmps    r%d, r%d wc\n", reg_indx, reg_indx-1);
            else
                Emit2ii("        cmp     r%d, r%d wc\n", reg_indx, reg_indx-1);
            Emit1i(" if_nc  mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_c   mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_CMPGT:
            if (signflag)
                Emit2ii("        cmps    r%d, r%d wc\n", reg_indx, reg_indx-1);
            else
                Emit2ii("        cmp     r%d, r%d wc\n", reg_indx, reg_indx-1);
            Emit1i(" if_c   mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_nc  mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_CMPGE:
            if (signflag)
                Emit2ii("        cmps    r%d, r%d  wc\n", reg_indx-1, reg_indx);
            else
                Emit2ii("        cmp     r%d, r%d  wc\n", reg_indx-1, reg_indx);
            Emit1i(" if_nc  mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_c   mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_CMPEQ:
            Emit2ii("        cmp     r%d, r%d  wz\n", reg_indx-1, reg_indx);
            Emit1i(" if_z   mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_nz  mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_CMPNE:
            Emit2ii("        sub     r%d, r%d  wz\n", reg_indx-1, reg_indx);
            Emit1i(" if_nz  mov     r%d, #1\n", reg_indx-1);
            break;
        case OP_AND:
            Emit2ii("        and     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_XOR:
            Emit2ii("        xor     r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_OR:
            Emit2ii("        or      r%d, r%d\n", reg_indx-1, reg_indx);
            break;
        case OP_ANDL:
            Emit1i("        cmp     r%d, #0  wz\n", reg_indx-1);
            Emit1i(" if_nz  cmp     r%d, #0  wz\n", reg_indx);
            Emit1i(" if_nz  mov     r%d, #1\n", reg_indx-1);
            Emit1i(" if_z   mov     r%d, #0\n", reg_indx-1);
            break;
        case OP_ORL:
            Emit2ii("        or      r%d, r%d  wz\n", reg_indx-1, reg_indx);
            Emit1i(" if_nz  mov     r%d, #1\n", reg_indx-1);
            break;
    }
}

char *SetupVarAccess(char *varname, int absolute, int indexed, int parmchar, int local, int value, char *addrstr)
{
    char *typestr = GetTypeStrFromChar(parmchar);
    int shiftval = 0;
    if (parmchar == 'l') shiftval = 2;
    else if (parmchar == 'w') shiftval = 1;

    strcpy(addrstr, "????");

    if (parmchar == 'r')
    {
        strcpy(addrstr, varname);
    }
    else if (local == 1 && !absolute)
    {
        sprintf(addrstr, "r%d", value);
    }
    else if (local == 2 && !absolute)
    {
        sprintf(addrstr, "r%d", reg_indx);
        if (value*4 < 512)
            Emit2ai("        mov     %s, #%d\n", addrstr, value*4);
        else
            Emit2ai("        mov     %s, ##%d\n", addrstr, value*4);
        Emit1a("        add     %s, sp\n", addrstr);
    }
    else if (absolute)
    {
        if (indexed)
        {
            reg_indx -= 3;
            if (shiftval) Emit2ii("        shl     r%d, #%d\n", reg_indx+2, shiftval);
            Emit2ii("        add     r%d, r%d\n", reg_indx+1, reg_indx+2);
            sprintf(addrstr, "r%d", reg_indx+1);
            reg_indx++;
        }
        else
        {
            reg_indx -= 2;
            sprintf(addrstr, "r%d", reg_indx+1);
            reg_indx++;
        }
    }
    else
    {
        if (indexed)
        {
            reg_indx -= 2;
            if (shiftval) Emit2ii("        shl     r%d, #%d\n", reg_indx+1, shiftval);
            Emit2ia("        add     r%d, ##%s\n", reg_indx+1, varname);
            sprintf(addrstr, "r%d", reg_indx+1);
            reg_indx++;
        }
        else
        {
            sprintf(addrstr, "##%s", varname);
        }
    }
    return typestr;
}

void EmitReadAccess(char *addrstr, char *typestr, int parmchar, int local, int signflag, int reg_indx1)
{
    if (parmchar == 'r' || local == 1)
        Emit2ia("        mov     r%d, %s\n", reg_indx1, addrstr);
    else
    {
        Emit3aia("        rd%s  r%d, %s\n", typestr, reg_indx1, addrstr);
        if (parmchar != 'l' && signflag) EmitSignExtend(parmchar, reg_indx1);
    }
}

void EmitWriteAccess(char *addrstr, char *typestr, int parmchar, int local, int reg_indx1, int absolute)
{
//fprintf(outfile, "EmitWriteAccess: addrstr = %s, typestr = %s, parmchar = %c, local = %d\n", addrstr, typestr, parmchar, local);
    if (parmchar == 'r' || (local == 1 && !absolute))
        Emit2ai("        mov     %s, r%d\n", addrstr, reg_indx1);
    else
    {
        Emit3aia("        wr%s  r%d, %s\n", typestr, reg_indx1, addrstr);
    }
}

void EmitIncrement(char *varname, int post, int incrsize, int plus, int retflag, int size, int pointer, int signflag, int absolute, int indexed, int parmchar, int local, int value)
{
    int reg_indx0 = reg_indx++;
    int reg_indx1 = reg_indx++;
    char addrstr[40];
    char *typestr = SetupVarAccess(varname, absolute, indexed, parmchar, local, value, addrstr);

    EmitReadAccess(addrstr, typestr, parmchar, local, signflag, reg_indx0);

    if (retflag && post)
        Emit2ii("        mov     r%d, r%d\n", reg_indx1, reg_indx0);
    else
        reg_indx1 = reg_indx0;

    if (plus)
        Emit2ii("        add     r%d, #%d\n", reg_indx1, incrsize);
    else
        Emit2ii("        sub     r%d, #%d\n", reg_indx1, incrsize);

    EmitWriteAccess(addrstr, typestr, parmchar, local, reg_indx1, absolute);

    reg_indx--;
    if (!retflag) reg_indx--;
}

void EmitVariableAssignment(char *varname, int index, int retflag, int absolute, int indexed, int parmchar, int signflag, int local, int value)
{
    int reg_indx1;
    char addrstr[40];
    char *typestr = SetupVarAccess(varname, absolute, indexed, parmchar, local, value, addrstr);

    reg_indx--;
    reg_indx1 = reg_indx+2;

//fprintf(outfile, "EmitVariableAssignment: reg_indx = %d, varname = %s, absolute = %d, indexed = %d, parmchar = %d, local = %d, value = %d, addrstr = %s\n",
//reg_indx, varname, absolute, indexed, parmchar, local, value, addrstr);

    if (index)
    {
        EmitReadAccess(addrstr, typestr, parmchar, local, signflag, reg_indx1);
        switch (index)
        {
            case AS_NULL:
                break;
            case AS_PLUS:
                Emit2ii("        add     r%d, r%d\n", reg_indx, reg_indx1);
                reg_indx1 = reg_indx;
                break;
            case AS_MINUS:
                Emit2ii("        sub     r%d, r%d\n", reg_indx1, reg_indx);
                break;
            case AS_MULT:
#if 0
                Emit1i("        mov     parm1, r%d\n", reg_indx);
                Emit1i("        mov     parm2, r%d\n", reg_indx1);
                Emit("        call    #multiply\n");
                EmitNops(2);
                Emit1i("        mov     r%d, parm1\n", reg_indx);
#else
                Emit2ii("        qmul    r%d, r%d\n", reg_indx, reg_indx1);
                Emit1i("        getqx   r%d\n", reg_indx);
#endif
                reg_indx1 = reg_indx;
                break;
            case AS_DIVIDE:
                // TODO: Handle unsigned divide
#if 1
                if (reg_indx1 != 0)
                {
                    Emit("        sub     sp, #4\n");
                    Emit("        wrlong  r0, sp\n");
                    Emit1i("        mov     r0, r%d\n", reg_indx1);
                }
                if (reg_indx1 != 1)
                {
                    Emit("        sub     sp, #4\n");
                    Emit("        wrlong  r1, sp\n");
                }
                if (reg_indx != 1)
                    Emit1i("        mov     r1, r%d\n", reg_indx);
                Emit("        call    #__DIVSI\n");
                if (reg_indx-1 != 1)
                {
                    Emit("        rdlong  r1, sp\n");
                    Emit("        add     sp, #4\n");
                }
                if (reg_indx1 != 0)
                {
                    Emit1i("        mov     r%d, r0\n", reg_indx1);
                    Emit("        rdlong  r0, sp\n");
                    Emit("        add     sp, #4\n");
                }
#else
                Emit1i("        mov     parm1, r%d\n", reg_indx1);
                Emit1i("        mov     parm2, r%d\n", reg_indx);
                Emit("        call    #_divide_\n");
                Emit1i("        mov     r%d, parm1\n", reg_indx1);
#endif
                break;
            case AS_MOD:
                // TODO: Handle unsigned modulus
                Emit1i("        mov     parm1, r%d\n", reg_indx1);
                Emit1i("        mov     parm2, r%d\n", reg_indx);
                Emit("        call    #_modulus_\n");
                Emit1i("        mov     r%d, parm1\n", reg_indx1);
                break;
            case AS_SHIFTL:
                Emit2ii("        shl     r%d, r%d\n", reg_indx1, reg_indx);
                break;
            case AS_SHIFTR:
                if (signflag)
                    Emit2ii("        sar     r%d, r%d\n", reg_indx1, reg_indx);
                else
                    Emit2ii("        shr     r%d, r%d\n", reg_indx1, reg_indx);
                break;
            case AS_AND:
                Emit2ii("        and     r%d, r%d\n", reg_indx, reg_indx1);
                reg_indx1 = reg_indx;
                break;
            case AS_OR:
                Emit2ii("        or      r%d, r%d\n", reg_indx, reg_indx1);
                reg_indx1 = reg_indx;
                break;
            case AS_XOR:
                Emit2ii("        xor     r%d, r%d\n", reg_indx, reg_indx1);
                reg_indx1 = reg_indx;
                break;
        }
    }
    else
    {
        reg_indx1 = reg_indx;
    }

    EmitWriteAccess(addrstr, typestr, parmchar, local, reg_indx1, absolute);

    if (retflag)
    {
        if (reg_indx1 != reg_indx)
            Emit2ii("        mov     r%d, r%d\n", reg_indx, reg_indx1);
        reg_indx++;
    }
}

void EmitCallPrep(int retflag)
{
    callstack[cs_index++] = reg_indx;
}

typedef struct VarFuncsS {
    char *fname;
    int numreg;
} VarFuncT;

VarFuncT varfuncs[] = { {"printf", 0}, {"scanf", 0}, {"sscanf", 1}, {0, 0}};

void EmitCall(int retflag, char *funcname)
{
    int i, numstack;
    int count = callstack[--cs_index];
    int numparms = reg_indx - count;
    VarFuncT *vf = varfuncs;
    int numreg = numparms;

    while (vf->fname)
    {
        if (!strcmp(funcname, vf->fname))
        {
            numreg = vf->numreg;
            break;
        }
        vf++;
    }
    if (numreg > 6) numreg = 6;
    numstack = numparms - numreg;

#if 0
    printf("EmitCall: retflag = %d, funcname = %s, count = %d, numparms = %d, numreg = %d, numstack = %d\n",
        retflag, funcname, count, numparms, numreg, numstack);
#endif

    if (count)
    {
        Emit1i("        sub     sp, #%d\n", 4*count);
        if (count > 1)
            Emit1i("        setq    #%d\n", count-1);
        Emit("        wrlong  r0, sp\n");

        for (i = 0; i < numreg; i++)
            Emit2ii("        mov     r%d, r%d\n", i, i + count);
    }

    if (numstack)
    {
        for (i = reg_indx-1; i >= count + numreg; i--)
        {
            Emit("        sub     sp, #4\n");
            Emit1i("        wrlong  r%d, sp\n", i);
        }
    }

    Emit1a("        calld   lr, #_%s\n", funcname);

    reg_indx = count;
    if (retflag)
    {
        Emit1i("        mov     r%d, r0\n", count);
        reg_indx++;
    }
    if (numstack)
        Emit1i("        add     sp, #%d\n", 4*numstack);

    if (count)
    {
        if (count > 1)
            Emit1i("        setq    #%d\n", count-1);
        Emit("        rdlong  r0, sp\n");
        Emit1i("        add     sp, #%d\n", 4*count);
    }
}

void EmitReturn(int stackspace)
{
    if (stackspace > 0)
    {
        if (stackspace < 512)
            Emit1i("        add     sp, #%d\n", stackspace);
        else
            Emit1i("        add     sp, ##%d\n", stackspace);
    }
#ifdef USE_CALLD
    Emit("        rdlong  lr, sp\n");
    Emit("        add     sp, #4\n");
    Emit("        jmp     lr\n");
#else
    Emit("        ret\n");
#endif
    EmitNops(0);
}

void EmitReturnValue(int stackspace)
{
    if (reg_indx > 1)
        Emit1i("        mov     r0, r%d\n", reg_indx-1);
    if (stackspace > 0)
    {
        if (stackspace < 512)
            Emit1i("        add     sp, #%d\n", stackspace);
        else
            Emit1i("        add     sp, ##%d\n", stackspace);
    }
#ifdef USE_CALLD
    Emit("        rdlong  lr, sp\n");
    Emit("        add     sp, #4\n");
    Emit("        jmp     lr\n");
#else
    Emit("        ret\n");
#endif
    EmitNops(0);
    reg_indx--;
}

void EmitEmbeddedString(char *str, int label1, int label2)
{
    char first = 1;
    char *ptr;
    Emit1i("        calld   lr, #label%04d\n", label2);
    Emit("        byte    ");
    if (*str == '"') str++;
    while (*str)
    {
        ptr = FindChars(str, "\"\\");
        if (ptr != str)
        {
            if (!first) Emit(", ");
            Emit("\"");
            while (ptr != str) Emit1i("%c", *str++);
            Emit("\"");
            first = 0;
        }
        if (*ptr == 0 || *ptr == '"')
        {
            if (!first) Emit(", ");
            Emit("0\n");
            Emit("        alignl\n");
            break;
        }
        str++;
        if (*str)
        {
            if (!first) Emit(", ");
            if (*str == 'n')
                Emit("10");
            else if (*str == 'r')
                Emit("13");
            else
                Emit1i("\"\\%c\"", *str);
            str++;
            first = 0;
        }
    }
    Emit1i("label%04d\n", label2);
    Emit1i("        mov     r%d, lr\n", reg_indx++);
}

void EmitLabelString(char *str)
{
    Emit1a("%s\n", str);
}

void EmitParmStart(void)
{
}

void EmitParmEnd(void)
{
}

void EmitLocalVar(char *varname)
{
}

void EmitNumParmsCode(int numparms)
{
    reg_indx += numparms;
}

void EmitAlignment(int size)
{
    if (size == 4)
        Emit("        alignl\n");
    else if (size == 2)
        Emit("        alignw\n");
}

void EmitFunctionStart(char *funcname)
{
#if 0
    if (globalflag)
        Emit1a("_%-7s global\n", funcname);
    else
        Emit1a("_%-7s\n", funcname);
#else
    if (globalflag)
        Emit1a("        .global _%s\n", funcname);
    Emit1a("_%s\n", funcname);
#endif
    //EmitLabelString(funcname);
#ifdef USE_CALLD
    Emit("        sub     sp, #4\n");
    Emit("        wrlong  lr, sp\n");
#endif
    //Emit("        sub     sp, #100\n");
    reg_indx = 0;
}

void EmitAllocateStackSpace(int stackspace)
{
    if (stackspace > 0)
    {
        if (stackspace < 512)
            Emit1i("        sub     sp, #%d\n", stackspace);
        else
            Emit1i("        sub     sp, ##%d\n", stackspace);
    }
}

void EmitIntrinsic(char *funcname)
{
    Emit2ai("        %-7s r%d\n", funcname, --reg_indx);
}

void EmitQuotedString(char *str)
{
    int len;
    if (str[0] == '"') str++;
    len = strlen(str) - 1;
    if (len >= 0 && str[len] == '"') str[len] = 0;
    Emit1a("%s\n", str);
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
