#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <dirent.h>
#include <sys/stat.h>
#include "fsrw.h"

char *getsn(char *, int num);

#define EOK         0
#define ENOENT      1
#define EEXIST      2
#define EINVAL      3
#define EMFILE      4
#define EIO         5
#define ENOTDIR     6
#define EISDIR      7
#define EROFS       8
#define ENOTEMPTY   9
#define ENOSPC     10
#define ENOMEM     11

int errno;
FILE __files[10] = {0};
static char dirbuf[16];
static char currentwd[100];

void sd_mount(int DO, int CLK, int DI, int CS)
{
    int i;
    __files[0]._flag = 0x100000;
    __files[1]._flag = 0x100000;
    __files[2]._flag = 0x100000;
    for (i = 3; i < 10; i++) __files[i]._flag = 0;
    strcpy(currentwd, "/");
    mount_explicit(DO, CLK, DI, CS);
}

void sd_unmount(void)
{
    unmount();
}

FILE *allocfile(int size)
{
    int i;

    for (i = 0; i < 10; i++)
    {
        if (!__files[i]._flag) break;
    }
    if (i == 10) return 0;
    __files[i]._flag = (int)malloc(size);
    if (__files[i]._flag) return &__files[i];
    return 0;
}

void freefile(FILE *fd)
{
    if (fd && fd->_flag)
    {
        if (!(fd->_flag & 0xfff00000)) free((void *)fd->_flag);
        fd->_flag = 0;
    }
}

FILE *fopen(const char *fname, const char *mode)
{
    FILE *fd;
    int *handle;
    if (*mode != 'r' && *mode != 'w' && *mode != 'a')
    {
        errno = EINVAL;
        return 0;
    }
    fd = allocfile(44 + 512);
    if (!fd)
    {
        errno = ENOMEM;
        return 0;
    }
    handle = (int *)fd->_flag;
    memset(handle, 0, 40);
    handle[10] = (int)&handle[11];
    loadhandle(handle);
    errno = popen((char *)fname, *mode);
    if (errno)
    {
        errno = ENOENT;
        loadhandle0();
        freefile(fd);
        return 0;
    }
    return fd;
}

int fclose(FILE *fd)
{
    if (!fd) return -1;
    loadhandle((int *)fd->_flag);
    pclose();
    loadhandle0();
    freefile(fd);
    return 0;
}

size_t fread(void *ptr0, size_t size, size_t num, FILE *fd)
{
    int numread;
    char *ptr = ptr0;
    if (fd == 0) return 0;
    size *= num;
    if (fd->_flag & 0xfff00000)
    {
        numread = size;
        while (size--) *ptr++ = getchar();
    }
    else
    {
        loadhandle((int *)fd->_flag);
        numread = pread(ptr, size);
    }
    if (numread < 0)
    {
        errno = numread;
        numread = 0;
    }
    return (size_t)numread;
}

size_t fwrite(const void *ptr0, size_t size, size_t num, FILE *fd)
{
    char *ptr = (char *)ptr0;
    size *= num;
    if (fd->_flag & 0xfff00000)
    {
        while (size--) putchar(*ptr++);
    }
    else
    {
        loadhandle((int *)fd->_flag);
        errno = pwrite(ptr, size);
    }
    return 0;
}

int remove(const char *fname)
{
    loadhandle0();
    errno = popen((char *)fname, 'd');
    return 0;
}

int fgetc(FILE *fd)
{
    int val;
    if (fd->_flag & 0xfff00000) return getchar();
    loadhandle((int *)fd->_flag);
    val = pgetc();
    return val;
}

int getc(FILE *fd)
{
    return fgetc(fd);
}

int fputc(int val, FILE *fd)
{
    if (fd->_flag & 0xfff00000)
        putchar(val);
    else
    {
        loadhandle((int *)fd->_flag);
        pputc(val);
    }
    return val;
}

int putc(int val, FILE *fd)
{
    return fputc(val, fd);
}

int chdir(const char *path)
{
    int err;
    if (!(err = pchdir((char *)path)))
    {
        if (*path == '/')
            strcpy(currentwd, path);
        else
        {
            if (strcmp(currentwd, "/"))
                strcat(currentwd, "/");
            strcat(currentwd, path);
        }
        return 0;
    }
    if (err == -1)
        errno = ENOENT;
    else if (err == -2)
        errno = ENOTDIR;
    else
        errno = EIO;
    if (pchdir(currentwd)) strcpy(currentwd, "/");
    return -1;
}

static char *get_errstr(void)
{
    char *ptr;

    switch (errno)
    {
        case EOK:
            ptr = "No error";
            break;
        case ENOENT:
            ptr = "No such file or directory";
            break;
        case EEXIST:
            ptr = "File exists";
            break;
        case EINVAL:
            ptr = "Invalid argument";
            break;
        case EMFILE:
            ptr = "Too many open files";
            break;
        case EIO:
            ptr = "I/O error";
            break;
        case ENOTDIR:
            ptr = "Not a directory";
            break;
        case EISDIR:
            ptr = "Is a directory";
            break;
        case EROFS:
            ptr = "Read only file system";
            break;
        case ENOTEMPTY:
            ptr = "Directory not empty";
            break;
        case ENOSPC:
            ptr = "No space on device";
            break;
        case ENOMEM:
            ptr = "Not enough memory";
            break;
        default:
            ptr = "Unknown error";
            break;
    }

    return ptr;
}

void perror(const char *str)
{
    if (str) printf("%s: ", str);
    printf("%s\n", get_errstr());
}

char *getcwd(char *ptr, int size)
{
    strncpy(ptr, currentwd, size);
    return ptr;
}

int fputs(const char *str, FILE *fd)
{
    if (fd->_flag & 0xfff00000)
        puts(str);
    else
    {
        loadhandle((int *)fd->_flag);
        pputs((char *)str);
    }
    return 0;
}

char *fgets(char *str, int num, FILE *fd)
{
    if (fd->_flag & 0xfff00000)
        getsn(str, num);
    else
        hgets((int *)fd->_flag, str, num);
    return str;
}

int fflush(FILE *fd)
{
    if (!fd) return -1;
    if (fd->_flag & 0xfff00000) return 0;
    loadhandle((int *)fd->_flag);
    pflush();
    return 0;
}

DIR *opendir(const char *path)
{
    FILE *fd;
    int *handle;
    if (path[0] && strcmp(path, ".") && strcmp(path, "/") && strcmp(path,"./"))
        return 0;
    fd = allocfile(44 + 512);
    if (!fd) return 0;
    handle = (int *)fd->_flag;
    memset(handle, 0, 40);
    handle[10] = (int)&handle[11];
    loadhandle(handle);
    errno = popendir();
    if (errno)
    {
        loadhandle0();
        freefile(fd);
        return 0;
    }
    return (DIR *)fd;
}

struct dirent *readdir(DIR *dirt)
{
    FILE *fd = (FILE *)dirt;
    loadhandle((int *)fd->_flag);
    if (!nextfile(dirbuf))
        return (struct dirent *)dirbuf;
    return 0;
}

int closedir(DIR *dirt)
{
    return fclose((FILE *)dirt);
}

int fseek(FILE *fd, long int offset, int origin)
{
    if (!fd || origin < 0 || origin > 2) return -1;

    loadhandle((int *)fd->_flag);
    if (origin == 1)
        offset += tell();
    else if (origin == 2)
        offset += get_filesize();
    return seek(offset);
}

long int ftell(FILE *fd)
{
    loadhandle((int *)fd->_flag);
    return tell();
}

int stat(const char *fname, struct stat *buf)
{
    int retval;
    int filestat[2];
    loadhandle0();
    retval = popen((char *)fname, 'r');
    if (retval) return -1;
    pstat(filestat);
    buf->st_size = filestat[1];
    if (filestat[0] & 0x10)
        buf->st_mode = S_IFDIR;
    else
        buf->st_mode = 0;
    pclose();
    return 0;
}

int mkdir(const char *path, int mode)
{
    int err = pmkdir((char *)path);
    if (err)
        errno = EEXIST;
    return err;
}

void rmdir(void)
{
}
