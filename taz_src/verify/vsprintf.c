//
// This routines generates a formatted output string based on the string pointed
// to by "format".  The parameter "arglist" is a pointer to a long array of values
// that are merged into the output string.  The characters in the format string
// are copied to the output string, exept for special character sequences that
// start with %.  The % character is used to merge values from "arglist".  The
// characters following the % are as follows: %[0][width][.digits][l][type].
// If a "0" immediately follows the % it indicates that leading zeros should be
// displayed.  The optional "width" paramter specifieds the minimum width of the
// field.  The optional ".digits" parameter specifies the number of fractional
// digits for floating point, or it may also be used to specify leading zeros and
// the minimum width for integer values.  The "l" parameter indicates long values,
// and it is ignored in this implementation.  The "type" parameter is a single
// character that indicates the type of output that should be generated.  It can
// be one of the following characters:
//
// d - signed decimal number
// i - same as d
// u - unsigned decimal number
// x - hexidecimal number
// o - octal number
// b - binary number
// c - character
// s - string
// e - floating-point number using scientific notation
// f - floating-point number in standard notation
// % - prints the % character
//
// Note, care must be taken the the generated output string does not exceed the size
// of the string.  A string size of 200 bytes is normally more than sufficient.  
//
void vsprintf(char *str, char *fmtstr, int *arglist)
{
    int arg, width, digits, val;
    char *fmtstr0;

    arg = *arglist++;
    while (*fmtstr)
    {
        if (*fmtstr == '%')
        {
            fmtstr0 = fmtstr + 1;
            if (*fmtstr0 == '0')
            {
                width = -1;
                digits = getvalue(&fmtstr0);
            }
            else
            {
                width = getvalue(&fmtstr0);
                if (*fmtstr0 == '.')
                {
                    fmtstr0++;
                    digits = getvalue(&fmtstr0);
                }
                else
                    digits = -1;
            }
            if (*fmtstr0 == 'l')
                fmtstr0++;
            val = *fmtstr0;
            if (val == 'd' || val == 'i')
                str = putdecstr(str, arg, width, digits);
            else if (val == 'u')
                str = putudecstr(str, arg, width, digits);
            else if (val == 'o')
                str = putoctalstr(str, arg, width, digits);
            else if (val == 'b')
                str = putbinarystr(str, arg, width, digits);
            else if (val == 'x')
                str = puthexstr(str, arg, width, digits);
            else if (val == 'c')
                *str++ = arg;
            else if (val == '%')
                *str++ = '%';
            else if (val == 's')
            {
                strcpy(str, arg);
                str += strlen(arg);
            }
            else
            {
                *str++ = '%';
                continue;
            }
            fmtstr = fmtstr0 + 1;
            arg = *arglist++;
        }
        else
            *str++ = *fmtstr++;
    }
    *str = 0;
}

//
// This private routine is used to convert a signed integer contained in
// "number" to a decimal character string.  It is called by itoa when the
// numeric base parameter has a value of 10.
//
int itoa10(int number, char *str)
{
    char *str0;
    int divisor, temp;

    str0 = str;
    if (number < 0)
    {
        *str++ = '-';
        if (number == 0x80000000)
        {
            *str++ = '2';
            number += 2000000000;
        }
        number = -number;
    }
    else if (number == 0)
    {
        *str++ = '0';
        *str = 0;
        return 1;
    }
    divisor = 1000000000;
    while (divisor > number)
      divisor /= 10;
    while (divisor > 0)
    {
        temp = number / divisor;
        *str++ = temp + '0';
        number -= temp * divisor;
        divisor /= 10;
    }
    *str++ = 0;
    return (str - str0 - 1);
}

//
// This private routine is used to extract the width and digits
// fields from a format string.  It is called by vsprintf.
//
int getvalue(char **pstr)
{
    int val;
    char *str;
    str = *pstr;
    if (!isdigit(*str)) return -1;
    val = 0;
    while (isdigit(*str))
        val = (val * 10) + *str++ - '0';
    *pstr = str;
    return val;
}

//
// This private routine is used to generate a formatted string
// containg at least "width" characters.  The value of count
// must be identical to the length of the string in "str".
// Leading spaces will be generated if width is larger than the
// maximum of count and digits.  Leading zeros will be generated
// if digits is greater than count.
//
char *printpadded(char *str, char *numstr, int count, int width, int digits)
{
    if (digits < count) digits = count;
    while (width-- > digits) *str++ = ' ';
    if (*numstr == '-')
    {
        *str++ = *numstr++;
        digits--;
    }
    while (digits-- > count) *str++ = '0';
    strcpy(str, numstr);
    return str + strlen(numstr);
}

//
// This private routine converts a number to a string of binary digits.
// printpadded is called to insert leading blanks and zeros.
//
char *putbinarystr(char *str, int number, int width, int digits)
{
    int count;
    char numstr[36];

    count = itoa(number, numstr, 2);
    return printpadded(str, numstr, count, width, digits);
}

//
// This private routine converts a number to a string of octal digits.
// printpadded is called to insert leading blanks and zeros.
//
char *putoctalstr(char *str, int number, int width, int digits)
{
    int count;
    char numstr[12];

    count = itoa(number, numstr, 8);
    return printpadded(str, numstr, count, width, digits);
}

//
// This private routine converts a number to a string of hexadecimal digits.
// printpadded is called to insert leading blanks and zeros.
//
char *puthexstr(char *str, int number, int width, int digits)
{
    int count;
    char numstr[12];

    count = itoa(number, numstr, 16);
    return printpadded(str, numstr, count, width, digits);
}
   
//
// This private routine converts a signed number to a string of decimal
// digits.  printpadded is called to insert leading blanks and zeros.
//
char *putdecstr(char *str, int number, int width, int digits)
{
    int count;
    char numstr[12];

    count = itoa10(number, numstr);
    return printpadded(str, numstr, count, width, digits);
}

//
// This private routine converts an unsigned number to a string of decimal
// digits.  printpadded is called to insert leading blanks and zeros.
//
char *putudecstr(char *str, int number, int width, int digits)
{
    int count;
    char numstr[12];
    int adjust;

    adjust = 0;
    while (number < 0)
    {
        number -= 1000000000;
        adjust++;
    }
    count = itoa10(number, numstr);
    *numstr += adjust;
    return printpadded(str, numstr, count, width, digits);
}

//
// This routine return true if the value of "char" represents an ASCII decimal
// digit between 0 and 9.  Otherwise, it returns false.
//
int isdigit(int val)
{
  return (val >= '0') & (val <= '9');
}

//
// This routine converts the 32-bit value in "number" to an ASCII string at the
// location pointed to by "str".  The numeric base is determined by the value
// of "base", and must be either 2, 4, 8, 10 or 16.  Leading zeros are suppressed,
// and the number is treated as unsigned except when the base is 10.  The length
// of the resulting string is returned.
//
int itoa(int number, char *str, int base)
{
    int mask, shift, nbits;
    char *str0;
    char *HexDigit;

    if (base == 10) return itoa10(number, str);

    if (base == 2) nbits = 1;
    else if (base == 4) nbits = 2;
    else if (base == 8) nbits = 3;
    else if (base == 16) nbits = 4;
    else
    {
        *str = 0;
        return 0;
    }

    str0 = str;
    mask = base - 1;
    HexDigit = "0123456789abcdef";
    if (nbits == 3) shift = 30;
    else            shift = 32 - nbits;

    while (shift > 0 && ((number >> shift) & mask) == 0)
        shift -= nbits;

    while (shift >= 0)
    {
        *str++ = HexDigit[(number >> shift) & mask];
        shift -= nbits;
    }

    *str = 0;
    return (str - str0);
}
