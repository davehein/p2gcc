//******************************************************************************
// Floating Point I/O Routines
// Author: Dave Hein
// Copyright (c) 2010
// See end of file for terms of use.
//******************************************************************************
//******************************************************************************
// Revison History
// v1.0 - 4/2/2010 First official release
//******************************************************************************
/*
  These routines are used by the C library to perform formatted floating point
  I/O.  The two output routines, putfloate and putfloatf write to string.

  Input formatting is performed by the strtofloat routine.  It uses a pointer
  to a string pointer and returns the resulting floating point value.

  If floating point I/O is not required for an application this file can be
  removed by deleting the references to the object and the three routines in
  clib.spin.
*/
#include <stdint.h>
#include <string.h>

float strtofloat(char **pstr);
static int numdigits(int man, int *pdiv);
static int round10(int digits, int *pman);
static char *utoa10(int number, char *str, int point);
static float fromfloat10(int man, int exp10, int signbit);
static int tofloat10(float fvalue, int *pman, int *pexp10);
static char *dochar(char *str, int val, int point, int num);
static int floatloop(int man, int *pexp0, int *pexp1, char *step0, char *step1, int *scale, int *pexp2, int step2);

/*
  These tables of scalers are used to scale a floating point number by a ratio of a
  power of 10 versus a power of 2.
*/
static int scale1[] = {
//SCALE1         10/16      100/128    1000/1024   10^6/2^20  10^12/2^40  10^24/2^80
              1342177280, 1677721600, 2097152000, 2048000000, 1953125000, 1776356839 };
static int scale2[] = {
//SCALE2          8/10       64/100     512/1000   2^19/10^6  2^39/10^12  2^79/10^24
              1717986918, 1374389535, 1099511628, 1125899907, 1180591621, 1298074215 };
static char nbits1[] = {  4, 7, 10, 20, 40, 80, 0, 0 };
static char nbits2[] = {  3, 6,  9, 19, 39, 79, 0, 0 };
static char ndecs[]  = {  1, 2,  3,  6, 12, 24, 0, 0 };

double atof(const char *str)
{
  return (double)strtofloat((char **)&str);
}

float strtof(const char *str, char **endptr)
{
  float x = strtofloat((char **)&str);
  if (endptr)
    *endptr = (char *)str;
  return x;
}

//******************************************************************************  
// Floating Point Routines
//******************************************************************************
/*
  Convert the floating point value in x to a string of characters in scientific
  notation in str.  digits determines the number of fractional digits used and
  width determines the minimum length of the output string.  Leading blanks are
  added to achieve the minimum width.
*/ 
char *putfloate(char *str, float x, int width, int digits)
{
  int man, exp10, signbit, temp;

  if (digits < 0)
    digits = 6;
  signbit = tofloat10(x, &man, &exp10);
  if (man)
  {
    exp10 += round10(digits + 1, &man) + digits;
    if (numdigits(man, &temp) > digits + 1)
    {
      exp10++;
      man /= 10;
    }
  }
  width -= 5 - signbit + (digits != 0);
  while (width-- > digits)
    *str++ = ' ';
  if (signbit)
    *str++ = '-';
  if (man)
    str = utoa10(man, str, 1);
  else
    str = dochar(str, '0', 1, digits + 1);
  *str++ = 'e';
  if (exp10 >= 0)
    *str++ = '+';
  else
  {
    *str++ = '-';
    exp10 = -exp10;
  }
  if (exp10 < 10)
    *str++ = '0';
  str = utoa10(exp10, str, -1);
  *str = 0;
  return str;
}

/*
  Convert the floating point value in x to a string of character in standard
  notation in str.  digits determines the number of fractional digits used and
  width determines the minimum length of the output string.  Leading blanks are
  added to achieve the minimum width.
*/
char *putfloatf(char *str, float x, int width, int digits)
{
  int lead0, trail0, man, exp10, signbit, digits0;
  int leftdigits, temp;

  if (digits < 0)
    digits = 6;
  signbit = tofloat10(x, &man, &exp10);
  if (man == 0)
  {
    width -= digits + (digits > 0) + 1;
    while (width-- > 0)
      *str++ = ' ';
    str = dochar(str, '0', 1, digits + 1);
    return str;
  }
  digits0 = numdigits(man, &lead0) + exp10;
  leftdigits = digits0;
  if (digits0 > 0)
    width -= digits0;
  digits0 += digits;
  if (digits0 > 8)
    digits0 = 8;
  temp = round10(digits0, &man);
  if (numdigits(man, &lead0) > digits0)
  {
    if (++leftdigits > 0)
      width--;
    if (digits0 == 8)
      man /= 10;
    else if (++digits0 > 8)
      digits0 = 8;
  }
  exp10 += temp + digits0 - 1;
  if (digits0 < 0)
    digits0 = 0;
  else if (digits0 == 0 && man == 1 && digits > 0)
    digits0 = 1;
  lead0 = digits - digits0;
  trail0 = digits - digits0 + exp10 + 1;
  width -= -signbit + digits + (lead0 >= 0) + 1;
  while (width-- > 0)
    *str++ = ' ';
  if (signbit)
    *str++ = '-';
  if (lead0 >= 0)
    *str++ = '0';
  if (lead0 > 0)
    *str++ = '.';
  while (lead0-- > 0)
    *str++ = '0';
  if (digits0 > 0)
    str = utoa10(man, str, exp10 + 1);
  exp10 -= digits0 - 1;
  while (trail0-- > 0)
  {
    if (exp10-- == 0)
      *str++ = '.';
    *str++ = '0';
  }
  *str = 0;
  return str;
}

/*
  Convert the string of characters pointer to by "pstr" into a floating point
  value.  The input can be in either standard or scientific notation.  Leading
  blanks are ignored.  The string pointed to by "pstr" is updated to the last
  character postioned that caused processing to be completed.
*/
float strtofloat(char **pstr)
{
  int value, exp10, exp10a, signbit, mode, strchar, esignbit;
  int loop = 1;
  char *str;

  str = *pstr;
  esignbit = 0;
  mode = 0;
  value = 0;
  exp10 = 0;
  exp10a = 0;
  signbit = 0;
  while (loop)
  {
    strchar = *str++;
    if (strchar == 0)
      break;
    switch (mode)
    {
      case 0:
      if (strchar >= '0' && strchar <= '9')
        value = strchar - '0';
      else if (strchar == '-')
        signbit = 1;
      else if (strchar == '.')
      {
        mode = 2;
        continue;
      }
      else if (strchar != '+')
        loop = 0;
      mode = 1;
      break;

      case 1:
      if (strchar >= '0' && strchar <= '9')
      {
        if (value <= 200000000)
          value = (value * 10) + strchar  - '0';
        else
          exp10++;
      }
      else if (strchar == '.')
        mode = 2;
      else if (strchar == 'e' || strchar == 'E')
        mode = 3;
      else
        loop = 0;
      break;

      case 2:
      if (strchar >= '0' && strchar <= '9')
      {
        if (value <= 200000000)
        {
          value = (value * 10) + strchar  - '0';
          exp10--;
        }
      }
      else if (strchar == 'e' || strchar == 'E')
        mode = 3;
      else
        loop = 0;
      break;

      case 3:
      if (strchar >= '0' && strchar <= '9')
        exp10a = strchar - '0';
      else if (strchar == '-')
        esignbit = 1;
      else if (strchar != '+')
        loop = 0;
      mode = 4;
      break;

      case 4:
      if (strchar >= '0' && strchar <= '9')
        exp10a = (exp10a * 10) + strchar - '0';
      else
        loop = 0;
      break;
    }
  }
  if (esignbit)
    exp10 -= exp10a;
  else
    exp10 += exp10a;
  *pstr = str;
  return fromfloat10(value, exp10, signbit);
}

/* This private routine returns the upper 32 bits of the product of the two values */
static int multupper(int val1, int val2)
{
  int64_t dval1 = (int64_t)val1;
  int64_t dval2 = (int64_t)val2;

  return (int32_t)((dval1 * dval2) >> 32);
}

/*
  This private routine reduces the value of exp0 toward 0 while increasing the value
  of exp1.  This is done in a successive approximation method using the scaling
  table passed in "scale".  This routine is used here to convert between a mantissa
  times a power of 2 or 10 to a mantissa times a power of 10 or 2.
*/
static int floatloop(int man, int *pexp0, int *pexp1, char *step0, char *step1, int *scale, int *pexp2, int step2)
{
  int i;

  for (i = 5; i >= 0; i--)
  {
    if (*pexp0 >= step0[i])
    {
      man = multupper(man, scale[i]) << 1;
      *pexp0 -= step0[i];
      *pexp1 += step1[i];
      if ((man & 0x40000000) == 0)
      {
        man <<= 1;
        *pexp2 -= step2;
      }
    }
  }
  return man;
}

/*
  This private routine converts from a mantissa times a power of 2 to a mantissa
  times a power of 10.
*/
static int tofloat10(float fvalue, int *pman, int *pexp10)
{
  int exp2, exp10, man, result, value;

  memcpy(&value, &fvalue, 4);
  if (value == 0)
  {
    *pman = 0;
    *pexp10 = 0;
    return 0;
  }
  result = value >> 31;
  exp2 = ((value >> 23) & 255) - 157;
  man = ((value & 0x007fffff) | 0x00800000) << 7;
  exp10 = 0;
  if (exp2 <= 0)
  {
    exp2 = -exp2;
    man = floatloop(man, &exp2, &exp10, nbits1, ndecs, scale1, &exp2, -1);
    man >>= exp2;
    exp10 = -exp10;
  }
  else
  {
    exp2 += 2;
    man = floatloop(man, &exp2, &exp10, nbits2, ndecs, scale2, &exp2,  1);
    man >>= 2 - exp2;
  }
  *pman = man;
  *pexp10 = exp10;
  return result;
}
  
/*
  This private routine converts from a mantissa times a power of 10 to a mantissa
  times a power of two.
*/
static float fromfloat10(int man, int exp10, int signbit)
{
  float fvalue;
  int exp2, value;

  if (man == 0)
    return 0;
  exp2 = 0;
  while ((man & 0x40000000) == 0)
  {
    man <<= 1;
    exp2--;
  }
  if (exp10 <= 0)
  {
    exp10 = -exp10;
    exp2 = -exp2;
    man = floatloop(man, &exp10, &exp2, ndecs, nbits2, scale2, &exp2, -1);
    exp2 = -exp2;
  }
  else
    man = floatloop(man, &exp10, &exp2, ndecs, nbits1, scale1, &exp2, 1);
  while(man & 0xff000000)
  {
    man >>= 1;
    exp2++;
  }
  value = (signbit << 31) | ((exp2 + 150) << 23) | (man & 0x007fffff);
  memcpy(&fvalue, &value, 4);
  return fvalue;
}

/*
  This routine determines the number of decimal digits in the number in man.
*/
static int numdigits(int man, int *pdiv)
{
  int numdig, divisor;

  numdig = 10;
  divisor = 1000000000;
  while (divisor > man)
  {
    numdig--;
    divisor /= 10;
  }
  *pdiv = divisor;
  return numdig;
}

/*
  This routine rounds the number pointed to by pman to the number of decimal
  digits specified by "digits".
*/
static int round10(int digits, int *pman)
{
  int i;
  int exp10, divisor, rounder, man;

  man = *pman;
  exp10 = numdigits(man, &divisor) - digits;
  if (digits < 0)
    man = 0;
  else if (digits == 0)
  {
    if (man / divisor >= 5)
      man = 1;
    else
      man = 0;
  }
  else if (exp10 > 0)
  {
    rounder = 1;
    for (i = 0; i < exp10; i++)
      rounder *= 10;
    man = (man + (rounder >> 1)) / rounder;
    divisor /= rounder;
  }
  else if (exp10 < 0)
  {
    for (i = 0; i < -exp10; i++)
      man *= 10;
  }
  *pman = man;
  return exp10;
}

/*
  This routine converts the value in "number" to a string of decimal characters
  in "str".  A decimal point is added after the character position specified by
  the value in "point".
*/
static char *utoa10(int number, char *str, int point)
{
  int divisor, temp;

  if (number == 0)
  {
    *str++ = '0';
    *str = 0;
    return str;
  }
  divisor = 1000000000;
  while (divisor > number)
    divisor /= 10;
  while (divisor > 0)
  {
    if (point-- == 0)
      *str++ = '.';
    temp = number / divisor;
    *str++ = temp + '0';
    number -= temp * divisor;
    divisor /= 10;
  }
  *str = 0;
  return str;
}

/*
  This routine generate num copies of the character given by val, and adds it
  to str.  A decimal point is added after the character position specified by
  the value in point.
*/
static char *dochar(char *str, int val, int point, int num)
{
    int i;

    for (i = 0; i < num; i++)
    {
        if (i == point)
          *str++ = '.';
        *str++ = val;
    }
    *str = 0;
    return str;
}

/*
+--------------------------------------------------------------------
|  TERMS OF USE: MIT License
+--------------------------------------------------------------------
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
+------------------------------------------------------------------
*/
