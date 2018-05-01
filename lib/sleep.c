void sleep(int seconds)
{
    __asm__("mov r1, ##80000000");
    __asm__("call #__MULSI");
    __asm__("waitx r0");
}
