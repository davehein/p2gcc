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
#define ENXIO      12

void resolve_path(const char *fname, char *path);
static char *SplitPathFile(char *pathstr);
static char *SplitPathFileCd(char *fname, char *pathstr);

int errno;
//FILE __files[10] = {{0}};
static char dirbuf[16];
static char currentwd[100];
static int mounted = 0;

void sd_mount(int DO, int CLK, int DI, int CS)
{
#if 0
    int i;
    __files[0]._flag = 0x100000;
    __files[1]._flag = 0x100000;
    __files[2]._flag = 0x100000;
    for (i = 3; i < 10; i++) __files[i]._flag = 0;
#endif
    strcpy(currentwd, "/");
    if (!mount_explicit(DO, CLK, DI, CS))
      mounted = 1;
}

void sd_unmount(void)
{
    unmount();
    mounted = 0;
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
    char path[100];
    char *fname1;
    char dirpath[100];

    if (!mounted)
    {
        errno = ENXIO;
        return 0;
    }
    if (*mode != 'r' && *mode != 'w' && *mode != 'a')
    {
        errno = EINVAL;
        return 0;
    }
    resolve_path(fname, path);
    fname1 = SplitPathFileCd(path, dirpath);
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
    errno = popen(fname1, *mode);
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
    char path[100];
    char dirpath[100];
    char *fname1;

    if (!mounted)
    {
        errno = ENXIO;
        return 1;
    }
    resolve_path(fname, path);
    fname1 = SplitPathFileCd(path, dirpath);
    loadhandle0();
    errno = popen((char *)fname1, 'd');
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
    char dirpath[100];

    if (!mounted)
    {
        errno = ENXIO;
        return -1;
    }
    resolve_path(path, dirpath);
    if (!(err = pchdir(dirpath)))
    {
        if (*dirpath == '/')
            strcpy(currentwd, dirpath);
        else
        {
            if (strcmp(currentwd, "/"))
                strcat(currentwd, "/");
            strcat(currentwd, dirpath);
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
        case ENXIO:
            ptr = "No such devide or address";
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
        str = hgets((int *)fd->_flag, str, num);
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
    char path1[100];

    if (!mounted)
    {
        errno = ENXIO;
        return 0;
    }
    resolve_path(path, path1);
    if (pchdir(path1))
        return 0;
#if 0
    if (path[0] && strcmp(path, ".") && strcmp(path, "/") && strcmp(path,"./"))
        return 0;
#endif
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
    char path[100];
    char dirpath[100];
    char *fname1;

    if (!mounted)
    {
        errno = ENXIO;
        return -1;
    }
    resolve_path(fname, path);
    fname1 = SplitPathFileCd(path, dirpath);
    loadhandle0();
    retval = popen(fname1, 'r');
    if (retval) return -1;
    pstat(filestat);
    buf->st_size = filestat[1];
    buf->st_mode = S_IWRITE;
    if (filestat[0] & 0x10)
        buf->st_mode |= S_IFDIR | S_IEXEC;
    if (filestat[0] & 0x20)
        buf->st_mode |= S_IEXEC;
    if (!(filestat[0] & 0x01))
        buf->st_mode |= S_IREAD;
    pclose();
    return 0;
}

int mkdir(const char *path, int mode)
{
    int err;
    char path1[100];
    char dirpath[100];
    char *dirname;

    if (!mounted)
    {
        errno = ENXIO;
        return -1;
    }
    resolve_path(path, path1);
    dirname = SplitPathFileCd(path1, dirpath);
    err = pmkdir(dirname);
    if (err)
        errno = EEXIST;
    return err;
}

void rmdir(void)
{
    if (!mounted)
        errno = ENXIO;
}

static void memcpyr(char *dst, char *src, int num)
{
    dst += num - 1;
    src += num - 1;
    while (num-- > 0)
        *dst-- = *src--;
}

static char *SplitPathFileCd(char *fname, char *pathstr)
{
    char *fname1;

    strncpy(pathstr, fname, 80);
    fname1 = SplitPathFile(pathstr);
    if (pchdir(pathstr))
        return 0;
    return fname1;
}

static char *SplitPathFile(char *pathstr)
{
    int len, len1;

    // Search backwards for a "/"
    len1 = len = strlen(pathstr);
    if (!len)
        return pathstr;
    if (len == 1 && *pathstr == '/')
        return pathstr + 1;
    while (--len > 0)
    {
        if (pathstr[len] == '/')
        {
            pathstr[len] = 0;
            return pathstr + len + 1;
        }
    }
    if (*pathstr == '/')
    {
        memcpyr(pathstr+2, pathstr+1, len1);
        pathstr[1] = 0;
        return pathstr + 2;
    }
    else
    {
        memcpyr(pathstr+1, pathstr, len1+1);
        pathstr[0] = 0;
        return pathstr + 1;
    }
}
