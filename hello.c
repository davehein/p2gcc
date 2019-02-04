#include <stdio.h>
#include <propeller.h>

#define p2clkfreq (*(int *)0x14)

void main(void)
{
    int i;

    for (i = 1; i <= 10; i++)
    {
        waitcnt(CNT+p2clkfreq/2);
        printf("Hello World - %d\n", i);
    }
    printf("Goodbye\n");
}
