#define OP_MULTIPY  0
#define OP_DIVIDE   1
#define OP_MOD      2
#define OP_PLUS     3
#define OP_MINUS    4
#define OP_SHIFTL   5
#define OP_SHIFTR   6
#define OP_CMPLT    7
#define OP_CMPLE    8
#define OP_CMPGT    9
#define OP_CMPGE    10
#define OP_CMPEQ    11
#define OP_CMPNE    12
#define OP_AND      13
#define OP_XOR      14
#define OP_OR       15
#define OP_ANDL     16
#define OP_ORL      17

#define AS_NULL   0
#define AS_PLUS   1
#define AS_MINUS  2
#define AS_MULT   3
#define AS_DIVIDE 4
#define AS_MOD    5
#define AS_SHIFTL 6
#define AS_SHIFTR 7
#define AS_AND    8
#define AS_OR     9
#define AS_XOR    10

void EmitHeader(void);
void Emit(char *fmtstr);
void Emit1a(char *fmtstr, char *parm1);
void Emit1i(char *fmtstr, int parm1);
void Emit2aa(char *fmtstr, char *parm1, char *parm2);
void Emit2ii(char *fmtstr, int parm1, int parm2);
void Emit2ia(char *fmtstr, int parm1, char *parm2);
void Emit2ai(char *fmtstr, char *parm1, int parm2);
void Emit3aii(char *fmtstr, char *parm1, int parm2, int parm3);
void Emit3aia(char *fmtstr, char *parm1, int parm2, char *parm3);
void EmitJump(int num);
void EmitJumpOnZero(int num);
void EmitJumpOnNonZero(int num);
void EmitLabel(int num);
void EmitLoadReg(char *varname);
void EmitLoadVarAddress(char *varname, int value, int local);
void EmitLoadNumberStr(char *numstr);
void EmitLoadNumber(int num);
void EmitNegate(void);
void EmitLogicalNot(void);
void EmitLoadVar(char *varname, int signflag, int size, int pointer, int value);
//void EmitLoadAddress(char *varname);
void EmitLoadAbsolute(int parmchar);
void EmitLoadAbsoluteIndexed(int parmchar);
void EmitSignExtend(int parmchar, int reg_indx1);
void CallFunc(char *funcname);
void EmitOpcode(int opdex, int signflag);
void EmitVariableAssignment(char *varname, int index, int retflag, int absolute, int indexed, int parmchar, int signflag, int local, int value);
void EmitIncrement(char *varname, int post, int incrsize, int plus, int retflag, int size, int pointer, int signflag, int absolute, int indexed, int parmchar, int local, int value);
void EmitCallPrep(int retflag);
void EmitCall(int retflag, char *funcname);
void EmitReturn(int stackspace);
void EmitReturnValue(int stackspace);
void EmitEmbeddedString(char *str, int label1, int label2);
void EmitLabelString(char *str);
void EmitParmStart(void);
void EmitParmEnd(void);
void EmitLocalVar(char *varname);
void EmitNumParmsCode(int numparms);
void EmitLoadParm(int num);
void EmitLoadLocal(int num);
void EmitFunctionStart(char *funcname);
void EmitLoadVariable(char *varname, int signflag, int size, int pointer, int array, int local, int value);
void EmitIntrinsic(char *funcname);
void EmitQuotedString(char *str);
void EmitComplement(void);
void EmitAddAbsoluteIndexed(int parmchar);
void EmitAlignment(int size);
void EmitLoadRegIndexed(void);
void EmitAllocateStackSpace(int stackspace);
