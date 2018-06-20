int prime(int maxnum)
{
    int i, j, numprimes, maxprimes;
    int count, prime, isprime;
    short primes[10000];

    primes[0] = 1;
    primes[1] = 2;

    printf("%d ", 1);
    printf("%d ", 2);

    numprimes = 2;
    count = 2;
    maxprimes = 10000;
    for (i = 3; i < maxnum; i += 2)
    {
        isprime = 1;
        for (j = 2; j < numprimes; j++)
        {
            prime = primes[j];
            if (prime * prime > i) j = numprimes;
            else if (i / prime * prime == i)
            {
                j = numprimes;
                isprime = 0;
            }
        }
        if (isprime)
        {
            printf("%d ", i);
            if (++count >= 10)
            {
                count = 0;
                printf("\n");
            }
            primes[numprimes++] = i;
            if (numprimes >= maxprimes) i = maxnum;
        }
    }
    if (count)
        printf("\n");
    return 0;
}

void main(void)
{
    int max_number;

    while (1)
    {
        printf("Enter the max number: ");
        scanf("%d", &max_number);
        if (max_number <= 0) break;
        if (max_number < 2) continue;
        prime(max_number);
    }
}
