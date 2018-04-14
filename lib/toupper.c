int toupper(int val)
{
    if (val >= 'a' && val <= 'z') val -= 32;
    return val;
}
