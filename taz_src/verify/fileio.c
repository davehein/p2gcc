int errno;
int *stdin;
int *stdout;
int *stderr;
char dirbuf[16];
int filelist[10] = {1, 1, 1, 0, 0, 0, 0, 0, 0, 0};
char currentwd[100];

void sd_mount(int DO, int CLK, int DI, int CS)
{
    int i;
    filelist[0] = 0x100000;
    filelist[1] = 0x100000;
    filelist[2] = 0x100000;
    memset(&filelist[3], 0, 28);
    stdin = &filelist[0];
    stdout = &filelist[1];
    stderr = &filelist[2];
    strcpy(currentwd, "/");
    mount_explicit(DO, CLK, DI, CS);
}

void sd_unmount(void)
{
    unmount();
}

int *allocfile(int size)
{
    int i;

    for (i = 0; i < 10; i++)
    {
        if (!filelist[i]) break;
    }
    if (i == 10) return 0;
    filelist[i] = malloc(size);
    if (filelist[i]) return &filelist[i];
    return 0;
}

void freefile(int *fd)
{
    if (fd && *fd)
    {
        if (!(*fd & 0xfff00000)) free(*fd);
        *fd = 0;
    }
}

char *fopen(char *fname, char *mode)
{
    int i;
    int err;
    int *fd;
    int *handle;
    if (*mode != 'r' && *mode != 'w' && *mode != 'a') return 0;
    fd = allocfile(44 + 512);
    if (!fd) return 0;
    handle = *fd;
    memset(handle, 0, 40);
    handle[10] = &handle[11];
    loadhandle(handle);
    err = popen(fname, *mode);
    if (err)
    {
        //printf("popen returned %d\n", err);
        loadhandle0();
        freefile(fd);
        return 0;
    }
    return fd;
}

int fclose(int *fd)
{
    if (!fd) return -1;
    loadhandle(*fd);
    pclose();
    loadhandle0();
    freefile(fd);
    return 0;
}

int fread(char *ptr, int size, int num, int *fd)
{
    size *= num;
    if (*fd & 0xfff00000)
    {
        num = size;
        while (size--) *ptr++ = getchar();
    }
    else
    {
        loadhandle(*fd);
        num = pread(ptr, size);
    }
    if (num < 0) num = 0;
    return num;
}

int fwrite(char *ptr, int size, int num, int *fd)
{
    size *= num;
    if (*fd & 0xfff00000)
    {
        while (size--) putchar(*ptr++);
    }
    else
    {
        loadhandle(*fd);
        pwrite(ptr, size);
    }
}

int remove(char *fname)
{
    loadhandle0();
    popen(fname, 'd');
    return 0;
}

int fgetc(int *fd)
{
    int val;
    if (*fd & 0xfff00000) return getchar();
    loadhandle(*fd);
    val = pgetc();
    return val;
}

void fputc(int val, int *fd)
{
    if (*fd & 0xfff00000)
        putchar(val);
    else
    {
        loadhandle(*fd);
        pputc(val);
    }
}

int chdir(char *path)
{
    if (!pchdir(path))
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
    if (pchdir(currentwd)) strcpy(currentwd, "/");
    return -1;
}

void perror(char *str)
{
    if (str) printf("%s: ", str);
    printf("error %d\n", errno);
}

char *getcwd(char *ptr, int size)
{
    strncpy(ptr, currentwd, size);
    return ptr;
}

void fputs(char *str, int *fd)
{
    if (*fd & 0xfff00000)
        puts(str);
    else
    {
        loadhandle(*fd);
        pputs(str);
    }
}

void fprintf(int *fd, char *fmt, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10)
{
    int i, index;
    int arglist[10];
    char outstr[200];

    va_start(index, fmt);
    for (i = 0; i < 10; i++)
        arglist[i] = va_arg(index, int);
    va_end(index);
    vsprintf(outstr, fmt, arglist);
    fputs(outstr, fd);
}

int fflush(int *fd)
{
    return 0;
    if (!fd) return -1;
    if (*fd & 0xfff00000) return 0;
    loadhandle(*fd);
    pflush();
}

int *opendir(char *path)
{
    int i;
    int err;
    int *fd;
    int *handle;
    if (path[0] && strcmp(path, ".") && strcmp(path, "/") && strcmp(path,"./"))
        return 0;
    fd = allocfile(44 + 512);
    if (!fd) return 0;
    handle = *fd;
    memset(handle, 0, 40);
    handle[10] = &handle[11];
    loadhandle(handle);
    err = popendir();
    if (err)
    {
        loadhandle0();
        freefile(fd);
        return 0;
    }
    return fd;
}

int *readdir(int *fd)
{
    loadhandle(*fd);
    if (!nextfile(dirbuf))
        return dirbuf;
    return 0;
}

int closedir(int *fd)
{
    return fclose(fd);
}

int fseek(int *fd, int offset, int origin)
{
    if (!fd || origin < 0 || origin > 2) return -1;

    loadhandle(*fd);
    if (origin == 1)
        offset += tell();
    else if (origin == 2)
        offset += get_filesize();
    return seek(offset);
}

int ftell(int *fd)
{
    loadhandle(*fd);
    return tell();
}

int fstat(int *fd, int *filestat)
{
    loadhandle(*fd);
    pstat(filestat);
    return 0;
}

int stat(char *fname, int *filestat)
{
    int retval;
    loadhandle0();
    retval = popen(fname, 'r');
    if (retval) return -1;
    pstat(filestat);
    pclose();
    return 0;
}

void mkdir(char *path, int mode)
{
    return pmkdir(path);
}

void rmdir(void)
{
}
