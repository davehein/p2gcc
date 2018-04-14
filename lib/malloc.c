//'******************************************************************************
//' C malloc functions
//' Copyright (c) 2010-2015 Dave Hein
//' See end of file for terms of use.
//'******************************************************************************
#include <stdlib.h>

#define NEXT 0
#define SIZE 1
#define BUFF 2

static void trimfreelist(void);
static void meminsert(int *currblk);
static void AddToMallocList(int *newblk);

int *memfreelist = 0;
int *malloclist = 0;
char *heapaddr = 0;
char *heapaddrlast = 0;

#if 0
void mallocinit(char *addr)
{
    malloclist = 0;
    memfreelist = 0;
    heapaddr = addr;
    heapaddrlast = addr;
}
#endif

void *malloc(size_t size)
{
    int size1;
    int *prevblk;
    int *currblk;
    int stackptr;

    // Return 0 if size less than 1
    if (size < 1) return 0;

    // Adjust size to nearest int plus the header size
    size = ((size + 3) & (~3)) + 8;
    size1 = size >> 2;

    // Attempt to allocate from the free list
    prevblk = 0;
    currblk = memfreelist;
    while (currblk)
    {
        if (currblk[SIZE] >= size)
        {
            // Split block if it's big enough
            if (currblk[SIZE] >= size + 12)
            {
                currblk[size1] = currblk[NEXT];
                currblk[size1+1] = currblk[SIZE] - size;
                currblk[NEXT] = (int)&currblk[size1];
                currblk[SIZE] = size;
            }
            // Remove block from free list
            if (prevblk)
                prevblk[NEXT] = currblk[NEXT];
            else
                memfreelist = (int *)currblk[NEXT];
            AddToMallocList(currblk);
            return &currblk[BUFF];
        }
        prevblk = currblk;
        currblk = (int *)currblk[NEXT];
    }

    // Attempt to allocate heapaddrlast
    stackptr = (int)&stackptr;
    if (stackptr - (int)heapaddrlast < size + 100) return 0;
    currblk = (int *)heapaddrlast;
    currblk[NEXT] = 0;
    currblk[SIZE] = size;
    AddToMallocList(currblk);
    heapaddrlast += size;
    return &currblk[BUFF];
}

// Allocate a memory block of num*size bytes and initialize to zero.  Return
// a pointer to the memory block if successful, or zero if a large enough
// memory block could not be found.
void *calloc(size_t num, size_t size)
{
    char *ptr;
    int *ptr1;
    size *= num;
    ptr = malloc(size);
    if (ptr)
    {
        ptr1 = (int *)ptr;
        size = (size + 3) >> 2;
        while (size--) *ptr1++ = 0;
    }
    return ptr;
}

// Return the memory block at "ptr" to the free list.  Return a value of one
// if successful, or zero if the memory block was not on the allocate list.
void free(void *ptr)
{
    int *prevblk;
    int *currblk;
    int *nextblk;
    int *iptr = ptr;

    prevblk = 0;
    nextblk = malloclist;
    currblk = &iptr[-2];

    // Search the malloclist for the currblk pointer
    while (nextblk)
    {
        if (currblk == nextblk)
        {
            // Remove from the malloc list
            if (prevblk)
                prevblk[NEXT] = nextblk[NEXT];
            else
                malloclist = (int *)nextblk[NEXT];
            // Add to the free list
            meminsert(nextblk);
            trimfreelist();
            return;
        }
        prevblk = nextblk;
        nextblk = (int *)nextblk[NEXT];
    }
}

static void AddToMallocList(int *newblk)
{
    int *currblk;

    newblk[NEXT] = 0;
    if (malloclist)
    {
        currblk = malloclist;
        while (currblk[NEXT]) currblk = (int *)currblk[NEXT];
        currblk[NEXT] = (int)newblk;
    }
    else
        malloclist = newblk;
}

static void trimfreelist(void)
{
    int *currblk;
    int *prevblk;
    int ival;

    if (!memfreelist) return;

    prevblk = 0;
    currblk = memfreelist;
    while (currblk[NEXT])
    {
        prevblk = currblk;
        currblk = (int *)currblk[NEXT];
    }
    ival = (int)currblk;
    if (ival + (int)currblk[SIZE] == (int)heapaddrlast)
    {
        heapaddrlast = (char *)currblk;
        if (prevblk)
            prevblk[NEXT] = 0;
        else
            memfreelist = 0;
    }
}

// Insert a memory block back into the free list.  Merge blocks together if
// the memory block is contiguous with other blocks on the list.
static void meminsert(int *currblk)
{
    int icurrblk;
    int iprevblk;
    int *prevblk;
    int *nextblk;

    prevblk = 0;
    nextblk = memfreelist;
    icurrblk = (int)currblk;

    // Find Insertion Point
    while (nextblk)
    {
        if (currblk >= prevblk && currblk <= nextblk) break;
        prevblk = nextblk;
        nextblk = (int *)nextblk[NEXT];
    }
    iprevblk = (int)prevblk;

    // Merge with the previous block if contiguous
    if (prevblk && (iprevblk + prevblk[SIZE] == icurrblk))
    {
        prevblk[SIZE] = prevblk[SIZE] + currblk[SIZE];
        // Also merge with next block if contiguous
        if (iprevblk + (int)prevblk[SIZE] == (int)nextblk)
        {
            prevblk[SIZE] = prevblk[SIZE] + nextblk[SIZE];
            prevblk[NEXT] = nextblk[NEXT];
        }
    }

    // Merge with the next block if contiguous
    else if (nextblk && icurrblk + (int)currblk[SIZE] == (int)nextblk)
    {
        currblk[SIZE] = currblk[SIZE] + nextblk[SIZE];
        currblk[NEXT] = nextblk[NEXT];
        if (prevblk)
          prevblk[NEXT] = (int)currblk;
        else
          memfreelist = currblk;
    }

    // Insert in the middle of the free list if not contiguous
    else if (prevblk)
    {
        prevblk[NEXT] = (int)currblk;
        currblk[NEXT] = (int)nextblk;
    }

    // Otherwise, insert at beginning of the free list
    else
    {
        memfreelist = currblk;
        currblk[NEXT] = (int)nextblk;
    }
}
