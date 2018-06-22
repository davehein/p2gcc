#include <stdio.h>
#include <propeller.h>

int value1 = 0x1234;
static int value2 = 0x5678;
int value3;

int main(void)
{
    waitcnt(CNT+12000000);
    printf("value1 = %x, &value1 = %x\n", value1, &value1);
    printf("value2 = %x, &value2 = %x\n", value2, &value2);
    printf("value3 = %x, &value3 = %x\n", value3, &value3);
    printf("__files = %x\n", __files);
    printf("stdin = %x\n", stdin);
    printf("&__files[1] = %x\n", &__files[1]);
    printf("stdout = %x\n", stdout);
    printf("sizeof(FILE) = %x\n", sizeof(FILE));
    testsub();
    return 0;
}
