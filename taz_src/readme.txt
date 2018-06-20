                                      TAZ
                                 June 20, 2018
                                   Dave Hein

Taz is a C compiler that handles a subset of the C language.  Taz only handles
the data types of char, short and int.  Signed or unsigned specify may also
be used along with the type.  By default, int and short are signed and char is
unsigned.  Taz also supports pointers and one-dimensional arrays.

Taz generates P2 assembly code, which can then be assembled using the p2asm
assembler.  The -g option is also required for object file, which will generate
a "global" directive.

The C keywords that taz supports are:

     break char continue else for if int return short signed unsigned
     void while 

The C keywords that taz does not support are:

     auto case const default do double enum extern float goto long
     register sizeof static struct switch typedef union volatile

Taz also does not support the preprocessor directives, such as #define and
#ifdef.  The preprocessor, prep, is used to handle these directives.
Currently, prep only handles #define.

A program is compiled by simply typing taz followed by the C file name, such
as

taz hello.c

This will generate an assembly file named hello.s.  This file can then be
assembled by p2asm to produce an executable .bin file.

An assembly file that will be used to generate an object file can be produced
by specifying the -g option.  This option will generate code with global
directives inserted for the function names.  The following line will generate
an object-compatible version of hello.c:

taz -o hello.c

