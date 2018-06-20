#define MAX_PREC     999
#define DOUBLE_QUOTE 0x22
#define SINGLE_QUOTE 0x27

#define KEYWORD_RETURN   0
#define KEYWORD_IF       1
#define KEYWORD_WHILE    2
#define KEYWORD_DO       3
#define KEYWORD_FOR      4
#define KEYWORD_BREAK    5
#define KEYWORD_CONTINUE 6
#define KEYWORD_INLINE   7

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

void usage(void);
int  ProcessCallParms(void);
void ProcessString(char *str);
void ProcessFunctionCall(char *fname, int retflag);
void OpenFiles(char *fname);
int  CheckExpect(char *str);
void ProcessReturnStatement(void);
void ProcessWhileStatement(void);
void ProcessIfStatement(int breaknum, int continuenum);
void ProcessDeclaration(int typeidx);
void ProcessType(int typeidx, SymbolT *type);
void ProcessFunctionDeclaration(SymbolT *type);
void ProcessVariableDeclaration(SymbolT *type);
void ProcessBraces(int breaknum, int continuenum);
void ProcessArrayAssignment(char *varname);
void CheckEndOfLocalVars(int keyword);
void ProcessStatement(int breaknum, int continuenum);
void EmitHeader(void);
void ProcessStatementOrBraces(int breaknum, int continuenum);
void ProcessDoStatement(void);
void ProcessForStatement(void);
void InitType(SymbolT *type, int size, int signflag, int array, int pointer, int local, int value);
void ProcessAbsoluteAssignment(int parmchar, int index, int retflag, SymbolT *type);
void ProcessExpression(int prec, SymbolT *type);
void ProcessValue(int retflag, SymbolT *type);
void ProcessVariableAssignment(char *varname, int index, int retflag, int absolute, int indexed, SymbolT *type);
void ProcessInline(void);
int  GetParmChar(SymbolT *type);
