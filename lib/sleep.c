void sleep(int seconds)
{
    __asm__("rdlong r1, #$14");
    __asm__("call #__MULSI");
    __asm__("waitx r0");
}
