                                    P2LINK
                               January 22, 2019
                                   Dave Hein

P2link is a linker that produces a P2 executable binary file.  It will link one
or more object and library files.  The first object file must start at location
zero, and contains the cog memory image.  All other objects can start at
location zero or $400, but anthing below $400 will be ignored.

If p2link is run without parameters, or a bad parameter is encountered the
following usage message will be printed:

p2link - a linker for the propeller 2 - version 0.004, 2019-1-21
usage: p2link
         [ -v ]       enable verbose mode
         [ -d ]       enable debug mode
         [ -o file ]  output file name (default a.out)
         [ -s addr ]  set starting address (default 0)
         [ -L dir ]   specify library directory
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

     <symbol type> <symbol section> <symbol value> <len> <symbol name>

The symbol type is a single byte that is defined in p2link.h as follows:

#define OTYPE_REF_AUGS     0x01 // Reference augs, s
#define OTYPE_REF_AUGD     0x02 // Reference augd, d
#define OTYPE_REF_FUNC_UND 0x0b // Undefined function reference
#define OTYPE_REF_LONG_REL 0x04 // Relocatable long reference
#define OTYPE_REF_LONG_UND 0x0d // Undefined long reference
#define OTYPE_GLOBAL_FUNC  0x11 // Global Function
#define OTYPE_LOCAL_LABEL  0x12 // Local Label
#define OTYPE_INIT_DATA    0x13 // Initialized global data
#define OTYPE_UNINIT_DATA  0x14 // Uninitialized global data
#define OTYPE_END_OF_CODE  0x20 // End of code/data

The symbol section defines the memory section where the symbol is declared
or from where it is referenced.  The symbol section is define in p2link.h
as follows:

#define SECTION_NULL       0
#define SECTION_TEXT       1
#define SECTION_DATA       2
#define SECTION_BSS        3

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
