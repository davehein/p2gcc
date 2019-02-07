#include <stdint.h>
#include <stdio.h>
#include <propeller.h>

#define p2clkfreq   (*(unsigned int *)0x14)
#define p2clkconfig (*(unsigned int *)0x18)
#define p2baudrate  (*(unsigned int *)0x1c)

int p2bitcycles;

int main()
{
    int freq;

    sleep(1);
    while (1)
    {
        printf("p2clkfreq   = %d %x\n", p2clkfreq, &p2clkfreq);
        printf("p2clkconfig = %d %x\n", p2clkconfig, &p2clkconfig);
        printf("p2baudrate  = %d %x\n", p2baudrate, &p2baudrate);
        printf("p2bitcycles = %d %x\n", p2bitcycles, &p2bitcycles);
        printf("Enter freq: ");
        scanf("%d", &freq);
        if (freq < 10000000 || freq > 320000000)
        {
            printf("freq %d is out of range\n", freq);
            break;
        }
        freqset(freq);
    }
}
