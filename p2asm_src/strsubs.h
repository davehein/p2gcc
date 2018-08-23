/*
 *
 * Copyright (c) 2018 by Dave Hein
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */
int Tokenize(char *str, char **tokens, int maxnum, char *tokenbuf);
int StrToBin(char *str);
int StrToQuad(char *str);
int StrToHex(char *str);
int StrToDec(char *str);
int StrCompNoCase(char *str1, char *str2);
int SearchList(char **list, char *str);
int SearchDelimiters(char *str);
int CheckForUnicode(FILE *infile);
int ReadString(char *buf, int size, FILE *infile, int unicode);
char *FindChar(char *str, int val);
char *SkipChars(char *str, char *chars);
char *FindChars(char *str, char *chars);
FILE *FileOpen(char *fname, char *mode);
void RemoveCRLF(char *buffer);
