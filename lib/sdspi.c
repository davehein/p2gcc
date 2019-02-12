//  sdspi:  SPI interface to a Secure Digital card.
//
//  Copyright 2008   Radical Eye Software
//
//  See end of file for terms of use.
//
//  This version is in Spin so it is very slow (3Kb/sec).
//  A version in assembly is about 100x faster.
//
//  You probably never want to call this; you want to use fswr
//  instead (which calls this); this is only the lowest layer.
//
//  Assumes SD card is interfaced using four consecutive Propeller
//  pins, as follows (assuming the base pin is pin 0):
//
//  The 150 ohm resistors are current limiters and are only
//  needed if you don't trust your code (and don't want an SD
//  driven signal to conflict with a Propeller driven signal).
//  A value of 150 should be okay, unless you've got some
//  unusually high capacitance on the line.  The 20k resistors
//  are pullups, and should be there on all six lines (even
//  the ones we don't drive).
//
//  This code is not general-purpose SPI code; it's very specific
//  to reading SD cards, although it can be used as an example.
//
//  The code does not use CRC at the moment (this is the default).
//  With some additional effort we can probe the card to see if it
//  supports CRC, and if so, turn it on.   
//
//  All operations are guarded by a watchdog timer, just in case
//  no card is plugged in or something else is wrong.  If an
//  operation does not complete in one second it is aborted.
//
#include <stdio.h>
#include <stdlib.h>
#include <propeller.h>

#define send(x) spi_send(x, clk_pin, di_pin)
#define read() spi_read(clk_pin, do_pin)

int spi_read(int cpin, int dpin);
void spi_send(int val, int cpin, int dpin);

int di_pin, do_pin, clk_pin, cs_pin, starttime;
int di_mask, do_mask, clk_mask, cs_mask;
int aflag;
int sdhc = 0;

void errorexit(int val)
{
    printf("errorexit: %d\n", val);
    exit(1);
}

int sdspi_getcnt(void)
{
    return CNT;
}

void release(void)
{
    if (aflag)
    {
        OUTA |= clk_mask | di_mask | cs_mask;
        DIRA &= ~(clk_mask | di_mask | cs_mask);
    }
    else
    {
        OUTB |= clk_mask | di_mask | cs_mask;
        DIRB &= ~(clk_mask | di_mask | cs_mask);
    }
}

#if 0
//
//  Send eight bits, then raise di.
//
void senda(int outv)
{
    int i;

    for (i = 0; i < 8; i++)
    {
        OUTA &= ~clk_mask;
        if (outv & 0x80)
            OUTA |= di_mask;
        else
            OUTA &= ~di_mask;
        outv <<= 1;
        OUTA |= clk_mask;
    }

    OUTA |= di_mask;
}

void sendb(int outv)
{
    int i;

    for (i = 0; i < 8; i++)
    {
        OUTB &= ~clk_mask;
        if (outv & 0x80)
            OUTB |= di_mask;
        else
            OUTB &= ~di_mask;
        outv <<= 1;
        OUTB |= clk_mask;
    }

    OUTB |= di_mask;
}

void send(int outv)
{
    if (aflag)
        senda(outv);
    else
        sendb(outv);
}
#endif

//
//  Did we go over our time limit yet?
//
void checktime(void)
{
    if (sdspi_getcnt() - starttime > 50000000)
        errorexit(-41); // Timeout during read
}

#if 0
static void __attribute__ ((noinline)) sdspi_delay(int cycles)
{
    __asm__("waitx r0");
}

//
//  Read eight bits from the card.
//
int reada(void)
{
    int i, r;

    r = 0;
    for (i = 0; i < 8; i++)
    {
        OUTA &= ~clk_mask;
        OUTA |= clk_mask;
        sdspi_delay(2);
        r <<= 1;
        if (INA & do_mask)
            r |= 1;
    }
    return r;
}

int readb(void)
{
    int i, r;

    r = 0;
    for (i = 0; i < 8; i++)
    {
        OUTB &= ~clk_mask;
        OUTB |= clk_mask;
        sdspi_delay(2);
        r <<= 1;
        if (INB & do_mask)
            r |= 1;
    }
    return r;
}

int read(void)
{
    int retval;

    if (aflag)
        retval = reada();
    else
        retval = readb();

    return retval;
}
#endif

//
//  Read eight bits, and loop until we
//  get something other than $ff.
//
int readresp(void)
{
    int r;

    while (1)
    {
        r = read();
        if (r != 0xff) break;
        checktime();
    }

    return r;
}

    
//
//  Wait until card stops returning busy
//
int busy(void)
{
    int r;

    while (1)
    {
        r = read();
        if (r) break;
        checktime();
    }

    return r;
}

//
//  Send a full command sequence, and get and
//  return the response.  We make sure cs is low,
//  send the required eight clocks, then the
//  command and parameter, and then the CRC for
//  the only command that needs one (the first one).
//  Finally we spin until we get a result.
//
int cmd(int op, int parm)
{
    if (aflag)
        OUTA &= ~cs_mask;
    else
        OUTB &= ~cs_mask;
    read();
    send(0x40+op);
    send(parm >> 24);
    send(parm >> 16);
    send(parm >> 8);
    send(parm << 0);
    if (op == 0)
        send(0x95);
    else
        send(0x87);
    return readresp();
}

//
//  Deselect the card to terminate a command.
//
int endcmd(void)
{
    if (aflag)
        OUTA |= cs_mask;
    else
        OUTB |= cs_mask;
    return 0;
}

//
//  Initialize the card!  Send a whole bunch of
//  clocks (in case the previous program crashed
//  in the middle of a read command or something),
//  then a reset command, and then wait until the
//  card goes idle.  If you want to change this
//  method to make the pins not be adjacent, all you
//  need to do is change these first four lines.
//
int sdspi_start_explicit(int DO, int CLK, int DI, int CS)
{
    int i;

    do_pin  = DO;
    clk_pin = CLK;
    di_pin  = DI;
    cs_pin  = CS;

    if (DO < 32)
    {
        aflag = 1;
        do_mask  = 1 << do_pin;
        clk_mask = 1 << clk_pin;
        di_mask  = 1 << di_pin;
        cs_mask  = 1 << cs_pin;
        OUTA |= clk_mask | di_mask | cs_mask;
        DIRA |= clk_mask | di_mask | cs_mask;
    }
    else
    {
        aflag = 0;
        do_mask  = 1 << (do_pin - 32);
        clk_mask = 1 << (clk_pin - 32);
        di_mask  = 1 << (di_pin - 32);
        cs_mask  = 1 << (cs_pin - 32);
        OUTB |= clk_mask | di_mask | cs_mask;
        DIRB |= clk_mask | di_mask | cs_mask;
    }

    starttime = sdspi_getcnt();
    for (i = 0; i < 600; i++) read();

    i = cmd(0, 0);
    endcmd();

    i = cmd(8, 0x1aa);
    endcmd();

    while (1)
    {
        cmd(55, 0);
        i = cmd(41, 0x40000000);
        if (i == 0) break;
    }

    i = cmd(58, 0);
    sdhc = (read() >> 6) & 1;
    endcmd();

    if (i)
       errorexit(-40); // could not initialize card

    return 0;
}

int sdspi_start(basepin)
{
    return sdspi_start_explicit(basepin, basepin+1, basepin+2, basepin+3);
}

//
//  Read a single block.  The "n" passed in is the
//  block number (blocks are 512 bytes); the b passed
//  in is the address of 512 blocks to fill with the
//  data.
//
int readblock(int n, char *b)
{
    int i;

    starttime = sdspi_getcnt();
    if (!sdhc) n <<= 9;
    cmd(17, n);
    readresp();
    for (i = 0; i < 512; i++)
        *b++ = read();
    read();
    read();
    return endcmd();
}

//
//  Read the CSD register.  Passed in is a 16-byte
//  buffer.
//
int getCSD(char *b)
{
    int i;

    starttime = sdspi_getcnt();
    cmd(9, 0);
    readresp();
    for (i = 0; i < 16; i++)
        *b++ = read();
    read();
    read();
    return endcmd();
}

//
//  Write a single block.  Mirrors the read above.
//
int writeblock(int n, char *b)
{
    int i;

    starttime = sdspi_getcnt();
    if (!sdhc) n <<= 9;
    cmd(24, n);
    send(0xfe);
    for (i = 0; i < 512; i++)
        send(*b++);
    read();
    read();
    if ((readresp() & 0x1f) != 5)
        errorexit(-42);
    busy();
    return endcmd();
}

//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
