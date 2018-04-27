#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_NAME_LEN 30
#define MAX_OBJECTS 1000
#define MAX_SYMBOLS 2000
#define PIC_ADDR    0x140 // Default PIC table address

int FindGlobalLimits(char *str, int type, int first, int last);

int addr = 0;
int debugflag = 0;
int start_addr = 0;

char symtype[MAX_SYMBOLS];
int symvalue[MAX_SYMBOLS];
int symoffset[MAX_SYMBOLS];
char *symname[MAX_SYMBOLS];
int numsym = 0;
char bigbuf[MAX_SYMBOLS*32];
char *bufptr = bigbuf;
int objnum = 0;
int varcount = 0;
int pictableaddr = PIC_ADDR;
int picflag = 0;
int verbose = 0;
int objstart[MAX_OBJECTS+1];
char objname[MAX_OBJECTS][MAX_NAME_LEN];

int mem[100000];

void usage(void)
{
    printf("usage: p2link\n");
    printf("         [ -v ]       enable verbose mode\n");
    printf("         [ -d ]       enable debug mode\n");
    printf("         [ -o file ]  output file name (default a.out)\n");
    printf("         [ -s addr ]  set starting address (default 0)\n");
    printf("         files        one or more object and library files\n");
    exit(1);
}

FILE *OpenFile(char *fname, char *mode)
{
    FILE *iofile = fopen(fname, mode);

    if (!iofile)
    {
        printf("Couldn't open %s\n", fname);
        exit(1);
    }

    return iofile;
}

int read_header(FILE *infile, char *objectname)
{
    int addr0;
    char buffer[8];
    unsigned char len;
    int num = fread(buffer, 1, 8, infile);

    if (num == 0) return -1;

    if (num != 8 || strncmp(buffer, "P2OBJECT", 8))
    {
        printf("Invalid P2 object file\n");
        return -1;
    }
    fread(&len, 1, 1, infile);
    if (len > MAX_NAME_LEN)
    {
        fread(objectname, 1, MAX_NAME_LEN, infile);
        objectname[MAX_NAME_LEN-1] = 0;
        printf("ERROR: Object name is too long - %s\n", objectname);
        exit(1);
    }
    else
        fread(objectname, 1, len, infile);
    fread(&addr0, 1, 4, infile);
    if (debugflag) printf("Linking %s\n", objectname);
    return addr0;
}

void ComputeSymbolOffsets(int first, int last, int offset)
{
    int i, index, value1, addr, offset1;

    for (i = first; i < last; i++)
    {
        if (symtype[i] == 'W' || symtype[i] == 'X' || symtype[i] == 'R')
        {
            addr = symvalue[i];
            value1 = mem[addr>>2];
            index = FindGlobalLimits(symname[i], 'V', first, last);
            if (index < 0)
            {
                printf("Couldn't find %s\n", symname[i]);
                continue;
            }
            if (symtype[i] == 'W')
            {
                value1 = (value1 & 0x7fffff) << 9;
                value1 |= mem[(addr>>2)+1] & 0x1ff;
            }
            else if (symtype[i] == 'X')
            {
                value1 = (value1 & 0x7fffff) << 9;
                value1 |= (mem[(addr>>2)+1] >> 9) & 0x1ff;
            }
            offset1 = value1 - (symvalue[index] - offset);
            if (offset1)
            {
                symoffset[i] = offset1;
                if (debugflag || verbose)
                    printf("Found offset of %d for symbol %s of type %c at location %x\n", offset1, symname[i], symtype[i], addr);
            }
        }
    }
}

int ReadObject(FILE *infile)
{
    unsigned char len;
    int num, size;
    int addr0;
    int prev_numsym = numsym;

    if (objnum >= MAX_OBJECTS)
    {
        printf("ERROR: Too many objects\n");
        exit(1);
    }

    addr0 = read_header(infile, objname[objnum]);
    objstart[objnum] = numsym;
    if (addr0 < 0) return 0;

    while (1)
    {
        if (numsym > MAX_SYMBOLS)
        {
            printf("ERROR: Too many symbols\n");
            exit(1);
        }
        if (fread(&symtype[numsym], 1, 1, infile) != 1) return 0;
        if (symtype[numsym] == 'E')
        {
            fread(&size, 1, 4, infile);
            break;
        }
        fread(&symvalue[numsym], 1, 4, infile);
        if (addr != start_addr)
            symvalue[numsym] += addr - 0x400;
        else
            symvalue[numsym] += addr;
        fread(&len, 1, 1, infile);
        fread(bufptr, 1, len, infile);
        symname[numsym] = bufptr;
        bufptr += len;
        if (debugflag)
            printf("%d: %c %8.8x %s\n", numsym, symtype[numsym], symvalue[numsym], symname[numsym]);
        if (addr == start_addr && symtype[numsym] == 'P' && !strcmp(symname[numsym], "pictable"))
        {
            if (debugflag)
                printf("Setting pictableaddr = %x\n", symvalue[numsym]);
            pictableaddr = symvalue[numsym];
        }
        numsym++;
    }
    objstart[objnum+1] = numsym;

    if (addr != start_addr)
    {
        if (addr0 == 0)
        {
            fread(&mem[addr>>2], 1, 0x400, infile);
        }
        else if (addr0 != 0x400)
        {
            printf("ERROR: Object must start at address 0 or 0x400\n");
            exit(1);
        }
        size -= 0x400;
    }
    else if (addr0)
    {
        printf("ERROR: First object must start at address 0\n");
        exit(1);
    }
    num = fread(&mem[addr>>2], 1, size, infile);
    if (num != size)
    {
        printf("ERROR: Expected %d bytes, but only read %d bytes\n", size, num);
    }
    if (addr != start_addr) ComputeSymbolOffsets(prev_numsym, numsym, addr - 0x400);
    addr += num;
    objnum++;
    return 1;
}

int FindSymbol(char *str, int type0)
{
    int i;

    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == type0 && !strcmp(str, symname[i])) return i;
    }

    return -1;
}

int FindGlobal(char *str)
{
    int i;

    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'G' && !strcmp(str, symname[i])) return i;
    }

    return -1;
}

int FindVariable(char *str)
{
    int i;

    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'V' && !strcmp(str, symname[i])) return i;
    }

    return -1;
}

int FindGlobalLimits(char *str, int type, int first, int last)
{
    int i;

    for (i = first; i < last; i++)
    {
        if (symtype[i] == type && !strcmp(str, symname[i])) return i;
    }

    return -1;
}

int Resolve(int num)
{
    int i, j;
    int resolved = 0;
    int addr_u, addr_g, value_u, value_r;

    for (i = 0; i < num; i++)
    {
        if (symtype[i] == 'U' || symtype[i] == 'u')
        {
            if (debugflag)
                printf("Resolving %s at %8.8x\n", symname[i], symvalue[i]);
            j = FindGlobal(symname[i]);
            if (j >= 0)
            {
                if (debugflag)
                    printf("Global %s located at %8.8x\n", symname[j], symvalue[j]);
                addr_u = symvalue[i];
                addr_g = symvalue[j];
                value_u = mem[addr_u>>2];
                if (symtype[i] == 'U')
                    value_r = (value_u & ~0xfffff) | ((addr_g - addr_u - 4) & 0xfffff);
                else
                    value_r = (addr_g & 0xfffff);
                mem[addr_u>>2] = value_r;
                symtype[i] = 'R';
                resolved++;
            }
        }
    }
    return resolved;
}

void CountVariables(void)
{
    int i;

    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'V') varcount++;
    }
}

void MergeGlobalVariablesPIC(int prev_num)
{
    int i, j;

    for (i = prev_num; i < numsym; i++)
    {
        if (symtype[i] == 'V')
        {
            j = FindVariable(symname[i]);
            if (debugflag)
            {
                printf("Found variable %s at %8.8x\n", symname[i], symvalue[i]);
                printf("i = %d, j = %d\n", i, j);
            }
            if (j < 0 || j == i)
            {
                int oldval = symvalue[i];
                symvalue[i] = (((pictableaddr >> 2) + varcount++) << 20) | (oldval & 0xfffff);
                if (debugflag)
                {
                    printf("New variable\n");
                    printf("Changing %8.8x to %8.8x\n", oldval, symvalue[i]);
                }
            }
            else
            {
                if (debugflag)
                {
                    printf("Merge with entry %d at address %8.8x\n", j, symvalue[j]);
                    printf("Changing %8.8x to %8.8x\n", symvalue[i], symvalue[j]);
                }
                symvalue[i] = symvalue[j];
                symtype[i] = '-';
            }
        }
    }
}

void ModifyBits(int addr, int value, int mask, int shift);

void FixUpRef(char *ptr, int newval, int first, int last)
{
    int i, addr, offset, newval1;

    for (i = first; i < last; i++)
    {
        if (strcmp(ptr, symname[i])) continue;
        if (symtype[i] != 'W' && symtype[i] != 'X' && symtype[i] != 'R') continue;
        addr = symvalue[i];
        offset = symoffset[i];
        newval1 = newval + offset;
        if (debugflag && offset) printf("FixUpRef: offset = %d\n", offset);
        if (symtype[i] == 'W')
        {
            if (debugflag) printf("Fixing up reference at entry %d at address %8.8x\n", i, addr);
            ModifyBits(addr, newval1 >> 9, 0x7fffff, 0);
            ModifyBits(addr+4, newval1, 0x1ff, 0);
        }
        else if (symtype[i] == 'X')
        {
            if (debugflag) printf("Fixing up reference at entry %d at address %8.8x\n", i, addr);
            ModifyBits(addr, newval1 >> 9, 0x7fffff, 0);
            ModifyBits(addr+4, newval1, 0x1ff, 9);
        }
        else
        {
            int oldval = mem[(addr>>2)];
            if (debugflag) printf("Fixing up reference at entry %d at address %8.8x\n", i, addr);
            mem[addr>>2] = newval1;
            if (debugflag) printf("Changing variable ref at %8.8x from %3.3x to %3.3x\n", addr, oldval, newval1);
        }
    }
}

int MergeGlobalVariables(int prev_num)
{
    int resolved = 0;
    int i, j, k, first, last;

    for (i = prev_num; i < numsym; i++)
    {
        if (symtype[i] == 'd')
        {
            j = FindSymbol(symname[i], 'D');
            if (j < 0) j = FindSymbol(symname[i], 'd');
            if (debugflag)
            {
                printf("Found variable %s at %8.8x\n", symname[i], symvalue[i]);
                printf("i = %d, j = %d\n", i, j);
            }
            // Use address from previous object if found
            if (j >= 0 && j != i)
            {
                if (debugflag)
                {
                    printf("Use address from entry %d at address %8.8x\n", j, symvalue[j]);
                    printf("Changing %8.8x to %8.8x\n", symvalue[i], symvalue[j]);
                }
                symvalue[i] = symvalue[j];
                // Fix address in "V" list also
                j = FindGlobalLimits(symname[i], 'V', prev_num, numsym);
                if (j >= 0)
                {
                    if (debugflag) printf("Also change entry %d\n", j);
                    if (debugflag) printf("Changing %8.8x to %8.8x\n", symvalue[j], symvalue[i]);
                    symvalue[j] = symvalue[i];
                }
            }
        }
        else if (symtype[i] == 'D')
        {
            if (debugflag) printf("Found initialized global variable %s at entry %d and address %8.8x\n", symname[i], i, symvalue[i]);
            // Loop over previous objects
            for (k = 0; k < objnum-1; k++)
            {
                first = objstart[k];
                last = objstart[k+1];
                j = FindGlobalLimits(symname[i], 'd', first, last);
                if (j < 0)
                {
                    j = FindGlobalLimits(symname[i], 'D', first, last);
                    if (j >= 0) printf("WARNING: Global variable %s initialized in another object\n", symname[i]);
                }
                if (j < 0) continue;
                if (debugflag) printf("Found global variable %s at entry %d and address %8.8x\n", symname[j], j, symvalue[j]);
                if (debugflag) printf("Changing %8.8x to %8.8x\n", symvalue[j], symvalue[i]);
                FixUpRef(symname[i], symvalue[i], first, last);
                symvalue[j] = symvalue[i];
                // Fix address in "V" list also
                j = FindGlobalLimits(symname[i], 'V', first, last);
                if (j >= 0)
                {
                    if (debugflag) printf("Also change entry %d\n", j);
                    if (debugflag) printf("Changing %8.8x to %8.8x\n", symvalue[j], symvalue[i]);
                    symvalue[j] = symvalue[i];
                }
                resolved++;
            }
        }
    }
    return resolved;
}

void ModifyBits(int addr, int value, int mask, int shift)
{
    int oldval = mem[addr>>2];
    int newval = (oldval & ~(mask << shift)) | ((value & mask) << shift);
    mem[addr>>2] = newval;
    if (debugflag) printf("Changing variable ref at %8.8x from %3.3x to %3.3x\n", addr, oldval, newval);
}

void FixVariableRef(int prev_num)
{
    int i, j;

    for (i = prev_num; i < numsym; i++)
    {
        if (symtype[i] == 'W' || symtype[i] == 'X' || symtype[i] == 'R')
        {
            int newval;
            int addr = symvalue[i];
            int oldval = mem[addr>>2];
            int offset = symoffset[i];
            j = FindGlobalLimits(symname[i], 'V', prev_num, numsym);
            if (debugflag)
            {
                printf("Found variable %s at %8.8x\n", symname[i], symvalue[i]);
                printf("i = %d, j = %d\n", i, j);
            }
            if (j < 0)
            {
                if (debugflag)
                    printf("ERROR: Couldn't find variable %s\n", symname[i]);
                continue;
            }
            newval = symvalue[j] + offset;
            if (picflag)
            {
                int oldval = mem[addr>>2] & 0x1ff;
                int newval = (symvalue[j] >> 20) & 0x1ff;
                if (debugflag)
                    printf("Changing variable ref at %8.8x from %3.3x to %3.3x\n", addr, oldval, newval);
                oldval = mem[addr>>2];
                newval = (oldval & ~0x1ff) | newval;
                if (debugflag)
                    printf("Changing %8.8x to %8.8x\n", oldval, newval);
                mem[addr>>2] = newval;
            }
            else if (symtype[i] == 'W')
            {
                ModifyBits(addr, newval >> 9, 0x7fffff, 0);
                ModifyBits(addr+4, newval, 0x1ff, 0);
            }
            else if (symtype[i] == 'X')
            {
                ModifyBits(addr, newval >> 9, 0x7fffff, 0);
                ModifyBits(addr+4, newval, 0x1ff, 9);
            }
            else if (symtype[i] == 'R')
            {
                mem[addr>>2] = newval;
                if (debugflag)
                    printf("Changing variable ref at %8.8x from %3.3x to %3.3x\n", addr, oldval, newval);
            }
        }
    }
}

void AddPicTable(void)
{
    int i;

    if (debugflag) printf("AddPicTable: Setting PIC table address to %8.8x at %8.8x\n", addr, pictableaddr);
    mem[pictableaddr>>2] = addr;
        
    if (debugflag) printf("Number of variables = %d\n", varcount);
    mem[addr>>2] = varcount;
    addr += 4;
    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'V')
        {
            if (debugflag)
                printf("%8.8x %s\n", symvalue[i], symname[i]);
            mem[addr>>2] = symvalue[i] & 0xfffff;
            addr += 4;
        }
    }
}

void AddAdjTable(void)
{
    int i;
    int num = 0;
    int adjust_addr = addr;
    int adjtableaddr = pictableaddr - 4;

    if (debugflag) printf("AddAdjTable: Setting ADJ table address to %8.8x at %8.8x\n", addr, adjtableaddr);
    mem[adjtableaddr>>2] = addr;
    addr += 4;
    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'J')
        {
            if (debugflag)
                printf("Adding %8.8x %s to adjustment table\n", symvalue[i] & 0xfffff, symname[i]);
            mem[addr>>2] = symvalue[i] & 0xfffff;
            addr += 4;
            num++;
        }
        else if (symtype[i] == 'V')
        {
            if (!strcmp(symname[i], "heapaddr") || !strcmp(symname[i], "heapaddrlast"))
            {
                if (debugflag)
                    printf("Adding %8.8x %s to adjustment table\n", symvalue[i] & 0xfffff, symname[i]);
                mem[addr>>2] = symvalue[i] & 0xfffff;
                addr += 4;
                num++;
            }
        }
    }
        
    if (debugflag) printf("Number of addresses = %d\n", num);
    mem[adjust_addr>>2] = num;
}

void ReadFile(FILE *infile, int libflag)
{
    int vars_resolved = 0;
    int prev_addr = addr;
    int prev_numsym = numsym;
    int prev_varcount = varcount;

    while (ReadObject(infile))
    {
        if (objnum > 1)
        {
            vars_resolved = MergeGlobalVariables(prev_numsym);
            FixVariableRef(prev_numsym);
        }
        else
            CountVariables();
        if (objnum > 1 && !Resolve(prev_numsym) && !vars_resolved && libflag)
        {
            addr = prev_addr;
            numsym = prev_numsym;
            varcount = prev_varcount;
            objnum--;
        }
        else
        {
            prev_addr = addr;
            prev_numsym = numsym;
            prev_varcount = varcount;
        }
    }
}

int is_lib(char *str)
{
    int len = strlen(str);
    if (len < 2) return 0;
    if (str[len-1] != 'a') return 0;
    if (str[len-2] != '.') return 0;
    return 1;
}

void InitHeapAddress(void)
{
    int i, hub_addr;
    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'V')
        {
            if (!strcmp(symname[i], "_heapaddr") || !strcmp(symname[i], "_heapaddrlast"))
            {
                hub_addr = symvalue[i] & 0xfffff;
                if (verbose) printf("Setting value of %s at location %x to %x\n", symname[i], hub_addr, addr);
                mem[hub_addr>>2] = addr;
            }
        }
    }
}

int main(int argc, char **argv)
{
    int i;
    char buffer[256];
    char outfname[100];
    int unresolved = 0;
    FILE *infile, *outfile;

    memset(symoffset, 0, MAX_SYMBOLS*4);
    strcpy(outfname, "a.out");
    for (i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (!strcmp(argv[i], "-d")) debugflag = 1;
            else if (!strcmp(argv[i], "-v")) verbose = 1;
            else if (!strcmp(argv[i], "-PIC")) picflag = 1;
            else if (argv[i][1] == 'o')
            {
                if (argv[i][2])
                    strcpy(outfname, &argv[i][2]);
                else if (++i >= argc)
                    usage();
                else
                    strcpy(outfname, argv[i]);
            }
            else if (argv[i][1] == 's')
            {
                if (argv[i][2])
                    sscanf(&argv[i][2], "%x", &start_addr);
                else if (++i >= argc)
                    usage();
                else
                    sscanf(argv[i], "%x", &start_addr);
                addr = start_addr;
            }
            else usage();
        }
        else
        {
            infile = OpenFile(argv[i], "rb");
            ReadFile(infile, is_lib(argv[i]));
            fclose(infile);
        }
    }

    if (addr == start_addr) usage();

    Resolve(numsym);
    // Check if any remaining unresolves
    for (i = 0; i < numsym; i++)
    {
        if (symtype[i] == 'U')
        {
            unresolved++;
            printf("%s is unresolved\n", symname[i]);
        }
    }

    if (unresolved)
    {
        printf("%d symbol(s) are unresolved\n", unresolved);
        exit(1);
    }

    if (picflag) AddPicTable();

    //AddAdjTable();

    InitHeapAddress();

    outfile = OpenFile(outfname, "wb");
    fwrite(&mem[start_addr>>2], 1, addr - start_addr, outfile);

    if (debugflag)
    {
        int j;
        printf("Object Dump\n");
        for (i = 1; i < objnum; i++)
        {
            printf("Object %d: %s\n", i, objname[i]);
            for (j = objstart[i]; j < objstart[i+1]; j++)
            {
                if (symoffset[j] == 0)
                    printf("%d: %c %8.8x %s\n", j, symtype[j], symvalue[j], symname[j]);
                else if (symoffset[j] > 0)
                    printf("%d: %c %8.8x %s+%d\n", j, symtype[j], symvalue[j], symname[j], symoffset[j]);
                else
                    printf("%d: %c %8.8x %s-%d\n", j, symtype[j], symvalue[j], symname[j], -symoffset[j]);
            }
        }
    }

    return 0;
}
