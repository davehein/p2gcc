void abort(void)
{
    inline("cogid reg0");
    inline("mov reg1, reg0");
    inline("shl reg1, #2");
    inline("add reg1, ##$7ff80");
    inline("wrlong #0, reg1");
    inline("cogstop reg0");
}
