#include <stdio.h>

int value1;
int value2;
int value3 = 0xFEED;
static int value4 = 0xdef0;
static int value5;

void testsub(void)
{
    printf("value1 = %x, &value1 = %x\n", value1, &value1);
    printf("value2 = %x, &value2 = %x\n", value2, &value2);
    printf("value3 = %x, &value3 = %x\n", value3, &value3);
    printf("value4 = %x, &value4 = %x\n", value4, &value4);
    printf("value5 = %x, &value5 = %x\n", value5, &value5);
    printf("__files = %x\n", __files);
    printf("stdin = %x\n", stdin);
    printf("&__files[1] = %x\n", &__files[1]);
    printf("stdout = %x\n", stdout);
}
