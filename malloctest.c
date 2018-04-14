#include <stdio.h>
#include <stdlib.h>
#include <propeller.h>

int malloclist;
int memfreelist;
int heapaddrlast;

void PrintMallocSpace(void)
{
    int *ptr;
    int ival;

    printf("Malloc list\n");
    ptr = (int *)malloclist;
    while (ptr)
    {
        printf("address = %x, data address = %x, size = %x\n", ptr, ptr+2, ptr[1]-8);
        ptr = (int *)ptr[0];
    }

    printf("Free list\n");
    ptr = (int *)memfreelist;
    while (ptr)
    {
        printf("address = %x, data address = %x, size = %x\n", ptr, ptr+2, ptr[1]-8);
        ptr = (int *)ptr[0];
    }

    printf("Stack space\n");
    ival = (int)&ptr;
    printf("heapaddrlast = %x, %x bytes available\n", heapaddrlast, ival - heapaddrlast);
}

int main(void)
{
    int size;
    char *ptr;
    char buffer[80];

    waitcnt(CNT+12000000);
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
            free(ptr);
            //size = free(ptr);
            //printf("Return value = %x\n", size);
        }
        else if (!strcmp(buffer, "dump"))
        {
            PrintMallocSpace();
        }
        else if (!strcmp(buffer, "exit"))
        {
            break;
        }
        else
            printf("Commands are malloc, free, dump and exit\n");
    }
    return 0;
}
