char *gets(char *ptr)
{
    int val;
    char *ptr1;
    ptr1 = ptr;

    while (1)
    {
        val = getch();
        if (val == 8 || val == 127)
        {
            if (ptr != ptr1)
            {
                putch(8);
                putch(' ');
                putch(8);
                ptr--;
            }
        }
        else
        {
            putch(val);
            if (val == 13) break;
            if (val == 10) break;
            *ptr++ = val;
        }
    }
    *ptr = 0;

    return ptr1;
}
