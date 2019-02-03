                                    S2PASM
                               February 2, 2019
                                   Dave Hein

S2pasm converts a P1 GCC assembly file to P2 assembly.  By default it assumes
that the C code was compiled using the COG memory model, and that the -S option
was specified to generate an assemby code file.  s2pasm can also convert
assembly that was produce for the LMM model by specifying the -lmm option.  The
output from s2pasm will have a .spin2 extension.

As an example, the C file blink.c is converted to a pasm2 file as follows:

propeller-elf-gcc -O2 -mcog -S blink.c
./s2pasm -p prefix.spin2 blink

The -p option specifies a file that is copied to the beginning of the output
file.  With the C compiler this file is normally prefix.spin2, which contains
the definitions of the registers along with the startup and stopping code.

S2pasm is built as follows:

gcc -Wall s2pasm.c lmmsubs.c -o s2pasm

