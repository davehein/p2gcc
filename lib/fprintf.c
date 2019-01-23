#include <stdarg.h>
#include <stdio.h>
//#include <ctype.h>
#include <compiler.h>
#include <stdint.h>

/*
 * very simple printf -- just understands a few format features
 * does c,s,u,d,x
 */

#define ULONG unsigned long
#define LONG long

//unsigned char __ctype[];

static int
fputcw(FILE *fd, int c, int width) {
	int put = 0;

	fputc(c, fd); put++;
	while (--width > 0) {
		fputc(' ', fd);
		put++;
	}
	return put;
}

static int
fputsw(FILE *fd, const char *s, int width) {
	int put = 0;

	while (*s) {
	  fputc(*s++, fd); put++;
	  width--;
	}
	while (width-- > 0) {
	  fputc(' ', fd); put++;
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
fputlw(FILE *fd, uint64_t u, int base, int width, int fill_char, int digits)
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
	  fputc(fill_char, fd); put++;
	}
	while (t != obuf) {
	  fputc(*--t, fd); put++;
	}
	return put;
}

static int
_dofprnt(FILE *fd, const char *fmt, va_list args )
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
       outbytes += fputcw(fd, c, 1);
       continue;
     }
     c = *fmt++;
     width = 0;
     digits = 0;
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
       while (c && ISDIGIT(c)) {
         digits = 10*digits + (c-'0');
         c = *fmt++;
       }
     }
     else
       digits = width;
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
       outbytes += fputcw(fd, c, width);
       break;
     case 'c':
       i_arg = va_arg(args, unsigned int);
       outbytes += fputcw(fd, i_arg, width);
       break;
     case 's':
       s_arg = va_arg(args, char *);
       outbytes += fputsw(fd, s_arg, width);
       break;
     case 'd':
     case 'x':
     case 'u':
       base = (c == 'x') ? 16 : 10;
       l_arg = (uint64_t)va_arg(args, ULONG);
       if (long_flag >= 2)
         l_arg |= ((uint64_t)va_arg(args, ULONG)) << 32;
       if (c == 'd') {
	 if (((int64_t)l_arg) < 0) {
           outbytes += fputcw(fd, '-', 1);
           width--;
           l_arg = (uint64_t)(-((int64_t)l_arg));
         }
       }
       outbytes += fputlw(fd, l_arg, base, width, fill_char, digits);
       break;
     }
   }
   return outbytes;
}

int fprintf(FILE *fd, const char *fmt, ...)
{
    va_list args;
    int r;
    va_start(args, fmt);
    r = _dofprnt(fd, fmt, args);
    va_end(args);
    return r;
}
