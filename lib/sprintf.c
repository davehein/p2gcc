#include <stdarg.h>
#include <stdio.h>
#include <compiler.h>
#include <stdint.h>
#include <string.h>

/*
 * sprintf
 * does c,s,u,d,x,f,g
 */

#define ULONG unsigned long
#define LONG long

char *putfloatf(char *str, int x, int width, int digits);
char *putfloate(char *str, int x, int width, int digits);

static void putcharstr(char **ptr, int val)
{
    char *ptr1 = *ptr;
    *ptr1++ = val;
    *ptr = ptr1;
}

static int
putcw(char **ptr, int c, int width) {
	int put = 0;

	putcharstr(ptr, c); put++;
	while (--width > 0) {
		putcharstr(ptr, ' ');
		put++;
	}
	return put;
}

static int
putsw(char **ptr, const char *s, int width) {
	int put = 0;

	while (*s) {
	  putcharstr(ptr, *s++); put++;
	  width--;
	}
	while (width-- > 0) {
	  putcharstr(ptr, ' '); put++;
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
putlw(char **ptr, uint64_t u, int base, int width, int fill_char, int digits)
{
	int put = 0;
	char obuf[24]; /* 64 bits -> 22 digits maximum in octal */ 
	char *t;

	t = obuf;

	do {
		*t++ = d2a((int)(u % base));
		u /= base;
		width--;
                digits--;
	} while (u > 0);

        if (digits > 0)
            width -= digits;

	while (width-- > 0) {
	  putcharstr(ptr, fill_char); put++;
	}
	while (digits-- > 0) {
	  putcharstr(ptr, '0'); put++;
	}
	while (t != obuf) {
	  putcharstr(ptr, *--t); put++;
	}
	return put;
}

static int
putf(char **ptr, int val, int width, int digits)
{
    char *ptr1 = *ptr;

    *ptr = putfloatf(ptr1, val, width, digits);
    return strlen(ptr1);
}

static int
pute(char **ptr, int val, int width, int digits)
{
    char *ptr1 = *ptr;

    *ptr = putfloate(ptr1, val, width, digits);
    return strlen(ptr1);
}

int
vsprintf(char *ptr, const char *fmt, va_list args )
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
       outbytes += putcw(&ptr, c, 1);
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
       outbytes += putcw(&ptr, c, width);
       break;
     case 'c':
       i_arg = va_arg(args, unsigned int);
       outbytes += putcw(&ptr, i_arg, width);
       break;
     case 's':
       s_arg = va_arg(args, char *);
       outbytes += putsw(&ptr, s_arg, width);
       break;
     case 'd':
     case 'x':
     case 'u':
     case 'o':
       if (c == 'x')
           base = 16;
       else if (c == 'o')
           base = 8;
       else
           base = 10;
       l_arg = (uint64_t)va_arg(args, ULONG);
       if (long_flag >= 2)
         l_arg |= ((uint64_t)va_arg(args, ULONG)) << 32;
       else
         l_arg = (((int64_t)l_arg) << 32) >> 32;
       if (c == 'd') {
	 if (((int64_t)l_arg) < 0) {
           outbytes += putcw(&ptr, '-', 1);
           width--;
           l_arg = (uint64_t)(-((int64_t)l_arg));
         }
       }
       outbytes += putlw(&ptr, l_arg, base, width, fill_char, digits);
       break;
     case 'f':
       i_arg = va_arg(args, unsigned int);
       outbytes += putf(&ptr, i_arg, width, digits);
       break;
     case 'e':
       i_arg = va_arg(args, unsigned int);
       outbytes += pute(&ptr, i_arg, width, digits);
       break;
     }
   }
   putcharstr(&ptr, 0);
   return outbytes;
}

int sprintf(char *ptr, const char *fmt, ...)
{
    va_list args;
    int r;
    va_start(args, fmt);
    r = vsprintf(ptr, fmt, args);
    va_end(args);
    return r;
}
