int tolower(int val)
{
    if (val >= 'A' && val <= 'Z') val += 32;
    return val;
}
