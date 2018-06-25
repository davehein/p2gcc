#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../p2link_src/p2link.h"

typedef struct ObjectTypeS {
    int type;
    char *descript;
} ObjectTypeT;

ObjectTypeT objtypes[] = {
    {OTYPE_GLOBAL_FUNC,  "Global Func   "},
    {OTYPE_REF_AUGS,     "Ref augs, s   "},
    {OTYPE_REF_AUGD,     "Ref augd, d   "},
    {OTYPE_REF_FUNC_UND, "Undef func ref"},
    {OTYPE_REF_FUNC_RES, "Resol func ref"},
    {OTYPE_REF_LONG_REL, "Reloc long ref"},
    {OTYPE_LOCAL_LABEL,  "Local Label   "},
    {OTYPE_INIT_DATA,    "Init data     "},
    {OTYPE_UNINIT_DATA,  "Uninit data   "},
    {OTYPE_REF_LONG_UND, "Undef long ref"},
    {OTYPE_REF_LONG_REL, "Resol long ref"},
    {OTYPE_END_OF_CODE,  "End of code   "},
    {0,                  "Invalid type  "}};

char *GetDescription(int type)
{
    ObjectTypeT *ot = objtypes;

    while (ot->type)
    {
        if (ot->type == type) break;
        ot++;
    }
    return ot->descript;
}

void usage(void)
{
    printf("usage: p2dumpobj file\n");
    exit(1);
}

int read_header(FILE *infile, char *fname)
{
    int addr0;
    char buffer[256];
    unsigned char len;
    int num = fread(buffer, 1, 8, infile);

    if (num == 0) exit(0);

    if (num != 8 || strncmp(buffer, "P2OBJECT", 8))
    {
        printf("%s contains an invalid P2 object file\n", fname);
        exit(1);
    }
    fread(&len, 1, 1, infile);
    fread(buffer, 1, len, infile);
    fread(&addr0, 1, 4, infile);
    printf("Object file %s, Starting address %x\n", buffer, addr0);
    return addr0;
}

int main(int argc, char **argv)
{
    FILE *infile;
    unsigned char type, len;
    char buffer[256];
    int num, value, addr0;

    if (argc != 2) usage();

    infile = fopen(argv[1], "rb");

    if (!infile)
    {
        printf("Couldn't open %s\n", argv[1]);
        exit(1);
    }

    addr0 = read_header(infile, argv[1]);
    while (1)
    {
        if (fread(&type, 1, 1, infile) != 1) break;
        fread(&value, 1, 4, infile);
        if (type == OTYPE_END_OF_CODE)
        {
            printf("End of code    %8.8x\n", value);
            value -= addr0;
            while (value > 0)
            {
                num = (value > 256) ? 256 : value;
                num = fread(buffer, 1, num, infile);
                if (num <= 0) break;
                value -= num;
            }
            addr0 = read_header(infile, argv[1]);
            continue;
        }
        fread(&len, 1, 1, infile);
        fread(buffer, 1, len, infile);
        printf("%s %8.8x %s\n", GetDescription(type), value, buffer);
    }

    return 0;
}
