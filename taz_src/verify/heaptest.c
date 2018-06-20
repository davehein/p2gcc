int malloclist;
int memfreelist;
int heapaddrlast;

void PrintMallocSpace(int parm)
{
    int *ptr;
    int ival;

    printf("Malloc list\n");
    inline("cogid reg0");
    printf("cognum %d\n", parm);
    inline("mov reg0, ptra");
    printf("ptra = %x\n", parm);
    inline("mov reg0, ptrb");
    printf("ptrb = %x\n", parm);
    printf("&ival = %x\n", &ival);
    printf("heapaddrlast = %x\n", heapaddrlast);
    inline("mov reg0, $58");
    printf("$58 = %x\n", parm);
    inline("mov reg0, $59");
    printf("$59 = %x\n", parm);
    inline("mov reg0, $5a");
    printf("$5a = %x\n", parm);
    inline("mov reg0, $5b");
    printf("$5b = %x\n", parm);
    ptr = malloclist;
    while (ptr)
    {
        printf("%x %x\n", ptr, ptr[1]);
        ptr = ptr[0];
    }

    printf("Free list\n");
    ptr = memfreelist;
    while (ptr)
    {
        printf("%x %x\n", ptr, ptr[1]);
        ptr = ptr[0];
    }

    printf("Stack space\n");
    ival = &ptr;
    printf("%x %x\n", heapaddrlast, ival - heapaddrlast);
}
    
void main(void)
{
    int size;
    char *ptr;
    char buffer[80];

    PrintMallocSpace();
    while (1)
    {
        printf("Enter command: ");
        gets(buffer);
        if (!strcmp(buffer, "malloc"))
        {
            printf("Enter size: ");
            scanf("%x", &size);
            ptr = malloc(size);
            printf("Return value = %x\n", ptr);
        }
        else if (!strcmp(buffer, "free"))
        {
            printf("Enter address: ");
            scanf("%x", &ptr);
            size = free(ptr);
            printf("Return value = %x\n", size);
        }
        else if (!strcmp(buffer, "dump"))
        {
            PrintMallocSpace();
        }
        else if (!strcmp(buffer, "trim"))
        {
            trimfreelist();
        }
        else if (!strcmp(buffer, "exit"))
            break;
        else
            printf("Commands are malloc, free, dump, trim and exit\n");
    }
}
