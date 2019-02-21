#include <stdio.h>
#include <stdlib.h>
#include "osint.h"

int sendfile(int argc, char **argv);

int main(int argc, char **argv)
{
    if (1 != serial_init("com4", 115200))
    {
        printf("Couldn't open serial channel\n");
        exit(1);
    }

    sendfile(argc, argv);

    serial_done();

    return 0;
}

void putch(int val)
{
    tx((unsigned char *)&val, 1);
}

int rxtime(int msec)
{
    int num;
    int val = 0;

    num = rx_timeout((unsigned char *)&val, 1, msec);
    if (num == 1) return val;
    return -1;
}
