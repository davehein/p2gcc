int p2clkfreq;

void sleep(int seconds)
{
    __asm__("rdlong r1, ##_p2clkfreq");
    __asm__("call #__MULSI");
    __asm__("waitx r0");
}
