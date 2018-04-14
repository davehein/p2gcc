                                    P2LINK
                                 July 20, 2017
                                   Dave Hein

P2link is a linker that produces a P2 executable binary file.  It will link one
or more object and library files.  The first object file must start at location
zero, and contains the cog memory image.  All other objects can start at
location zero or $400, but anthing below $400 will be ignored.

If p2link is run without parameters, or a bad parameter is encountered the
following usage message will be printed:

usage: p2link
         [ -v ]       enable verbose mode
         [ -d ]       enable debug mode
         [ -o file ]  output file name (default a.out)
         [ -s addr ]  set starting address (default 0)
         files        one or more object and library files

Object files use the following format:

     <object header> <symbol table> <object binary>

The object binary is the same as an executable binary, but with some locations
unresolved.  The object header is a follows:

    <object ID> <len> <object name>

The object ID consists of the 8 ASCII characters "P2OBJECT".  This identifies
the file as a P2 object file.  The len field is a single byte that gives the
length of the object name, which includes the terminating NULL character.

The symbol table contains one or more symbol entries with the following
format:

     <symbol type> <symbol value> <len> <symbol name>

The symbol type is a single byte that consist of an ASCII character.  The
allowable symbol types are listed below.

     G - Global function
     W - Reference augs, s
     X - Reference augd, d
     U - Undefined function reference
     R - Relocatable long reference
     V - Label
     D - Initialized global data
     d - Unititialized global data
     u - Undefined long reference
     E - End of code/data

The symbol value is a 32-bit number that normally specifies an address.  The
len value is a single byte that specifies the length of the symbol name, which
includes the terminating NULL.  The only exception to this is the "E" field
that signals the end of the symbol table.  It must be at the end of the table
and does not include a symbol name.

Library files contain one or more object files, and is simply a concatenation
of multiple object files.  A library file can by made using cat, as shown in
this example.

     cat object1.o object2.o object3.o >library.a

Library files must use an "a" file extension.  The linker will unconditionally
load all object files with a .o extension, but will only load objects in a
library if they are needed to resolve a symbol.
