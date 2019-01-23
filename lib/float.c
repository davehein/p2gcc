//******************************************************************************
// Copyright (c) 2019 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdint.h>
#include <string.h>

#define MAX_FLOAT (3.402e+38)
#define MIN_FLOAT (2.351e-38)

float __divsf3(float x, float y)
{
  int64_t x_dman, y_dman;
  int ix, iy, x_sgn, x_exp, x_man, y_sgn, y_exp, y_man;
  memcpy(&ix, &x, 4);
  memcpy(&iy, &y, 4);
  if (ix == 0) return 0.0;
  if (iy == 0) return MAX_FLOAT;
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;
  y_sgn = (iy >> 31) & 1;
  y_exp = ((iy >> 23) & 255) - 150;
  y_man = (iy & 0x007fffff) | 0x00800000;

  x_sgn ^= y_sgn;
  x_exp -= y_exp;
  x_dman = x_man;
  y_dman = y_man;
  x_dman <<= 30;
  x_exp -= 30;
  x_dman /= y_dman;
  while (x_dman > 0x01ffffff)
  {
    x_dman >>= 1;
    x_exp++;
  }
  if (x_dman & 0x01000000)
  {
    x_dman = (x_dman + 1) >> 1;
    x_exp++;
  }
  x_man = x_dman & 0x007fffff;
  ix = (x_sgn << 31) | (((x_exp + 150) & 255) << 23) | x_man;
  memcpy(&x, &ix, 4);
  return x;
}

float __mulsf3(float x, float y)
{
  int64_t x_dman, y_dman;
  int ix, iy, x_sgn, x_exp, x_man, y_sgn, y_exp, y_man;
  memcpy(&ix, &x, 4);
  memcpy(&iy, &y, 4);
  if (ix == 0 || iy == 0) return 0.0;
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;
  y_sgn = (iy >> 31) & 1;
  y_exp = ((iy >> 23) & 255) - 150;
  y_man = (iy & 0x007fffff) | 0x00800000;

  x_sgn ^= y_sgn;
  x_exp += y_exp;
  x_dman = x_man;
  y_dman = y_man;
  x_dman *= y_dman;
  while (x_dman > 0x01ffffff)
  {
    x_dman >>= 1;
    x_exp++;
  }
  if (x_dman & 0x01000000)
  {
    x_dman = (x_dman + 1) >> 1;
    x_exp++;
  }
  x_man = x_dman & 0x007fffff;
  ix = (x_sgn << 31) | (((x_exp + 150) & 255) << 23) | x_man;
  memcpy(&x, &ix, 4);
  return x;
}

float __addsf3(float x, float y)
{
  int ix, iy, x_sgn, x_exp, x_man, y_sgn, y_exp, y_man;
  memcpy(&ix, &x, 4);
  memcpy(&iy, &y, 4);
  if (ix == 0) return y;
  if (iy == 0) return x;
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 157;
  x_man = (ix & 0x007fffff) | 0x00800000;
  y_sgn = (iy >> 31) & 1;
  y_exp = ((iy >> 23) & 255) - 157;
  y_man = (iy & 0x007fffff) | 0x00800000;

  if (x_exp > y_exp)
  {
    if (x_exp > y_exp + 24)
      return x;
    y_man += 1 << (x_exp - y_exp - 1);
    y_man >>= (x_exp - y_exp);
    y_exp = x_exp;
  }
  else if (y_exp > x_exp)
  {
    if (y_exp > x_exp + 24)
      return y;
    x_man += 1 << (y_exp - x_exp - 1);
    x_man >>= (y_exp - x_exp);
    x_exp = y_exp;
  }
  if (x_sgn == y_sgn)
  {
      x_man += y_man;
      if (x_man & 0x01000000)
      {
          x_man >>= 1;
          x_exp++;
      }
  }
  else
  {
      x_man -= y_man;
      if (x_man == 0)
          return 0.0;
      else if (x_man < 0)
      {
          x_man = -x_man;
          x_sgn ^= 1;
      }
      if (x_man & 0x01000000)
      {
          x_man >>= 1;
          x_exp++;
      }
      while (!(x_man & 0x00800000))
      {
          x_man <<= 1;
          x_exp--;
      }
  }
  ix = (x_sgn << 31) | (((x_exp + 157) & 255) << 23) | (x_man & 0x007fffff);
  memcpy(&x, &ix, 4);
  return x;
}

float __subsf3(float x, float y)
{
  int iy;
  memcpy(&iy, &y, 4);
  if (iy == 0) return x;
  iy ^= 0x80000000;
  memcpy(&y, &iy, 4);
  return __addsf3(x, y);
}

float floorf(float x)
{
  int x_sgn, x_exp, x_man, ix, x_man1;

  memcpy(&ix, &x, 4);
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  if (x_exp >= 0)
    return x;
  if (x_exp < -30)
    return 0.0;

  x_man1 = x_man;
  x_man = (x_man >> (-x_exp)) << (-x_exp);
  if (x_sgn && x_man1 != x_man)
  {
      x_man += 1 << (-x_exp);
      if (x_man & 0x01000000)
      {
          x_man = (x_man + 1) >> 1;
          x_exp++;
      }
  }
  ix = (x_sgn << 31) | (((x_exp + 150) & 255) << 23) | (x_man & 0x007fffff);
  memcpy(&x, &ix, 4);
  return x;
}

double floor(double x)
{
    return (double)floorf((float)x);
}

int __fixsfsi(float x)
{
  int x_sgn, x_exp, x_man, ix;

  memcpy(&ix, &x, 4);
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  if (x_exp > 7)
  {
      if (x_sgn)
          ix = 0x7fffffff;
      else
          ix = 0x80000000;
  }
  else if (x_exp >= 0)
  {
      ix = x_man << x_exp;
      if (x_sgn) ix = -ix;
  }
  else if (x_exp < -30)
      ix = 0;
  else
  {
      ix = x_man >> (-x_exp);
      if (x_sgn) ix = -ix;
  }
  return ix;
}

static float sem2float(int x_sgn, int x_man, int x_exp)
{
    int ix;
    float x;

    if (x_man == 0) return (float)0.0;

    if ((unsigned int)x_man > 0x00ffffff)
    {
        while ((unsigned int)x_man > 0x01ffffff)
        {
            x_man = (unsigned int)x_man >> 1;
            x_exp++;
        }

        x_man++; // Add rounding value

        while ((unsigned int)x_man > 0x00ffffff)
        {
            x_man = (unsigned int)x_man >> 1;
            x_exp++;
        }
    }
    else
    {
        while (!(x_man & 0x00800000))
        {
            x_man <<= 1;
            x_exp--;
        }
    }

    x_exp += 150;
    if (x_exp > 254)
    {
        if (x_sgn)
            x = -MAX_FLOAT;
        else
            x = MAX_FLOAT;
    }
    else if (x_exp < 1)
    {
        if (x_sgn)
            x = -MIN_FLOAT;
        else
            x = MIN_FLOAT;
    }
    else
    {
        ix = (x_sgn << 31) | (x_exp << 23) | (x_man & 0x007fffff);
        memcpy(&x, &ix, 4);
    }
    return x;
}

float valexp2float(int value, int exponent)
{
    int signflag;

    if (value < 0)
    {
        signflag = 1;
        if (value != 0x80000000) value = -value;
    }
    else
        signflag = 0;

    return sem2float(signflag, value, exponent);
}

static int fcompare(float x, float y)
{
    int ix, iy, x_sgn, x_exp, x_man, y_sgn, y_exp, y_man, retval;

    memcpy(&ix, &x, 4);
    memcpy(&iy, &y, 4);
    if (ix == iy) return 0;

    x_sgn = (ix >> 31) & 1;
    x_exp = ((ix >> 23) & 255) - 150;
    x_man = (ix & 0x007fffff) | 0x00800000;
    y_sgn = (iy >> 31) & 1;
    y_exp = ((iy >> 23) & 255) - 150;
    y_man = (iy & 0x007fffff) | 0x00800000;

    if (x_sgn && !y_sgn)
        retval = -1;
    else if (!x_sgn && y_sgn)
        retval = 1;
    else if (x_exp < y_exp)
    {
        if (x_sgn)
            retval = 1;
        else
            retval = -1;
    }
    else if (x_exp > y_exp)
    {
        if (x_sgn)
            retval = -1;
        else
            retval = 1;
    }
    else
    {
        if (x_sgn)
            retval = -((y_man < x_man) << 1) + 1;
        else
            retval = -((x_man < y_man) << 1) + 1;
    }
    
    return retval;
}

int __ltsf2(float x, float y)
{
    return fcompare(x, y);
}

int __gtsf2(float x, float y)
{
    return fcompare(x, y);
}

int __lesf2(float x, float y)
{
    return fcompare(x, y);
}

int __gesf2(float x, float y)
{
    return fcompare(x, y);
}

int __nesf2(float x, float y)
{
    return fcompare(x, y);
}

int __eqsf2(float x, float y)
{
    return fcompare(x, y);
}

float __floatsisf(int value)
{
    return valexp2float(value, 0);
}
/*
+-----------------------------------------------------------------------------+
|                       TERMS OF USE: MIT License                             |
+-----------------------------------------------------------------------------+
|Permission is hereby granted, free of charge, to any person obtaining a copy |
|of this software and associated documentation files (the "Software"), to deal|
|in the Software without restriction, including without limitation the rights |
|to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    |
|copies of the Software, and to permit persons to whom the Software is        |
|furnished to do so, subject to the following conditions:                     |
|                                                                             |
|The above copyright notice and this permission notice shall be included in   |
|all copies or substantial portions of the Software.                          |
|                                                                             |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   |
|IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     |
|FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  |
|AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       |
|LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,|
|OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE|
|SOFTWARE.                                                                    |
+-----------------------------------------------------------------------------+
*/
