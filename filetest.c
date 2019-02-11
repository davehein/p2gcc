//############################################################################
//# This program is used to test the basic functions of the SD file system.
//# It implements simple versions of the cat, rm, ls, echo, cd, pwd and mkdir
//# commands plus the <, > and >> file redirection operators.  The program
//# starts up the file driver and then prompts for a command.
//#
//# Written by Dave Hein
//# Copyright (c) 2011 - 2017 Parallax, Inc.
//# MIT Licensed
//############################################################################
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <propeller.h>
#include <sys/stat.h>
#include <dirent.h>

FILE __files[]; // Needed for stdin and stdout to link properly
FILE *stdinfile;
FILE *stdoutfile;

// Print help information
void Help()
{
    printf("Commands are help, cat, rm, ls, ll, echo, cd, pwd, mkdir and exit\n");
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
    ptr = (char *)getcwd(buffer, 64);
    if (!ptr)
        perror(0);
    else
        fprintf(stdoutfile, "%s\n", ptr);
}

void MakeDir(int argc, char **argv)
{
    int i;

    for (i = 1; i < argc; i++)
    {
        if (mkdir(argv[i], 0))
            perror(argv[i]);
    }
}

// This routine implements the file cat function
void Cat(int argc, char **argv)
{
    int i;
    int num;
    FILE *infile;
    char buffer[41];

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
            {
                fwrite(buffer, 1, num, stdoutfile);
            }
        }
        if (i)
            fclose(infile);
    }
    fflush(stdout);
}

// This routine deletes the files specified by the command line arguments
void RemoveFile(int argc, char **argv)
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
    DIR *dirp;
    struct dirent *entry;
    //int filestat[2];
    int attribute;
    struct stat statbuf;
    char longpath[100];
    int len;

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
            ptr = entry->name;
            for (i = 0; i < 13; i++)
            {
                fname[i] = tolower(*ptr);
                if (*ptr++ = 0) break;
            }
            if (longflag)
            {
                strcpy(longpath, path);
                len = strlen(longpath);
                if (len && longpath[len-1] != '/')
                    strcat(longpath, "/");
                strcat(longpath, fname);
                stat(longpath, &statbuf);
                filesize = statbuf.st_size;
                attribute = statbuf.st_mode;
                strcpy(drwx, "-rw-");
#if 0
                if (attribute & 1)
                    drwx[2] = '-';
                if (attribute & 0x20)
                    drwx[3] = 'x';
#endif
                if (attribute & S_IFDIR)
                {
                    drwx[0] = 'd';
                    drwx[3] = 'x';
                }
                fprintf(stdoutfile, "%s %8d %s\n", drwx, filesize, fname);
            }
            else if (++column == 5)
            {
#if 0
                for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
                fprintf(stdoutfile, "%s\n", fname);
#else
                for (i = prevlen; i < 14; i++) printf(" ");
                printf("%s\n", fname);
#endif
                column = 0;
                prevlen = 14;
            }
            else
            {
#if 0
                for (i = prevlen; i < 14; i++) fprintf(stdoutfile, " ");
                prevlen = strlen(fname);
                fprintf(stdoutfile, "%s", fname);
#else
                for (i = prevlen; i < 14; i++) printf(" ");
                prevlen = strlen(fname);
                printf("%s", fname);
#endif
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

    waitcnt(CNT+12000000);
    //sd_mount(59, 60, 58, 61);
    sd_mount(58, 61, 59, 60);

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
            RemoveFile(num, tokens);
        else if (!strcmp(tokens[0], "echo"))
            Echo(num, tokens);
        else if (!strcmp(tokens[0], "cd"))
            Cd(num, tokens);
        else if (!strcmp(tokens[0], "pwd"))
            Pwd(num, tokens);
        else if (!strcmp(tokens[0], "mkdir"))
            MakeDir(num, tokens);
        else if (!strcmp(tokens[0], "exit"))
        {
            printf("Exiting\n");
            sd_unmount();
            exit(0);
        }
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

