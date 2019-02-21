//******************************************************************************
// Copyright (c) 2011-2019, Dave Hein
// See end of file for terms of use.
//******************************************************************************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __P2GCC__
#include <propeller.h>
#endif

//XMODEM chars from ymodem.txt
#define SOH 0x01
#define STX 0x02
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CAN 0x18
#define CEE 0x43  //liberties here
#define ZEE 0x1A  //or SUB  (DOS EOF?)

#define MSG_TIMEOUT  -2
#define MSG_EOT      -3
#define BYTE_TIMEOUT -4
#define MSG_BADNUM   -5
#define MSG_CRCERR   -6

#define p2clkfreq (*(int *)0x14)

int getfilesize(FILE *infile);
void AppendCRC(unsigned char *ptr, int num);
int ComputeCRC(unsigned char *ptr, int num);
int SendPacket(int packetnum, unsigned char *ptr, int num);
int rxtime(int msec);
int SendEOT(void);
int kbhit(void);
int getch(void);
void putch(int val);
void msleep(int ms);
int WaitForC(int msec);

static unsigned char *pdata = 0;

static unsigned short fcstab[] = {
  0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
  0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
  0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
  0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
  0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
  0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
  0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
  0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
  0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
  0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
  0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
  0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
  0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
  0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
  0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
  0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
  0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
  0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
  0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
  0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
  0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
  0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
  0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
  0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
  0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
  0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
  0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
  0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
  0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
  0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
  0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
  0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0};

#ifdef __P2GCC__
int main(int argc, char **argv)
#else
int sendym(int argc, char **argv)
#endif
{
  int filesize, len, packetnum;
  FILE *infile;
  char *str;
  char *fname;

  if (argc != 2)
  {
    printf("usage: sb file\n");
    exit(0);
  }

#ifdef __P2GCC__
  sd_mount(58, 61, 59, 60);
  chdir(argv[argc]);
  start_rx_cog();
#endif

  pdata = malloc(1028);
  if (!pdata)
  {
    printf("Could not malloc 1028 bytes for the data buffer\n");
    exit(1);
  }
  fname = argv[1];
  infile = fopen(fname, "rb");
  if (!infile)
  {
    printf("Could not open %s\n", fname);
    free(pdata);
    exit(1);
  }
  filesize = getfilesize(infile);
printf("filesize = %d\n", filesize);
  memset(pdata, 0, 130);
  pdata[1] = 255;
  str = (char *)pdata + 2;
  len = strlen(fname) + 1;
  memcpy(str, fname, len);
  str += len;
  sprintf(str, "%d", filesize);
  if (!WaitForC(20000))
  {
    fclose(infile);
    free(pdata);
    exit(0);
  }
#if 0
  while (1)
  {
    val = rxtime(20000);
    if (val == -1 || val == 27)
    {
printf("Timed out\n");
      fclose(infile);
      free(pdata);
      exit(0);
    }
printf("val = 0x%x\n", val);
    if (val == CEE)
      break;
  }
#endif

printf("Sending first packet\n");
  SendPacket(0, pdata, 128);

  if (!WaitForC(10000))
  {
    fclose(infile);
    free(pdata);
    exit(0);
  }
#if 0
  while (1)
  {      
    val = rxtime(10000);
    if (val == -1 || val == 27)
    {
printf("Timed out\n");
      fclose(infile);
      free(pdata);
      exit(0);
    }
printf("val = 0x%x\n", val);
    if (val == CEE)
      break;
  }
#endif

printf("Sending file\n");
  packetnum = 1;
  while (filesize > 0)
  {
    len = filesize;
#if 1
    if (len > 1024)
      len = 1024;
#else
    if (len > 128)
      len = 128;
#endif
    filesize -= len;
    fread(pdata + 2, 1, len, infile);
    SendPacket(packetnum, pdata, len);
    packetnum++;
  }

printf("Sending EOT\n");
  SendEOT();
  if (!WaitForC(10000))
  {
    fclose(infile);
    free(pdata);
    exit(0);
  }
  pdata[2] = 0;
  memset(pdata, 0, 128);
printf("Sending last packet\n");
  SendPacket(0, pdata, 128);

  fclose(infile);
  free(pdata);
  return 0;
}

#ifdef __P2GCC__
int rxtime(int msec)
{
  int cycles, cycles0, elapsed;

  cycles = msec * (p2clkfreq/1000);
  cycles0 = CNT;
  while (1)
  {
    elapsed = CNT - cycles0;
    if (elapsed > cycles)
      return -1;
    if (kbhit())
      return getch();
  }
}
#endif

int SendEOT(void)
{
  int val;

  while (1)
  {
    putch(EOT);
    while (1)
    {
      val = rxtime(10000);
      if (val == ACK)
      {
        printf("Received ACK\n");
        return 1;
      }
      else if (val == NAK)
      {
        printf("Received ACK\n");
        break;
      }
    }
  }

  return 0;
}

#ifndef __P2GCC__
void putblock(unsigned char *ptr, int num)
{
    while (num-- > 0)
    {
        putch(*ptr++);
    }
}
#endif

int SendPacket(int packetnum, unsigned char *ptr, int num)
{
  int val, firstchar;

  msleep(10);
printf("SendPacket: %d, %d\n", packetnum, num);
  if ((num <= 0) || (num > 1024))
    return 0;
  else if (num <= 128)
  {
    num = 128;
    firstchar = SOH;
  }
  else
  {
    num = 1024;
    firstchar = STX;
  }
  ptr[0] = packetnum;
  ptr[1] = 255 - packetnum;
  AppendCRC(ptr+2, num);
  while (1)
  {
//printf("SendPacket: sending firstchar = 0x%x\n", firstchar);
    putch(firstchar);
//printf("Sending block\n");
#ifdef __P2GCC__
    fwrite(ptr, 1, num + 4, stdout);
#else
    putblock(ptr, num + 4);
#endif
    while (1)
    {
printf("Waiting for ACK\n");
      val = rxtime(10000);
      if (val == ACK)
      {
        printf("Received ACK\n");
        return num;
      }
      else if (val == NAK)
      {
        printf("Received NAK\n");
        break;
      }
      else
        printf("Received %d\n", val);
    }
  }
  return num;
}

int ComputeCRC(unsigned char *ptr, int num)
{
  int result = 0;

  while (num-- > 0)
    result = ((result << 8) & 0xffff) ^ fcstab[(result >> 8) ^ *ptr++];

  return result;
}

void AppendCRC(unsigned char *ptr, int num)
{
  int crc = ComputeCRC(ptr, num);

  ptr[num] = crc >> 8;
  ptr[num+1] = crc & 0xff;
}

int getfilesize(FILE *infile)
{
  int len;

  fseek(infile, 0, SEEK_END);
  len = ftell(infile);
  fseek(infile, 0, SEEK_SET);

  return len;
}

int WaitForC(int msec)
{
  int val;

#if 0
  while (1)
  {
    val = rxtime(20000);
    if (val == -1 || val == 27)
    {
printf("Timed out\n");
      fclose(infile);
      free(pdata);
      exit(0);
    }
    if (val == CEE)
      break;
  }
#else
  printf("Waiting for CEE\n");
  val = rxtime(msec);
  if (val == CEE)
  {
    printf("Received CEE\n");
    return 1;
  }
  printf("Received 0x%x, expected CEE\n", val);
  return 0;
#endif
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
