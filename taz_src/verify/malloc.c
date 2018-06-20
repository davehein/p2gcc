//'******************************************************************************
//' C malloc functions
//' Copyright (c) 2010-2015 Dave Hein
//' See end of file for terms of use.
//'******************************************************************************
int memfreelist = 0;
int malloclist = 0;
char *heapaddr = 0;
char *heapaddrlast = 0;

void mallocinit(char *addr)
{
    malloclist = 0;
    memfreelist = 0;
    heapaddr = addr;
    heapaddrlast = addr;
}

char *malloc(int size)
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
        if (currblk[1] >= size)
        {
            // Split block if it's big enough
            if (currblk[1] >= size + 12)
            {
                currblk[size1] = currblk[0];
                currblk[size1+1] = currblk[1] - size;
                currblk[0] = &currblk[size1];
                currblk[1] = size;
            }
            // Remove block from free list
            if (prevblk)
                prevblk[0] = currblk[0];
            else
                memfreelist = currblk[0];
            AddToMallocList(currblk);
            return &currblk[2];
        }
        prevblk = currblk;
        currblk = currblk[0];
    }

    // Attempt to allocate heapaddrlast
    stackptr = &stackptr;
    if (stackptr - heapaddrlast < size + 100) return 0;
    currblk = heapaddrlast;
    currblk[0] = 0;
    currblk[1] = size;
    AddToMallocList(currblk);
    heapaddrlast += size;
    return &currblk[2];
}

void AddToMallocList(int *newblk)
{
    int *currblk;

    newblk[0] = 0;
    if (malloclist)
    {
        currblk = malloclist;
        while (currblk[0]) currblk = currblk[0];
        currblk[0] = newblk;
    }
    else
        malloclist = newblk;
}

// Return the memory block at "ptr" to the free list.  Return a value of one
// if successful, or zero if the memory block was not on the allocate list.
int free(int *ptr)
{
    int *prevblk;
    int *currblk;
    int *nextblk;

    prevblk = 0;
    nextblk = malloclist;
    currblk = &ptr[-2];

    // Search the malloclist for the currblk pointer
    while (nextblk)
    {
        if (currblk == nextblk)
        {
            // Remove from the malloc list
            if (prevblk)
                prevblk[0] = nextblk[0];
            else
                malloclist = nextblk[0];
            // Add to the free list
            meminsert(nextblk);
            trimfreelist();
            return 1;
        }
        prevblk = nextblk;
        nextblk = nextblk[0];
    }

    // Return a NULL value if not found
    return 0;
}

void trimfreelist(void)
{
    int *currblk;
    int *prevblk;
    int ival;

    if (!memfreelist) return;

    prevblk = 0;
    currblk = memfreelist;
    while (currblk[0])
    {
        prevblk = currblk;
        currblk = currblk[0];
    }
    ival = currblk;
    if (ival + currblk[1] == heapaddrlast)
    {
        heapaddrlast = currblk;
        if (prevblk)
            prevblk[0] = 0;
        else
            memfreelist = 0;
    }
}

// Insert a memory block back into the free list.  Merge blocks together if
// the memory block is contiguous with other blocks on the list.
void meminsert(int *currblk)
{
    int icurrblk;
    int iprevblk;
    int *prevblk;
    int *nextblk;

    prevblk = 0;
    nextblk = memfreelist;
    icurrblk = currblk;

    // Find Insertion Point
    while (nextblk)
    {
        if (currblk >= prevblk && currblk <= nextblk) break;
        prevblk = nextblk;
        nextblk = nextblk[0];
    }
    iprevblk = prevblk;

    // Merge with the previous block if contiguous
    if (prevblk && (iprevblk + prevblk[1] == icurrblk))
    {
        prevblk[1] = prevblk[1] + currblk[1];
        // Also merge with next block if contiguous
        if (iprevblk + prevblk[1] == nextblk)
        {
            prevblk[1] = prevblk[1] + nextblk[1];
            prevblk[0] = nextblk[0];
        }
    }

    // Merge with the next block if contiguous
    else if (nextblk && icurrblk + currblk[1] == nextblk)
    {
        currblk[1] = currblk[1] + nextblk[1];
        currblk[0] = nextblk[0];
        if (prevblk)
          prevblk[0] = currblk;
        else
          memfreelist = currblk;
    }

    // Insert in the middle of the free list if not contiguous
    else if (prevblk)
    {
        prevblk[0] = currblk;
        currblk[0] = nextblk;
    }

    // Otherwise, insert at beginning of the free list
    else
    {
        memfreelist = currblk;
        currblk[0] = nextblk;
    }
}

// Allocate a memory block of num*size bytes and initialize to zero.  Return
// a pointer to the memory block if successful, or zero if a large enough
// memory block could not be found.
int *calloc(int num, int size)
{
    char *ptr;
    int *ptr1;
    size *= num;
    ptr = malloc(size);
    if (ptr)
    {
        ptr1 = ptr;
        size = (size + 3) >> 2;
        while (size--) *ptr1++ = 0;
    }
    return ptr;
}
