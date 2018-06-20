typedef struct SymbolS {
    struct SymbolS *next;
    int size;
    int signflag;
    int array;
    int pointer;
    int local;
    int value;
    char name[1];
} SymbolT;

void AddSymbol(char *name, int size, int signflag, int array, int pointer, int local, int value);
void PrintSymbols(void);
void RemoveLocals(void);
SymbolT *FindSymbol(char *name);
SymbolT *FindSymbolNeed(char *name);
void GeneratePicTable(void);
