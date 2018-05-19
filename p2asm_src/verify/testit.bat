echo %1
..\p2asm %1.spin2
comp %1.bin %1.obj <no.txt
fc %1.lst %1.lst1
