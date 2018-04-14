#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
        if (type == 'E')
        {
            printf("%c %8.8x\n", type, value);
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
        printf("%c %8.8x %s\n", type, value, buffer);
    }

    return 0;
}
