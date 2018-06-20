#define HDR_SIZE 8

typedef struct StringS {
  struct StringS * next;
  int size;
  char str[1];
  } StringT;

void  NextToken(void);
void  SetPrintNL(void);
void  NeedTokens(int num);
char *TokenStr(void);
char *TokenIdx(int idx);
int   TokenLast(void);
int   CompareToken(char *str);
int   CompareTokenIdx(char *str, int idx);
void  Tokenize(char *ptr);
int   GetLine(void);
int   GetLineNumber(void);
int   eof(void);
void  Initialize(FILE *infile0, FILE *outfile0, int *plocalvars0);
void  AttachToken(StringT *sptr);
void  PrintLine(void);
void  EmitLine(void);
void  AttachTokens(StringT *sptr);
void  FreeList(StringT *list);
StringT *DetachToken(void);
StringT *GetTail(StringT *list);
