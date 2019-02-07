#include <stdio.h>
#include <string.h>

#define p2clkfreq (*(int *)0x14)
#define p2baudrate (*(int *)0x1c)

int main(int argc, char **argv);

FILE __files[10] = {{0}};
int p2bitcycles = 694;
int _start_address; 

static void init_files(void)
{
    int i;
    __files[0]._flag = 0x100000;
    __files[1]._flag = 0x100000;
    __files[2]._flag = 0x100000;
    for (i = 3; i < 10; i++) __files[i]._flag = 0;
}

static int __attribute__((noinline)) _get_ptrb(void)
{
    __asm__("mov r0, ptrb");
}

void configserial(int baudrate)
{
    p2bitcycles = p2clkfreq/baudrate;
}

void _setbaud(int baudrate)
{
    p2baudrate = baudrate;
    configserial(baudrate);
}

void patch_sys_config(void)
{
    memcpy(&p2clkfreq, (char *)&p2clkfreq + _start_address, 3 * 4);
}

void p2start(int argc, char **argv)
{
    _start_address = _get_ptrb();
    if (_start_address) patch_sys_config();
    configserial(p2baudrate);
    init_files();
    main(argc, argv);
}
