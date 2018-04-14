#include <stdio.h>
#include <propeller.h>

void main(void)
{
    int i;

    for (i = 1; i <= 10; i++)
    {
        waitcnt(CNT+12000000);
        printf("Hello World - %d\n", i);
    }
    printf("Goodbye\n");
}
