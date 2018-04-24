#include <propeller.h>

unsigned int _clkfreq = 80000000;

int main(void)
{
  int32_t	Index;
  DIRB |= (63);
  while (1) {
    for(Index = 0; Index <= 5; Index++) {
      OUTB |= (1 << Index);
      waitcnt(((CLKFREQ / 50) + CNT));
      OUTB &= (~(1 << Index));
      waitcnt(((CLKFREQ / 50) + CNT));
    }
    for(Index = 5; Index >= 0; Index--) {
      OUTB |= (1 << Index);
      waitcnt(((CLKFREQ / 50) + CNT));
      OUTB &= (~(1 << Index));
      waitcnt(((CLKFREQ / 50) + CNT));
    }
  }
}
