/*
 *
 * Copyright (c) 2018 - 2019 by Dave Hein
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
    {OTYPE_WEAK_LABEL,   "Weak Label    "},
    {OTYPE_END_OF_CODE,  "End of code   "},
    {0,                  "Invalid type  "}};

ObjectTypeT objsects[] = {
    {SECTION_NULL,       "Null   "},
    {SECTION_TEXT,       "Text   "},
    {SECTION_DATA,       "Data   "},
    {SECTION_BSS,        "BSS    "},
    {-1,                 "Invalid"}};

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

char *GetObjectSection(int objsect)
{
    ObjectTypeT *os = objsects;

    while (os->type != -1)
    {
        if (os->type == objsect) break;
        os++;
    }
    return os->descript;
}

void usage(void)
{
    printf("p2dumpobj - a utility to dump propeller 2 object files - version 0.003, 2019-1-11\n");
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
    unsigned char type, objsect, len;
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
        fread(&objsect, 1, 1, infile);
        fread(&value, 1, 4, infile);
        if (type == OTYPE_END_OF_CODE)
        {
            printf("%s %s %8.8x\n", GetDescription(type), GetObjectSection(objsect), value);
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
        printf("%s %s %8.8x %s\n", GetDescription(type), GetObjectSection(objsect), value, buffer);
    }

    return 0;
}
