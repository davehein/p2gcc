//{
//   fsrw 2.6 Copyright 2009  Tomas Rokicki and Jonathan Dummer
//
//   See end of file for terms of use.
//
//   This object provides FAT16/32 file read/write access on a block device.
//   Only one file open at a time.  Open modes are 'r' (read), 'a' (append),
//   'w' (write), and 'd' (delete).  Only the root directory is supported.
//   No long filenames are supported.  We also support traversing the
//   root directory.
//
//   In general, negative return values are errors; positive return
//   values are success.  Other than -1 on _popen when the file does not
//   exist, all negative return values will be "aborted" rather than
//   returned.
//
//   Changes:
//       v1.1  28 December 2006  Fixed offset for ctime
//       v1.2  29 December 2006  Made default block driver be fast one
//       v1.3  6 January 2007    Added some docs, and a faster asm
//       v1.4  4 February 2007   Rearranged vars to save memory;
//                               eliminated need for adjacent pins;
//                               reduced idle current consumption; added
//                               sample code with abort code data
//       v1.5  7 April 2007      Fixed problem when directory is larger
//                               than a cluster.
//       v1.6  23 September 2008 Fixed a bug found when mixing _pputc
//                               with pwrite.  Also made the assembly
//                               routines a bit more cautious.
//       v2.1  12 July 2009      FAT32, SDHC, multiblock, bug fixes
//       v2.4  26 September 2009 Added seek support.  Added clustersize.
//       v2.4a   6 October 2009 modified setdate to explicitly set year/month/etc.
//       v2.5  13 November 2009 fixed a bug on releasing the pins, added a "release" pass through function
//       v2.6  11 December 2009: faster transfer hub <=> cog, safe_spi.spin uses 1/2 speed reads, is default
//}
//
//   Constants describing FAT volumes.
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fsrw.h"

#define SECTORSIZE  512
#define SECTORSHIFT   9
#define DIRSIZE      32
#define DIRSHIFT      5

int pclose(void);
int writeblock(int n, char *b);
int readblock(int n, char *b);
int sdspi_start_explicit(int DO, int CLK, int DI, int CS);

//
//
//   Variables concerning the open file.
//
static int fclust;        // the current cluster number
static int filesize;      // the total current size of the file
static int floc;          // the seek position of the file
static int frem;          // how many bytes remain in this cluster from this file
static int bufat;         // where in the buffer our current character is
static int bufend;        // the last valid character (read) or free position (write)
static int direntry;      // the byte address of the directory entry (if open for write)
static int writelink;     // the byte offset of the disk location to store a new cluster
static int fatptr;        // the byte address of the most recently written fat entry
static int firstcluster;  // the first cluster of this file
static char *buf;         // pointer to the data buffer

//
//   Variables used when mounting to describe the FAT layout of the card
//   (moved to the end of the file in the Spin version).
//
static int filesystem;    // 0 = unmounted, 1 = fat16, 2 = fat32
static int rootdir;       // the byte address of the start of the root directory
static int rootdirend;    // the byte immediately following the root directory.
static int dataregion;    // the start of the data region, offset by two sectors
static int clustershift;  // log base 2 of blocks per cluster
static int clustersize;   // total size of cluster in bytes
static int fat1;          // the block address of the fat1 space
static int totclusters;   // how many clusters in the volume
static int sectorsperfat; // how many sectors per fat
static int endofchain;    // end of chain marker (with a 0 at the end)
static int pdate;         // current date

//
//   Variables controlling the caching.
//
static int lastread;     // the block address of the buf2 contents
static int dirty;        // nonzero if buf2 is dirty

//
//  Buffering:  two sector buffers.  These two buffers must be longword
//  aligned!  To ensure this, make sure they are the first byte variables
//  defined in this object.
//
static char buf1[512];   // main data buffer
static char buf2[512];   // main metadata buffer
static char padname[11]; // filename buffer

// Variables used for subdirectories
static int direntry0;
static int rootdir0;
static int rootdirend0;

// Variables used for file handles
static int *curr_handle = 0;
static int handle0[11];

static int minimum(int a, int b)
{
    if (a < b) return a;
    return b;
}

#if 0
static void error(char *s)
{
    printf("%s\n", s);
    exit(10);
}
#endif

static void spinabort(int v)
{
    printf("Spin abort %d\n", v);
    exit(10);
}

//
//   This is just a pass-through function to allow the block layer
//   to tristate the I/O pins to the card.
//
void release()
{
   //SPIN sdspi.release
}

//
//   On metadata writes, if we are updating the FAT region, also update
//   the second FAT region.
//
static void writeblock2(int n, char *b)
{
    writeblock(n, b);
    if (n >= fat1)
        if (n < fat1 + sectorsperfat)
            writeblock(n+sectorsperfat, b);
}

//
//   If the metadata block is dirty, write it out.
//
static void flushifdirty()
{
    if (dirty)
    {
        writeblock2(lastread, buf2);
        dirty = 0;
    }
}

//
//   Read a block into the metadata buffer, if that block is not already
//   there.
//
static void readblockc(int n)
{
    if (n != lastread)
    {
        flushifdirty();
        readblock(n, buf2);
        lastread = n;
    }
}

//
//   Read a byte-reversed word from a (possibly odd) address.
//
static int brword(char *b)
{
   return (b[0] & 255) + ((b[1] & 255) << 8);
}

//
//   Read a byte-reversed long from a (possibly odd) address.
//
static int brlong(char *b)
{
   return brword(b) + (brword(b+2) << 16);
}

//
//   Read a cluster entry.
//
static int brclust(char *b)
{
    if (filesystem == 1)
        return brword(b);
    else
        return brlong(b);
}

//
//   Write a byte-reversed word to a (possibly odd) address, and
//   mark the metadata buffer as dirty.
//
static void brwword(char *w, int v)
{
    *w++ = v;
    *w = v >> 8;
    dirty = 1;
}

//
//   Write a byte-reversed long to a (possibly odd) address, and
//   mark the metadata buffer as dirty.
//
static void brwlong(char *w, int v)
{
    brwword(w, v);
    brwword(w+2, v >> 16);
}

//
//   Write a cluster entry.
static void brwclust(char *w, int v)
{
    if (filesystem == 1)
        brwword(w, v);
    else
        brwlong(w, v);
}

//
//   This may do more complicated stuff later.
//
void unmount(void)
{
    pclose();
    release();
  //SPIN sdspi.stop
}

static int getfstype()
{
    if (!strncmp(buf+0x36, "FAT16", 5)) return 1;
    if (!strncmp(buf+0x52, "FAT32", 5)) return 2;
    return 0;
}

//{
//   Mount a volume.  The address passed in is passed along to the block
//   layer; see the currently used block layer for documentation.  If the
//   volume mounts, a 0 is returned, else abort is called.
//}
int mount_explicit(int DO, int CLK, int DI, int CS)
{
    int r, start, sectorspercluster, reserved, rootentries, sectors;
    r = 0;
    buf = buf1;
    handle0[10] = (int)buf1;
    curr_handle = handle0;
    if (pdate == 0)
        pdate = (((2009-1980) << 25) + (1 << 21) + (27 << 16) + (7 << 11));
    //unmount();
    sdspi_start_explicit(DO, CLK, DI, CS);
    lastread = -1;
    dirty = 0;
    readblock(0, buf);
    readblock(0, buf);
    readblock(0, buf);
    if (getfstype() > 0) {
        start = 0;
    } else {
        start = brlong(buf+0x1c6);
        readblock(start, buf);
    }
    filesystem = getfstype();
    if (filesystem == 0)
         return(-20); // not a fat16 or fat32 volume
         //spinabort(-20); // not a fat16 or fat32 volume
    if (brword(buf+0x0b) != SECTORSIZE)
         return(-21); // bad bytes per sector
         //spinabort(-21); // bad bytes per sector
    sectorspercluster = buf[0x0d];
    if (sectorspercluster & (sectorspercluster - 1))
         return(-22); // bad sectors per cluster
         //spinabort(-22); // bad sectors per cluster
    clustershift = 0;
    while (sectorspercluster > 1) {
         clustershift++;
         sectorspercluster >>= 1;
    }
    sectorspercluster = 1 << clustershift;
    clustersize = SECTORSIZE << clustershift;
    reserved = brword(buf+0x0e);
    if (buf[0x10] != 2)
         return(-23); // not two FATs
         //spinabort(-23); // not two FATs
    sectors = brword(buf+0x13);
    if (sectors == 0)
        sectors = brlong(buf+0x20);
    fat1 = start + reserved;
    if (filesystem == 2) {
         rootentries = 16 << clustershift;
         sectorsperfat = brlong(buf+0x24);
         dataregion = (fat1 + 2 * sectorsperfat) - 2 * sectorspercluster;
         rootdir = (dataregion + (brword(buf+0x2c) << clustershift)) << SECTORSHIFT;
         rootdirend = rootdir + (rootentries << DIRSHIFT);
         endofchain = 0xffffff0;
    } else {
         rootentries = brword(buf+0x11);
         sectorsperfat = brword(buf+0x16);
         rootdir = (fat1 + 2 * sectorsperfat) << SECTORSHIFT;
         rootdirend = rootdir + (rootentries << DIRSHIFT);
         dataregion = 1 + ((rootdirend - 1) >> SECTORSHIFT) - 2 * sectorspercluster;
         endofchain = 0xfff0;
    }
    rootdir0 = rootdir;
    rootdirend0 = rootdirend;
    if (brword(buf+0x1fe) != 0xaa55)
        return(-24); // bad FAT signature
        //spinabort(-24); // bad FAT signature
    totclusters = ((sectors - dataregion + start) >> clustershift);
    return r;
}

//
//   For compatibility, a single pin.
//
int mount(int basepin)
{
    return mount_explicit(basepin, basepin+1, basepin+2, basepin+3);
}

//
//   Read a byte address from the disk through the metadata buffer and
//   return a pointer to that location.
//
static char *readbytec(int byteloc)
{
    readblockc(byteloc >> SECTORSHIFT);
    return buf2 + (byteloc & (SECTORSIZE - 1));
}

//
//   Read a fat location and return a pointer to the location of that
//   entry.
//
static char *readfat(int clust)
{
    fatptr = (fat1 << SECTORSHIFT) + (clust << filesystem);
    return readbytec(fatptr);
}

//
//   Follow the fat chain and update the writelink.
//
static int followchain()
{
    int r;
    r = brclust(readfat(fclust));
    writelink = fatptr;
    return r;
}

//
//   Read the next cluster and return it.  Set up writelink to 
//   point to the cluster we just read, for later updating.  If the
//   cluster number is bad, return a negative number.
//
static int nextcluster()
{
    int r;
    r = followchain();
    if (r < 2 || r >= totclusters)
        spinabort(-9); // bad cluster value
    return r;
}

//
//   Free an entire cluster chain.  Used by remove and by overwrite.
//   Assumes the pointer has already been cleared/set to end of chain.
//
static void freeclusters(int clust)
{
    char *bp;
    while (clust < endofchain) {
        if (clust < 2)
            spinabort(-26); // bad cluster number");
        bp = readfat(clust);
        clust = brclust(bp);
        brwclust(bp, 0);
    }
    flushifdirty();
}

//
//   Calculate the block address of the current data location.
//
static int datablock()
{
    return (fclust << clustershift) + dataregion + ((floc >> SECTORSHIFT) & ((1 << clustershift) - 1));
}

//
//   Compute the upper case version of a character.
//
static int uc(int c)
{
    if ('a' <= c && c <= 'z')
        return c - 32;
    return c;
}

//
//   Flush the current buffer, if we are open for write.  This may
//   allocate a new cluster if needed.  If metadata is true, the
//   metadata is written through to disk including any FAT cluster
//   allocations and also the file size in the directory entry.
//
static int pflushbuf(int rcnt, int metadata)
{
    int cluststart, newcluster, count, i;
    if (direntry == 0)
        spinabort(-27); // not open for writing
    if (rcnt > 0) // must *not* allocate cluster if flushing an empty buffer
    {
        if (frem < SECTORSIZE)
        {
            // find a new cluster; could be anywhere!  If possible, stay on the
            // same page used for the last cluster.
            newcluster = -1;
            cluststart = fclust & (~((SECTORSIZE >> filesystem) - 1));
            count = 2;
            while (1)
            {
                readfat(cluststart);
                for (i=0; i<SECTORSIZE; i+=1<<filesystem)
                    if (buf2[i] == 0)
                    {
                        if (brclust(buf2+i) == 0)
                        {
                            newcluster = cluststart + (i >> filesystem);
                            if (newcluster >= totclusters)
                                newcluster = -1;
                            break;
                        }
                    }
                    if (newcluster > 1)
                    {
                        brwclust(buf2+i, endofchain+0xf);
                        if (writelink == 0)
                        {
                            brwword(readbytec(direntry)+0x1a, newcluster);
                            writelink = (direntry&(SECTORSIZE-filesystem));
                            brwlong(buf2+writelink+0x1c, floc+bufat);
                            if (filesystem == 2)
                            {
                                brwword(buf2+writelink+0x14, newcluster>>16);
                            }
                    }
                    else
                    {
                        brwclust(readbytec(writelink), newcluster);
                    }
                    writelink = fatptr + i;
                    fclust = newcluster;
                    frem = clustersize;
                    break;
                }
                else
                {
                    cluststart += (SECTORSIZE >> filesystem);
                    if (cluststart >= totclusters)
                    {
                        cluststart = 0;
                        count--;
                        if (rcnt < 0)
                        {
                            rcnt = -5; // No space left on device
                            break;
                        }
                    }
                }
            }
        }
        if (frem >= SECTORSIZE)
        {
            writeblock(datablock(), buf);
            if (rcnt == SECTORSIZE) // full buffer, clear it
            {
                floc += rcnt;
                frem -= rcnt;
                bufat = 0;
                bufend = rcnt;
            }
        }
    }
    if (rcnt < 0 || metadata) // update metadata even if error
    {
        readblockc(direntry >> SECTORSHIFT); // flushes unwritten FAT too
        brwlong(buf2+(direntry & (SECTORSIZE-filesystem))+0x1c, floc+bufat);
        flushifdirty();
    }
    if (rcnt < 0)
        spinabort(rcnt);
    return rcnt;
}

//{
//   Call flush with the current data buffer location, and the flush
//   metadata flag set.
//}
int pflush()
{
    return pflushbuf(bufat, 1);
}

//
//   Get some data into an empty buffer.  If no more data is available,
//   return -1.  Otherwise return the number of bytes read into the
//   buffer.
//
static int pfillbuf()
{
    int r;
    r = 0;
    if (floc >= filesize)
        return -1;
    if (frem == 0) {
        fclust = nextcluster();
        frem = minimum(clustersize, filesize - floc);
    }
    readblock(datablock(), buf);
    r = SECTORSIZE;
    if (floc + r >= filesize)
        r = filesize - floc;
    floc += r;
    frem -= r;
    bufat = 0;
    bufend = r;
    return r;
}

//{
//   Flush and close the currently open file if any.  Also reset the
//   pointers to valid values.  If there is no error, 0 will be returned.
//}
int pclose(void)
{
    int r;
    r = 0;
//printf("pclose: direntry = %d\n", direntry);
    if (direntry)
    {
        //printf("pclose: direntry = %x\n", direntry);
        r = pflush();
    }
    bufat = 0;
    bufend = 0;
    filesize = 0;
    floc = 0;
    frem = 0;
    writelink = 0;
    direntry = 0;
    fclust = 0;
    firstcluster = 0;
    //SPIN sdspi.release
    return r;
}

//{
//   Set the current date and time, as a long, in the format
//   required by FAT16.  Various limits are not checked.
//}
void setdate(int year, int month, int day, int hour, int minute, int second)
{
    pdate = ((year-1980) << 25) + (month << 21) + (day << 16);
    pdate += (hour << 11) + (minute << 5) + (second >> 1);
}


static void ConvertName(char *fname1, char *fname2)
{
    int i;

    i = 0;
    while (i < 8 && *fname1 && *fname1 != '.')
        fname2[i++] = uc(*fname1++);
    while (i < 8)
        fname2[i++] = ' ';
    while (*fname1 &&  *fname1 != '.')
        fname1++;
    if (*fname1 == '.')
        fname1++;
    while (i < 11 && *fname1)
        fname2[i++] = uc(*fname1++);
    while (i < 11)
        fname2[i++] = ' ';
}

//{
//   Close any currently open file, and open a new one with the given
//   file name and mode.  Mode can be 'r' 'w' 'a' or 'd' (delete).
//   If the file is opened successfully, 0 will be returned.  If the
//   file did not exist, and the mode was not 'w' or 'a', -1 will be
//   returned.  Otherwise abort will be called with a negative error
//   code.
//}
int popen(char *s, char mode)
{
    int r, i, sentinel, dirptr, freeentry;
//printf("popen: %s %c\n", s, mode);
    r = 0;
//printf("Trace 0\n");
    pclose();
//printf("Trace 0.5\n");
    i = 0;
    while (i<8 && s[0] && s[0] != '.')
    {
        //printf("padname[%d] = %x\n", i, *s);
        padname[i++] = uc(*s++);
    }
    while (i<8)
        padname[i++] = ' ';
    while (s[0] && s[0] != '.')
        s++;
    if (s[0] == '.')
        s++;
    while (i<11 && s[0])
        padname[i++] = uc(*s++);
    while (i < 11)
        padname[i++] = ' ';
    sentinel = 0;
    freeentry = 0;
//printf("padname = %s\n", padname);
//printf("padname = %x, buf2 = %x\n", padname, buf2);
    for (dirptr=rootdir; dirptr<rootdirend; dirptr += DIRSIZE)
    {
        s = readbytec(dirptr);
        if (freeentry == 0 && (s[0] == 0 || s[0] == 0xe5))
            freeentry = dirptr;
        if (s[0] == 0)
        {
            sentinel = dirptr;
            break;
        }
//printf("padname = %s, s = %s\n", padname, s);
        for (i=0; i<11; i++)
            if (padname[i] != s[i])
                break;
        if (i == 11 && 0 == (s[0x0b] & 0x08)) // this always returns
        {
            fclust = brword(s+0x1a);
            if (filesystem == 2)
            {
                fclust += brword(s+0x14) << 16;
            }
            firstcluster = fclust;
            filesize = brlong(s+0x1c);
            if (mode == 'r')
            {
//printf("Trace 1\n");
                frem = minimum(clustersize, filesize);
                direntry0 = dirptr;
                return 0;
            }
            if (s[11] & 0xd9)
                return(-6); // no permission to write
                //spinabort(-6); // no permission to write
            if (mode == 'd')
            {
//printf("About to delete %s\n", padname);
                brwword(s, 0xe5);
                if (fclust)
                    freeclusters(fclust);
//printf("Flush it\n");
                flushifdirty();
                return 0;
            }
            if (mode == 'w')
            {
                brwword(s+0x1a, 0);
                brwword(s+0x14, 0);
                brwlong(s+0x1c, 0);
                writelink = 0;
                direntry = dirptr;
                if (fclust)
                    freeclusters(fclust);
                bufend = SECTORSIZE;
                fclust = 0;
                filesize = 0;
                frem = 0;
//printf("popen w1: bufend = %d\n", bufend);
                return 0;
            }
            else if (mode == 'a')
            {
                // this code will eventually be moved to seek
                frem = filesize;
                freeentry = clustersize;
                if (fclust >= endofchain)
                    fclust = 0;
                while (frem > freeentry)
                {
                    if (fclust < 2)
                        return(-7); // eof while following chain
                        //spinabort(-7); // eof while following chain
                    fclust = nextcluster();
                    frem -= freeentry;
                }
                floc = filesize & (~(SECTORSIZE - 1));
                bufend = SECTORSIZE;
                bufat = frem & (SECTORSIZE - 1);
                writelink = 0;
                direntry = dirptr;
                if (bufat)
                {
                    readblock(datablock(), buf);
                    frem = freeentry - (floc & (freeentry - 1));
                }
                else
                {
                    if (fclust < 2 || frem == freeentry)
                        frem = 0;
                    else
                        frem = freeentry - (floc & (freeentry - 1));
                }
                if (fclust >= 2)
                    followchain();
                return 0;
            }
            else
            {
                return(-3); // bad argument
                //spinabort(-3); // bad argument
            }
        }
    }
    if (mode != 'w' && mode != 'a')
        return -1; // not found
    direntry = freeentry;
    if (direntry == 0)
        return(-2); // no empty directory entry
        //spinabort(-2); // no empty directory entry
    // write (or new append): create valid directory entry
    s = readbytec(direntry);
    memset(s, 0, DIRSIZE);
    memcpy(s, padname, 11);
    brwword(s+0x1a, 0);
    brwword(s+0x14, 0);
    i = pdate;
    brwlong(s+0xe, i); // write create time and date
    brwlong(s+0x16, i); // write last modified date and time
    if (direntry == sentinel && direntry + DIRSIZE < rootdirend)
         brwword(readbytec(direntry+DIRSIZE), 0);
    flushifdirty();
    writelink = 0;
    fclust = 0;
    bufend = SECTORSIZE;
//printf("popen w2: bufend = %d\n", bufend);
    return r;
}

int get_filesize()
{
    return filesize;
}

//{
//   Read count bytes into the buffer ubuf.  Returns the number of bytes
//   successfully read, or a negative number if there is an error.
//   The buffer may be as large as you want.
//}
int pread(char *ubuf, int count)
{
    int r, t;
    r = 0;
    while (count > 0)
    {
        if (bufat >= bufend)
        {
            t = pfillbuf();
            if (t <= 0)
            {
                if (r > 0)
                // parens below prevent this from being optimized out
                return (r);
                return t;
            }
        }
        t = minimum(bufend - bufat, count);
        memcpy(ubuf, buf+bufat, t);
        bufat += t;
        r += t;
        ubuf += t;
        count -= t;
    }
    return r;
}

//{
//   Read and return a single character.  If the end of file is
//   reached, -1 will be returned.  If an error occurs, a negative
//   number will be returned.
//}
int pgetc()
{
    int t;
    if (bufat >= bufend)
    {
        t = pfillbuf();
        if (t <= 0)
            return -1;
    }
    return (buf[bufat++] & 255);
}

//{
//   Write count bytes from the buffer ubuf.  Returns the number of bytes
//   successfully written, or a negative number if there is an error.
//   The buffer may be as large as you want.
//}
int pwrite(char *ubuf, int count)
{
    int r, t;
    r = 0;
//printf("pwrite %d\n", count);
    while (count > 0)
    {
//printf("bufend = %d, bufat = %d\n", bufend, bufat);
        if (bufat >= bufend)
            pflushbuf(bufat, 0);
        t = minimum(bufend - bufat, count);
//printf("bufend = %d, bufat = %d, bufend-bufat = %d, count = %d, t = %d\n", bufend, bufat, bufend-bufat, count, t);
        memcpy(buf+bufat, ubuf, t);
        r += t;
        bufat += t;
        ubuf += t;
        count -= t;
    }
    return r;
}

//{
//   Write a null-terminated string to the file.
//}
int pputs(char *b)
{
    return pwrite(b, strlen(b));
}

//{
//   Write a single character into the file open for write.  Returns
//   0 if successful, or a negative number if some error occurred.
//}
int pputc(int c)
{
    int r;
    r = 0;
    if (bufat == SECTORSIZE)
        if (pflushbuf(SECTORSIZE, 0) < 0)
            return -1;
    buf[bufat++] = c;
    return r;
}

//{
//   Seek.  Right now will only seek within the current cluster.
//   Added for PrEdit so he can debug; do not use with files larger
//   than one cluster (and make that cluster size 32K please.)
//
//   Returns -1 on failure.  Make sure to check this return code!
//
//   We only support reads right now (but writes won't be too hard to
//   add).
//}
int seek(int pos)
{
    int delta;
    if (direntry || pos < 0 || pos > filesize)
        return -1;
    delta = (floc - bufend) & - clustersize;
    if (pos < delta)
    {
        fclust = firstcluster;
        frem = minimum(clustersize, filesize);
        floc = 0;
        bufat = 0;
        bufend = 0;
        delta = 0;
    }
    while (pos >= delta + clustersize)
    {
        fclust = nextcluster();
        floc += clustersize;
        delta += clustersize;
        frem = minimum(clustersize, filesize - floc);
        bufat = 0;
        bufend = 0;
    }
    if (bufend == 0 || pos < floc - bufend || pos >= floc - bufend + SECTORSIZE)
    {
        // must change buffer
        delta = floc + frem;
        floc = pos & - SECTORSIZE;
        frem = delta - floc;
        pfillbuf();
    }
    bufat = pos & (SECTORSIZE - 1);
    return 0;
}

int tell()
{
    return floc + bufat - bufend;
}

//{
//   Close the currently open file, and set up the read buffer for
//   calls to nextfile().
//}
int popendir()
{
    int off;
    pclose();
    off = rootdir - (dataregion << SECTORSHIFT);
    fclust = off >> (clustershift + SECTORSHIFT);
    floc = off - (fclust << (clustershift + SECTORSHIFT));
    frem = rootdirend - rootdir;
    filesize = floc + frem;
    return 0;
}

//{
//   Find the next file in the root directory and extract its
//   (8.3) name into fbuf.  Fbuf must be sized to hold at least
//   13 characters (8 + 1 + 3 + 1).  If there is no next file,
//   -1 will be returned.  If there is, 0 will be returned.
//}
int nextfile(char *fbuf)
{
    int i, t; char *at, *lns;
    while (1)
    {
        if (bufat >= bufend)
        {
            t = pfillbuf();
            if (t < 0)
                return t;
            if (((floc >> SECTORSHIFT) & ((1 << clustershift) - 1)) == 0)
                fclust++;
        }
        at = buf + bufat;
        if (at[0] == 0)
            return -1;
        bufat += DIRSIZE;
        if (at[0] != 0xe5 && (at[0x0b] & 0x08) == 0)
        {
            lns = fbuf;
            for (i=0; i<11; i++)
            {
                fbuf[0] = at[i];
                fbuf++;
                if (at[i] != ' ')
                    lns = fbuf;
                if (i == 7 || i == 10)
                {
                    fbuf = lns;
                    if (i == 7)
                    {
                        fbuf[0] = '.';
                        fbuf++;
                    }
                }
            }
            fbuf[0] = 0;
            return 0;
        }
    }
}

//{
//   Utility routines; may be removed.
//}
int getclustersize()
{
    return clustersize;
}

int getclustercount()
{
    return totclusters;
}
// New routines to provide enhancements to FSRW

// Routine to support file handles

int loadhandle(int *handle)
{
    if (!handle) return 0;

    if (handle != curr_handle)
    {
        if (curr_handle)
        {
//printf("Save curr_handle - %x\n", curr_handle);
            curr_handle[0] = fclust;
            curr_handle[1] = filesize;
            curr_handle[2] = floc;
            curr_handle[3] = frem;
            curr_handle[4] = bufat;
            curr_handle[5] = bufend;
            curr_handle[6] = direntry;
            curr_handle[7] = writelink;
            curr_handle[8] = fatptr;
            curr_handle[9] = firstcluster;
        }
//printf("Load handle - %x\n", handle);
        curr_handle  = handle;
        fclust       = curr_handle[0];
        filesize     = curr_handle[1];
        floc         = curr_handle[2];
        frem         = curr_handle[3];
        bufat        = curr_handle[4];
        bufend       = curr_handle[5];
        direntry     = curr_handle[6];
        writelink    = curr_handle[7];
        fatptr       = curr_handle[8];
        firstcluster = curr_handle[9];
        buf          = (char *)curr_handle[10];
    }

    return 1;
}

void loadhandle0(void)
{
    loadhandle(handle0);
}

// Routines to support subdirectories
static void InitRootDirectory(void)
{
    rootdir = rootdir0;
    rootdirend = rootdirend0;
}

static int InitSubDirectory(char *fname)
{
    char *ptr;
    int retval;

    //printf("InitSubDirectory: %s\n", fname);
    loadhandle(handle0);
    retval = popen(fname, 'r');
    if (retval)
    {
        //printf("InitSubDirectory: failed %d\n", result);
        return retval;
    }
    ptr = readbytec(direntry0) + 11;
    if (!(*ptr & 0x10))
    {
        pclose();
        return -2;
    }
    rootdir = ((fclust << clustershift) + dataregion) << SECTORSHIFT;
    rootdirend = rootdir + 32768;
    pclose();
    return retval;
}

int pchdir(char *path)
{
    int retval;
    char *nextptr;
    retval = 0;

    //printf("chdir: %s\n", path);
    // Check if starting from root directory
    if (*path == '/')
    {
        path++;
        InitRootDirectory();
    }

    // Loop over sub-directory names in path
    while (*path)
    {
        nextptr = path;
        while (*nextptr)
        {
            if (*nextptr++ == '/')
            {
                nextptr[-1] = 0;
                break;
            }
        }
        if ((retval = InitSubDirectory(path)))
            InitRootDirectory();
        if (*nextptr)
            nextptr[-1] = '/';
        if (retval)
            break;
        path = nextptr;
    }
    return retval;
}

int pmkdir(char *fname)
{
    char *ptr;
    int retval;
    char tempbuf[32];

    loadhandle(handle0);
    retval = popen(fname, 'r');
    if (!retval)
    {
        pclose();
        return -1;
    }
    retval = popen(fname, 'w');
    if (retval) return retval;
    ptr = readbytec(direntry) + 11;
    *ptr = 0x30;
    dirty = 1;
    memset(tempbuf, 0, 32);
    pwrite(tempbuf, 32);
    pclose();
    flushifdirty();
    return retval;
}

// Additional routines
void pstat(FatDirEntryT *direntry)
{
    char *ptr = readbytec(direntry0);
    memcpy(direntry, ptr, 32);
}

void pchmod(int modebits)
{
    char *ptr;
    ptr = readbytec(direntry0) + 11;
    *ptr = modebits;
    dirty = 1;
    flushifdirty();
}

int rename(const char *fname1, const char *fname2)
{
    char *ptr;
    int retval;

    //printf("rename %s %s\n", fname1, fname2);
    loadhandle(handle0);
    retval = popen((char *)fname2, 'r');
    if (!retval)
    {
        pclose();
        //printf("Trace 1\n");
        return -2;
    }
    retval = popen((char *)fname1, 'r');
    if (retval)
    {
        //printf("Trace 2\n");
        return retval;
    }
    //printf("Trace 3\n");
    pclose();
    ptr = readbytec(direntry0);
    ConvertName((char *)fname2, ptr);
    dirty = 1;
    flushifdirty();
    return 0;
}

// This routine returns the first sector number
int hget_first_sector(int *handle)
{
    if (!loadhandle(handle)) return -1;
    return (firstcluster << clustershift) + dataregion;
}

int *get_volumeinfo(void)
{
    return &filesystem;
}

int *get_fileinfo(void)
{
    return &fclust;
}

char *hgets(int *handle, char *ubuf, int count)
{
    int val;
    int index;

    if (!loadhandle(handle)) return 0;

    count--;
    index = 0;
    while (index < count)
    {
        if (bufat >= bufend)
        {
            if (pfillbuf() <= 0)
            {
                if (index) break;
                return 0;
            }
        }
        ubuf[index++] = val = buf[bufat++];
        if (val == 10) break;
    }
    ubuf[index] = 0;
    if (index) return ubuf;
    return 0;
}

//{
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files
//  (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of the Software,
//  and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
//}
