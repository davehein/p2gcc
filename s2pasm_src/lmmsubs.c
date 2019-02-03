#include <stdio.h>
#include <string.h>
#include <stdlib.h>

FILE *infile;
FILE *outfile;

#define NEW_LINE "\r\n"

void RemoveCRLF(char *str);
char *FindString(char *str1, char *str2);

char buffer1[1000];

char *FindCharX(char *ptr, int val)
{
    while (*ptr)
    {
        if (*ptr == val) return ptr;
        ptr++;
    }
    return 0;
}

int whitespace(int val)
{
    return (val == ' ' || val == '\t' || val == 0);
}

char *FindWord(char *ptr, char *word)
{
    int prevchar = ' ';
    int len = strlen(word);

    while (*ptr)
    {
        if (!strncmp(ptr, word, len) && whitespace(prevchar) && strlen(ptr) >= len && whitespace(ptr[len])) return ptr;
        prevchar = *ptr++;
    }
    return 0;
}

int Modify(char *old, char *new, char *modstr)
{
    char *ptr;
    char *ptr1;

    if ((ptr = FindWord(buffer1, old)) && (ptr1 = FindCharX(buffer1, '#')))
    {
        *ptr = 0;
        *ptr1 = 0;
        fprintf(outfile, "%s%s%s%s%s%s", buffer1, new, ptr + strlen(old), modstr, ptr1 + 1, NEW_LINE);
        return 1;
    }
    return 0;
}

int CheckLmmJmp(void)
{
    if (strcmp(buffer1, "\tjmp\t#__LMM_JMP")) return 0;
    fgets(buffer1, 1000, infile);
    fprintf(outfile, "\tjmp\t#%s%s", buffer1+6, NEW_LINE);
    return 1;
}

int CheckLmmCallIndirect(void)
{
    if (strcmp(buffer1, "\tjmp\t#__LMM_CALL_INDIRECT")) return 0;
    fprintf(outfile, "\tcalld\tlr,__TMP0%s", NEW_LINE);
    return 1;
}

int CheckMovPcLr(void)
{
    if (strcmp(buffer1, "\tmov\tpc,lr")) return 0;
printf("Found mov sp,lr\n");
    fprintf(outfile, "\tjmp\tlr%s", NEW_LINE);
    return 1;
}

int CheckMorePc(void)
{
    char *ptr = FindString(buffer1, "add\tpc,#8");

    if (*ptr == 0) return 0;
    printf("Found PC\n");
    *ptr = 0;
    fprintf(outfile, "%sjmp\t#$+8%s", buffer1, NEW_LINE);
    return 1;
}

int CheckPushPop(void)
{
    int num, reg;

    if (strncmp(buffer1, "\tmov\t__TMP0,#(", 14) || strncmp(buffer1+15, "<<4)+", 5)) return 0;
    num = atoi(buffer1+14);
    reg = atoi(buffer1+20);
    printf("PUSH or POP %d %d\n", num, reg);
    fgets(buffer1, 1000, infile);
    RemoveCRLF(buffer1);
    if (!strcmp(buffer1, "\tcall\t#__LMM_PUSHM"))
    {
#if 0
        while (num-- > 1)
        {
            fprintf(outfile, "\tsub\tsp,#4%s", NEW_LINE);
            fprintf(outfile, "\twrlong\tr%d,sp%s", reg++, NEW_LINE);
        }
#else
        fprintf(outfile, "\tsub\tsp,#%d*4%s", num-1, NEW_LINE);
        fprintf(outfile, "\tsetq\t#%d%s", num-2, NEW_LINE);
        fprintf(outfile, "\twrlong\tr%d,sp%s", reg, NEW_LINE);
#endif
        fprintf(outfile, "\tsub\tsp,#4%s", NEW_LINE);
        fprintf(outfile, "\twrlong\tlr,sp%s", NEW_LINE);
    }
    else if (!strcmp(buffer1, "\tcall\t#__LMM_POPRET"))
    {
        fprintf(outfile, "\trdlong\tlr,sp%s", NEW_LINE);
        fprintf(outfile, "\tadd\tsp,#4%s", NEW_LINE);
#if 0
        while (num-- > 1)
        {
            fprintf(outfile, "\trdlong\tr%d,sp%s", --reg, NEW_LINE);
            fprintf(outfile, "\tadd\tsp,#4%s", NEW_LINE);
        }
#else
        fprintf(outfile, "\tsetq\t#%d%s", num-2, NEW_LINE);
        fprintf(outfile, "\trdlong\tr%d,sp%s", reg-num+1, NEW_LINE);
        fprintf(outfile, "\tadd\tsp,#%d*4%s", num-1, NEW_LINE);
#endif
        fprintf(outfile, "\tjmp\tlr%s", NEW_LINE);
    }
    else
    {
        printf("ERROR: Not push or pop\n");
        printf("%s\n", buffer1);
    }
    return 1;
}
