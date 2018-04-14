void sleep(int seconds)
{
    seconds *= 80000000;
    inline("waitx reg0");
}
