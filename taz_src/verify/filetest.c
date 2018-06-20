//############################################################################
//# This program is used to test the basic functions of the SD file system.
//# It implements simple versions of the cat, rm, ls, echo, cd, pwd, mkdir and
//# rmdir commands plus the <, > and >> file redirection operators.
//# The program starts up the file driver and then prompts for a command.
//#
//# Written by Dave Hein
//# Copyright (c) 2011 Parallax, Inc.
//# MIT Licensed
//############################################################################






int *stdin;
int *stdout;
int *stdinfile;
int *stdoutfile;

// Print help information
void Help()
{
    printf("Commands are help, cat, rm, ls, ll, echo, cd, pwd, mkdir, run and exit\n");
}

void Run(int argc, char **argv)
{
    int *infile;
    char *ptr;
    int filestat[2];
    int *proctable;
    int val, cognum;
    int heap;
    char save_cwd[80];

    proctable = 0x7ff80;

    if (argc != 2)
    {
        printf("usage: run file\n");
        return;
    }

    infile = fopen(argv[1], "r");
    if (!infile)
    {
        printf("Couldn't open %s\n", argv[1]);
        return;
    }
    fstat(infile, filestat);
    for (heap = 450000; heap >= 50000; heap -= 50000)
    {
        ptr = malloc(filestat[1] + heap);
        if (ptr) break;
    }
    if (!ptr)
    {
        printf("Couldn't allocate memory\n");
        fclose(infile);
        return;
    }
    //printf("Allocated %d bytes of memory\n", filestat[1] + heap);
    val = fread(ptr, 1, 1000000, infile);
    fclose(infile);
    //printf("Read %d bytes from %s\n", val, argv[1]);
    getcwd(save_cwd, 80);
    sd_unmount();
    dira = 0;
    dirb = 0;
    waitx(5000000);
    cognum = CogInit(16, ptr, ptr + filestat[1] + heap);
    if (cognum & ~15)
    {
        dirb &= ~0x40000000;
        //printf("CogInit returned %d\n", cognum);
        free(ptr);
        return;
    }
    proctable[cognum] = 1;
    //dirb &= ~0x40000000;
    while (proctable[cognum])
    {
        if (!(inb & 0x80000000))
        {
            val = getch();
            if (val == 3)
            {
                CogStop(cognum);
                dirb |= 0x40000000;
                printf("\n^C");
                break;
            }
        }
    }
    dirb |= 0x40000000;
    free(ptr);
    //printf("CogInit returned %d\n", cognum);
    sd_mount(0, 1, 2, 3);
    chdir(save_cwd);
}

void CogStop(int cognum)
{
    inline("cogstop reg0");
}

void CogInit(int cognum, int addr, int parm)
{
    inline("setq reg2");
    inline("coginit reg0, reg1 wc");
}

void Cd(int argc, char **argv)
{
    if (argc < 2) return;

    if (chdir(argv[1]))
        perror(argv[1]);
}

void Pwd(int argc, char **argv)
{
    char buffer[64];
    char *ptr;
    ptr = getcwd(buffer, 64);
    if (!ptr)
        perror(0);
    else
        fprintf(stdoutfile, "%s\n", ptr);
}

void Mkdir(int argc, char **argv)
{
    int i;

    for (i = 1; i < argc; i++)
    {
        if (mkdir(argv[i], 0))
            perror(argv[i]);
    }
}

void Rmdir(int argc, char **argv)
{
    int i;

    for (i = 1; i < argc; i++)
    {
        if (rmdir(argv[i]))
            perror(argv[i]);
    }
}

// This routine implements the file cat function
void Cat(int argc, char **argv)
{
    int i;
    int num;
    void *infile;
    char buffer[40];

    for (i = 0; i < argc; i++)
    {
        if (i == 0)
        {
            if (argc == 1 || stdinfile != stdin)
                infile = stdinfile;
            else
                continue;
        }
        else
        {
            infile = fopen(argv[i], "r");
            if (infile == 0)
            {
                perror(argv[i]);
                continue;
            }
        }
        if (infile == stdin)
        {
            while (gets(buffer))
            {
                if (buffer[0] == 4) break;
                fprintf(stdoutfile, "%s\n", buffer);
            }
        }
        else
        {
            while ((num = fread(buffer, 1, 40, infile)))
                fwrite(buffer, 1, num, stdoutfile);
        }
        if (i)
            fclose(infile);
    }
    fflush(stdout);
}

// This routine deletes the files specified by the command line arguments
void Remove(int argc, char **argv)
{
    int i;

    for (i = 1; i < argc; i++)
    {
        if (remove(argv[i]))
            perror(argv[i]);
    }
}

// This routine echos the command line arguments
void Echo(int argc, char **argv)
{
    int i;
    for (i = 1; i < argc; i++)
    {
        if (i != argc - 1)
            fprintf(stdoutfile, "%s ", argv[i]);
        else
            fprintf(stdoutfile, "%s\n", argv[i]);
    }
}

// This routine lists the root directory or any subdirectories specified
// in the command line arguments.  If the "-l" option is specified, it
// will print the file attributes and size.  Otherwise, it will just
// print the file names.
void List(int argc, char **argv)
{
    int i, j;
    char *ptr;
    char fname[13];
    int count;
    unsigned int filesize;
    unsigned int longflag;
    char *path;
    char drwx[5];
    int column;
    int prevlen;
    int *dirp;
    int *entry;
    int filestat[2];
    int attribute;

    count = 0;
    longflag = 0;

    // Check flags
    for (j = 1; j < argc; j++)
    {
        if (*(argv[j]) == '-')
        {
            if (!strcmp(argv[j], "-l"))
                longflag = 1;
            else
                printf("Unknown option '%s'\n", argv[j]);
        }
        else
            count++;
    }

    // List directories
    for (j = 1; j < argc || count == 0; j++)
    {
        if (count == 0)
        {
            count--;
            path = "./";
        }
        else if (*(argv[j]) == '-')
            continue;
        else
            path = argv[j];

        if (count >= 2)
            fprintf(stdoutfile, "\n%s:\n", path);

        dirp = opendir(path);

        if (!dirp)
        {
            perror(path);
            continue;
        }

        column = 0;
        prevlen = 14;
        while (entry = readdir(dirp))
        {
            ptr = entry;
            for (i = 0; i < 13; i++)
            {
                fname[i] = tolower(*ptr);
                if (*ptr++ = 0) break;
            }
            if (longflag)
            {
                stat(fname, filestat);
                filesize = filestat[1];
                attribute = filestat[0];
                strcpy(drwx, "-rw-");
                if (attribute & 1)
                    drwx[2] = '-';
                if (attribute & 0x20)
                    drwx[3] = 'x';
                if (attribute & 0x10)
                {
                    drwx[0] = 'd';
                    drwx[3] = 'x';
                }
                fprintf(stdoutfile, "%s %8d %s\n", drwx, filesize, fname);
            }
            else if (++column == 5)
            {
                for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
                fprintf(stdoutfile, "%s\n", fname);
                column = 0;
                prevlen = 14;
            }
            else
            {
                for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
                prevlen = strlen(fname);
                fprintf(stdoutfile, "%s", fname);
            }
        }
        closedir(dirp);
        if (!longflag && column)
            fprintf(stdoutfile, "\n");
    }
}

// This routine returns a pointer to the first character that doesn't
// match val.
char *SkipChar(char *ptr, int val)
{
    while (*ptr)
    {
        if (*ptr != val) break;
        ptr++;
    }
    return ptr;
}

// This routine returns a pointer to the first character that matches val.
char *FindChar(char *ptr, int val)
{
    while (*ptr)
    {
        if (*ptr == val) break;
        ptr++;
    }
    return ptr;
}

// This routine extracts tokens from a string that are separated by one or
// more spaces.  It returns the number of tokens found.
int tokenize(char *ptr, char **tokens)
{
    int num;
    num = 0;

    while (*ptr)
    {
        ptr = SkipChar(ptr, ' ');
        if (*ptr == 0) break;
        if (ptr[0] == '>')
        {
            ptr++;
            if (ptr[0] == '>')
            {
                tokens[num++] = ">>";
                ptr++;
            }
            else
                tokens[num++] = ">";
            continue;
        }
        if (ptr[0] == '<')
        {
            ptr++;
            tokens[num++] = "<";
            continue;
        }
        tokens[num++] = ptr;
        ptr = FindChar(ptr, ' ');
        if (*ptr) *ptr++ = 0;
    }
    return num;
}

// This routine searches the list of tokens for the redirection operators
// and opens the files for input, output or append depending on the 
// operator.
int CheckRedirection(char **tokens, int num)
{
    int i, j;

    for (i = 0; i < num-1; i++)
    {
        if (!strcmp(tokens[i], ">"))
        {
            stdoutfile = fopen(tokens[i+1], "w");
            if (!stdoutfile)
            {
                perror(tokens[i+1]);
                stdoutfile = stdout;
                return 0;
            }
        }
        else if (!strcmp(tokens[i], ">>"))
        {
            stdoutfile = fopen(tokens[i+1], "a");
            if (!stdoutfile)
            {
                perror(tokens[i+1]);
                stdoutfile = stdout;
                return 0;
            }
        }
        else if (!strcmp(tokens[i], "<"))
        {
            stdinfile = fopen(tokens[i+1], "r");
            if (!stdinfile)
            {
                perror(tokens[i+1]);
                stdinfile = stdin;
                return 0;
            }
        }
        else
            continue;
        for (j = i + 2; j < num; j++) tokens[j-2] = tokens[j];
        i--;
        num -= 2;
    }
    return num;
}

// This routine closes files that were open for redirection
void CloseRedirection()
{
    if (stdinfile != stdin)
    {
        fclose(stdinfile);
        stdinfile = stdin;
    }
    if (stdoutfile != stdout)
    {
        fclose(stdoutfile);
        stdoutfile = stdout;
    }
}

int getdec(char *ptr)
{
    int val;
    val = 0;
    while (*ptr) val = (val * 10) + *ptr++ - '0';
    return val;
}

// The program starts the file system.  It then loops reading commands
// and calling the appropriate routine to process it.
int main(int argc, char **argv)
{
    int i;
    int num;
    char *tokens[20];
    char buffer[80];

    sd_mount(0, 1, 2, 3);

    stdinfile = stdin;
    stdoutfile = stdout;

    printf("\n");
    Help();

    while (1)
    {
        printf("\n> ");
        fflush(stdout);
        gets(buffer);
        num = tokenize(buffer, tokens);
        num = CheckRedirection(tokens, num);
        if (num == 0) continue;
        if (!strcmp(tokens[0], "help"))
            Help();
        else if (!strcmp(tokens[0], "cat"))
            Cat(num, tokens);
        else if (!strcmp(tokens[0], "ls"))
            List(num, tokens);
        else if (!strcmp(tokens[0], "ll"))
        {
            tokens[num++] = "-l";
            List(num, tokens);
        }
        else if (!strcmp(tokens[0], "rm"))
            Remove(num, tokens);
        else if (!strcmp(tokens[0], "echo"))
            Echo(num, tokens);
        else if (!strcmp(tokens[0], "cd"))
            Cd(num, tokens);
        else if (!strcmp(tokens[0], "pwd"))
            Pwd(num, tokens);
        else if (!strcmp(tokens[0], "mkdir"))
            Mkdir(num, tokens);
        else if (!strcmp(tokens[0], "rmdir"))
            Rmdir(num, tokens);
        else if (!strcmp(tokens[0], "exit"))
            exit(0);
        else if (!strcmp(tokens[0], "run"))
            Run(num, tokens);
        else
        {
            printf("Invalid command\n");
            Help();
        }
        CloseRedirection();
    }
}
//+--------------------------------------------------------------------
//|  TERMS OF USE: MIT License
//+--------------------------------------------------------------------
//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files
//(the "Software"), to deal in the Software without restriction,
//including without limitation the rights to use, copy, modify, merge,
//publish, distribute, sublicense, and/or sell copies of the Software,
//and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//+------------------------------------------------------------------

