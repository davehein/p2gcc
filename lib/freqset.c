#define p2clkfreq   (*(unsigned int *)0x14)
#define p2clkconfig (*(unsigned int *)0x18)
#define p2baudrate  (*(unsigned int *)0x1c)

void configserial(int baudrate);

void __attribute__((noinline)) change_clkmode(int clkmode)
{
    __asm__("hubset  r0");       // set up oscillator 
    __asm__("waitx   ##200000"); // wait 200,000 cycles
    __asm__("or      r0, #3");   // enable XI+PLL mode
    __asm__("hubset  r0");       // enable oscillator
}

void clkset(int mode, int freq)
{
    p2clkfreq = freq;
    p2clkconfig = mode;
    change_clkmode(mode);
    configserial(p2baudrate);
}

void freqset(int freq)
{
    int xtalfreq = 20000000;
    int xdiv = 4;
    int xdivp = 2;
    int xosc = 2;
    int xmul, xpppp, mode;

    if (freq > 180)
    {
        xdiv = 10;
        xdivp = 1;
    }

    xmul = freq/100*xdiv*xdivp/(xtalfreq/100);
    xpppp = ((xdivp >> 1) + 15) & 0xf;
    mode = (1 << 24) + ((xdiv-1) << 18) + ((xmul - 1) << 8) + (xpppp << 4) + (xosc << 2);

    clkset(mode, freq);
}
