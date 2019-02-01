#include <stdarg.h>
#include <stdio.h>
#include <compiler.h>
#include <stdint.h>
#include <string.h>

/*
 * printf
 * does c,s,u,d,x,f,e
 */

#define ULONG unsigned long
#define LONG long

char *putfloatf(char *str, int x, int width, int digits);
char *putfloate(char *str, int x, int width, int digits);

static int
putcw(int c, int width) {
	int put = 0;

	putchar(c); put++;
	while (--width > 0) {
		putchar(' ');
		put++;
	}
	return put;
}

static int
putsw(const char *s, int width) {
	int put = 0;

	while (*s) {
	  putchar(*s++); put++;
	  width--;
	}
	while (width-- > 0) {
	  putchar(' '); put++;
	}
	return put;
}

static int d2a(int val)
{
    if (val < 10)
        val += '0';
    else
        val += 'A' - 10;
    return val;
}

static int ISDIGIT(int val)
{
    if (val >= '0' && val <= '9') return 1;
    return 0;
}

static int
putlw(uint64_t u, int base, int width, int fill_char, int digits)
{
	int put = 0;
	char obuf[24]; /* 64 bits -> 22 digits maximum in octal */ 
	char *t;

	t = obuf;
        do {
            *t++ = d2a((int)(u % base));
            u /= base;
            width--;
        } while (u > 0);
	while (width-- > 0) {
	  putchar(fill_char); put++;
	}
	while (t != obuf) {
	  putchar(*--t); put++;
	}
	return put;
}

static int
putf(int val, int width, int digits)
{
    char obuf[100];
    char *ptr = obuf;

    putfloatf(obuf, val, width, digits);
    while (*ptr) putchar(*ptr++);
    return strlen(obuf);
}

static int
pute(int val, int width, int digits)
{
    char obuf[100];
    char *ptr = obuf;

    putfloate(obuf, val, width, digits);
    while (*ptr) putchar(*ptr++);
    return strlen(obuf);
}

static int
_doprnt( const char *fmt, va_list args )
{
   char c, fill_char;
   char *s_arg;
   unsigned int i_arg;
   uint64_t l_arg;
   int width, long_flag;
   int outbytes = 0;
   int base;
   int digits;

   while( (c = *fmt++) != 0 ) {
     if (c != '%') {
       outbytes += putcw(c, 1);
       continue;
     }
     c = *fmt++;
     width = 0;
     digits = -1;
     long_flag = 0;
     fill_char = ' ';
     if (c == '0') fill_char = '0';
     while (c && ISDIGIT(c)) {
       width = 10*width + (c-'0');
       c = *fmt++;
     }
     if (c == '.')
     {
       c = *fmt++;
       digits = 0;
       while (c && ISDIGIT(c)) {
         digits = 10*digits + (c-'0');
         c = *fmt++;
       }
     }
     /* for us "long int" and "int" are the same size, so
	we can ignore one 'l' flag; use long long if two
    'l flags are seen */
     while (c == 'l' || c == 'L') {
       long_flag++;
       c = *fmt++;
     }
     if (!c) break;

     switch (c) {
     case '%':
       outbytes += putcw(c, width);
       break;
     case 'c':
       i_arg = va_arg(args, unsigned int);
       outbytes += putcw(i_arg, width);
       break;
     case 's':
       s_arg = va_arg(args, char *);
       outbytes += putsw(s_arg, width);
       break;
     case 'd':
     case 'x':
     case 'u':
       base = (c == 'x') ? 16 : 10;
       l_arg = (uint64_t)va_arg(args, ULONG);
       if (long_flag >= 2)
         l_arg |= ((uint64_t)va_arg(args, ULONG)) << 32;
       else
         l_arg = (((int64_t)l_arg) << 32) >> 32;
       if (c == 'd') {
         if ((int64_t)l_arg < 0) {
           outbytes += putcw('-', 1);
           width--;
           l_arg = (uint64_t)(-((int64_t)l_arg));
         }
       }
       outbytes += putlw(l_arg, base, width, fill_char, digits);
       break;
     case 'f':
       i_arg = va_arg(args, unsigned int);
       outbytes += putf(i_arg, width, digits);
       break;
     case 'e':
       i_arg = va_arg(args, unsigned int);
       outbytes += pute(i_arg, width, digits);
       break;
     }
   }
   return outbytes;
}

int printf(const char *fmt, ...)
{
    va_list args;
    int r;
    va_start(args, fmt);
    r = _doprnt(fmt, args);
    va_end(args);
    return r;
}
