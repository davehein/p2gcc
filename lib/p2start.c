#define p2clkfreq (*(int *)0x14)
#define p2baudrate (*(int *)0x1c)

int main(void);

int p2bitcycles = 694;

void configserial(int baudrate)
{
    p2bitcycles = p2clkfreq/baudrate;
}

void _setbaud(int baudrate)
{
    p2baudrate = baudrate;
    configserial(baudrate);
}

void p2start(void)
{
    configserial(p2baudrate);
    main();
}
