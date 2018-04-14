#include <stdio.h>

void CheckStack(void)
{
    int dummy;

    printf("%d - %d = %d\n", (int)&dummy, (int)CheckStack, (char *)&dummy - (char *)CheckStack);
}
