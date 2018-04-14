static int _randval_ = 1;

void srand(int seed)
{
    _randval_ = seed;
}

int rand(void)
{
    _randval_ = ((_randval_ * 1103515245) + 12345) & 0x7fffffff;
    return _randval_;
}
