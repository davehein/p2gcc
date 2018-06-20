int fibo(int n)
{
    if (n < 2) return (n);
    return fibo(n - 1) + fibo(n - 2);
}

int main(int argc, int argv)
{
    int n;
    int value;
    int startTime;
    int endTime;
    int executionTime;
    int rawTime;

    printf("hello, world!\r\n");
    for (n = 0; n <= 28; n++)
    {
        printf("fibo(%d) = ", n);
        startTime = getcount();
        value = fibo(n);
        endTime = getcount();
        rawTime = endTime - startTime;
        executionTime = rawTime / 80000;
        printf ("%d (%dms) (%d ticks)\n", value, executionTime, rawTime);
    }
    return 0;
}

int getcount(void)
{
    inline("        getct   reg0");
}

