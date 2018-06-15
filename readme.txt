                                     P2GCC
                                 May 29, 2018
                                   Dave Hein

p2gcc will compile, link and load a C file onto a P2 FPGA board.  If the -s
option is specified p2gcc will run the program on the P2 simulator instead of
running it on an FPGA board.  It uses the PropGCC compiler to generate a P1 .s
assembly file.  The assembly file is converted to a P2 .spin2 file using the
utility s2pasm.  The P2 assembly file is assembled into an object file using
p2asm.  p2link is then used to link the object file with other object files
and libraries to produce an executable binary file.

If p2gcc is run without any parameters it will produce the following usage
message.

     usage: p2gcc [options] file [file...]
       options are
       -c      - Do not run the linker
       -v      - Enable verbose mode
       -d      - Enable debug mode
       -r      - Run after linking
       -t      - Run terminal emulator
       -T      - Run terminal emulator in PST mode
       -k      - Keep intermediate files
       -s      - Run simulutor
       -o file - Set output file name
       -p path - Port used for loading

If the -o option is not specified an executable binary file named a.out will be
created.

p2gcc will link with the library files located in the lib subdirectory.  The lib
subdirectory also contains an object file name prefix.o.  This file is produced
from the P2 assembly file prefix.spin2.  It contains the register definitions and
a small number of routines that run from cog memory.  prefix.spin2 is added to a
.spin2 file when it is converted from a .s file.  When linking, prefix.o is
included as the first object in the list.

The various tools are pre-built for Windows and MinGW.  They can be rebuilt using
the build script build_mingw run from a MinGW window.  The build scripts
build_cygwin, build_linux and build_macos are used to build the tools for Cygwin,
Linux and macOS.

The executable files are placed in the bin subdirectory.  The source code for the
various tools are located in the subdirectories loadp2_src, p2asm_src, p2link_src,
s2pasm_src and util.

The bin directory should be added to the user's path, or the files in the bin
directory should be copied to an existing directory that is already in the user's
path.  The environment variable, P2GCC_LIBDIR must also be defined to point to
the lib directory.  It is used for linking and also defines where prefix.spin2 is
located for s2pasm.

There are several example programs in this directory.  They can be built and run
as follows:

     p2gcc -r blink.c
     p2gcc -r -t bas.c
     p2gcc -r -t chess.c
     p2gcc -r -t dry.c
     p2gcc -r -t fibo.c
     p2gcc -r -t fft_bench.c
     p2gcc -r -t hello.c
     p2gcc -r -t malloctest.c
     p2gcc -r -t prime.c
     p2gcc -r -t xxtea.c
     p2gcc -r -t test7.c test8.c
     p2gcc -r -t fsrwtest.c
     p2gcc -r -t filetest.c

fsrwtest and filetest require that an SD card be connected to I/O pins 59, 60,
58 and 61.

Programs can also be run on the simulator by specifying the -s option.  A Windows
executable for spinsim is included in this distribution.  spinsim must be built
separately to run under Linux.  Version 0.97 or later is required.
