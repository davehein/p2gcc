//******************************************************************************
// Copyright (c) 2019 Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdint.h>
#include <string.h>
#include <complex.h>

#define MAX_FLOAT (3.402e+38)
#define MIN_FLOAT (2.351e-38)

float valexp2float(int value, int exponent);

int __attribute__((noinline)) qvectorangle(int x, int y)
{
    __asm__("qvector r0, r1");
    __asm__("getqy r0");
    return x; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qexponent(int value)
{
    __asm__("qexp r0");
    __asm__("getqx r0");
    return value; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qlogarithm(int value)
{
    __asm__("qlog r0");
    __asm__("getqx r0");
    return value; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qsquareroot(int value)
{
    __asm__("qsqrt #0, r0");
    __asm__("getqx r0");
    return value; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qsine(int angle)
{
    __asm__("qrotate ##0x10000000, r0");
    __asm__("getqy r0");
    return angle; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qcosine(int angle)
{
    __asm__("qrotate ##0x10000000, r0");
    __asm__("getqx r0");
    return angle; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) qtangent(int angle)
{
    __asm__("qrotate ##0x10000000, r0");
    __asm__("getqy r0");
    __asm__("getqx r1");
    __asm__("mov r2, r0");
    __asm__("sar r2, #4");
    __asm__("shl r0, #28");
    __asm__("setq r2");
    __asm__("qdiv r0, r1");
    __asm__("getqx r0");
    return angle; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) ilog(int x)
{
    __asm__("qlog r0");
    __asm__("getqx r0");
    return x; // This is optimized away.  Eliminates warning message.
}

int __attribute__((noinline)) ialog(int x)
{
    __asm__("qexp r0");
    __asm__("getqx r0");
    return x; // This is optimized away.  Eliminates warning message.
}

double sin(double x)
{
  int x_sgn, x_exp, x_man, ix;

  if (x == 0.0) return 0.0;

  x /= 2.0 * 3.1415926;
  memcpy(&ix, &x, 4);

  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  x_exp += 32;

  if (x_exp >= 0)
      x_man <<= x_exp;
  else
      x_man >>= -x_exp;
  x_man = qsine(x_man);
  if (x_sgn) x_man = -x_man;
  return valexp2float(x_man, -28);
}

double cos(double x)
{
  int x_exp, x_man, ix;

  if (x == 0.0) return 1.0;

  x /= 2.0 * 3.1415926;
  memcpy(&ix, &x, 4);
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  x_exp += 32;

  if (x_exp >= 0)
      x_man <<= x_exp;
  else
      x_man >>= -x_exp;

  x_man = qcosine(x_man);
  return valexp2float(x_man, -28);
}

float _sin_(float x)
{
  int x_sgn, x_exp, x_man, ix;

  if (x == 0.0) return 0.0;

  x /= 2.0 * 3.1415926;
  memcpy(&ix, &x, 4);

  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  x_exp += 32;

  if (x_exp >= 0)
      x_man <<= x_exp;
  else
      x_man >>= -x_exp;

  x_man = qsine(x_man);
  if (x_sgn) x_man = -x_man;
  return valexp2float(x_man, -28);
}

float _cos_(float x)
{
  int x_exp, x_man, ix;

  if (x == 0.0) return 1.0;

  x /= 2.0 * 3.1415926;
  memcpy(&ix, &x, 4);
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  x_exp += 32;

  if (x_exp >= 0)
      x_man <<= x_exp;
  else
      x_man >>= -x_exp;
  x_man = qcosine(x_man);
  return valexp2float(x_man, -28);
}

double tan(double x)
{
  float y;
  int x_sgn, x_exp, x_man, ix;

  if (x == 0.0) return 0.0;

  x /= 2.0 * 3.1415926;
  memcpy(&ix, &x, 4);
  x_sgn = (ix >> 31) & 1;
  x_exp = ((ix >> 23) & 255) - 150;
  x_man = (ix & 0x007fffff) | 0x00800000;

  x_man <<= (32 + x_exp);
  x = valexp2float(qsine(x_man), -28);
  if (x_sgn) x = -x;
  y = valexp2float(qcosine(x_man), -28);
  return x/y;
}

double sqrt(double x)
{
    int ix, x_exp, x_man;

    memcpy(&ix, &x, 4);
    x_exp = ((ix >> 23) & 255) - 150;
    x_man = (ix & 0x007fffff) | 0x00800000;
    x_man <<= 5;
    x_exp -= 5;
    x_exp -= 32;

    if (x_exp & 1)
    {
        x_man <<= 1;
        x_exp--;
    }

    x_man = qsquareroot(x_man);
    x_exp >>= 1;
    return valexp2float(x_man, x_exp);
}

double log2(double x)
{
    int ix, x_exp, x_man;

    memcpy(&ix, &x, 4);
    x_exp = ((ix >> 23) & 255) - 150;
    x_man = (ix & 0x007fffff) | 0x00800000;
    x_man = qlogarithm(x_man);
    x_man = (unsigned int)x_man >> 4;
    x_man += x_exp << 23;
    return valexp2float(x_man, -23);
}

double pow(double x, double y)
{
    int iy, y_sgn, y_exp, y_man;
    int intval;
    int shift, adjust;

    y *= log2(x);

    if (y >  127.9) return 3.402e+38;
    if (y < -124.4) return 2.351e-38;

    memcpy(&iy, &y, 4);
    if (iy == 0) return 1.0;
    y_sgn = (iy >> 31) & 1;
    y_exp = ((iy >> 23) & 255) - 150;
    y_man = (iy & 0x007fffff) | 0x00800000;
    if (y_exp < -30)
        intval = 0;
    else
        intval = y_man >> -y_exp;
    adjust = 30 - intval;
    shift = 27 + y_exp;
    if (y_exp < -30)
    {
        y_man += adjust << 27;
    }
    else
    {
        y_man += adjust << -y_exp;
    }
    if (shift >= 0)
        y_man <<= shift;
    else
        y_man >>= -shift;
    y_exp = adjust;
    y_man = qexponent(y_man);
    x = valexp2float(y_man, -y_exp);
    if (y_sgn) x = 1.0 / x;
    return x;
}

double exp(double x)
{
    return pow(2.718281828459, x);
}

double asin(double value1)
{
    int iangle;
    float x, y, angle, value2;

    value2 = sqrt(1.0 - value1 * value1);

    x = 1000000.0 * value2;
    y = 1000000.0 * value1;
    iangle = qvectorangle((int)x, (int)y);
    iangle = (unsigned int)iangle >> 1;
    angle = valexp2float(iangle, -31);
    angle = angle * 2.0 * 3.1415926;
    if (angle > 3.1415926) angle -= 2.0 * 3.1415926;
    return angle;
}

double atan2(double y, double x)
{
    int iangle;
    float angle;
    int x_sgn = 0;
    int y_sgn = 0;

    if (x < 0.0)
    {
        x_sgn = 1;
        x = -x;
    }

    if (y < 0.0)
    {
        y_sgn = 1;
        y = -y;
    }

    if (y > x)
    {
        x = 1000000.0 * x / y;
        y = 1000000.0;
    }
    else
    {
        y = 1000000.0 * y / x;
        x = 1000000.0;
    }

    if (x_sgn) x = -x;
    if (y_sgn) y = -y;

    iangle = qvectorangle((int)x, (int)y);
    iangle = (unsigned int)iangle >> 1;
    angle = valexp2float(iangle, -31);
    angle = angle * 2.0 * 3.1415926;
    if (angle > 3.1415926) angle -= 2.0 * 3.1415926;
    return angle;
}

double complex cexp(double complex z)
{
    double a[2], b;

    a[1] = 0.0; // Needed to avoid compiler warning message

    memcpy(a, &z, 8);

    if (a[0] == 0)
        b = 1.0;
    else
        b = exp(a[0]);
    a[0] = b * _cos_(a[1]);
    a[1] = b * _sin_(a[1]);
    memcpy(&z, a, 8);

    return z;
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
