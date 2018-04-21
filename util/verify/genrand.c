#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int buf[256];

int main(int argc, char **argv)
{
    int i, j;
    FILE *outfile = fopen("rand.obj", "w");
    if (argc >= 2) srand(atoi(argv[1]));
    for (i = 0; i < 1024*1024; i += 1024)
    {
        for (j = 0; j < 256; j++) buf[j] = rand();
        fwrite(buf, 1, 1024, outfile);
    }
    fclose(outfile);
    return 0;
}
