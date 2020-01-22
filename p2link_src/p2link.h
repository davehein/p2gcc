#define OTYPE_LABEL_BIT      0x10 // Indicates a symbol declaration
#define OTYPE_UNRESOLVED_BIT 0x08 // Indicates symbol is unresolved
#define OTYPE_WEAK_BIT       0x40 // Indicates symbol is weak

#define OTYPE_REF_AUGS       0x01 // Reference augs, s
#define OTYPE_REF_AUGD       0x02 // Reference augd, d
#define OTYPE_REF_FUNC_UND   0x0b // Undefined function reference
#define OTYPE_REF_FUNC_RES   0x03 // Resolved function reference
#define OTYPE_REF_LONG_REL   0x04 // Relocatable long reference
#define OTYPE_REF_LONG_UND   0x0d // Undefined long reference
#define OTYPE_REF_LONG_RES   0x05 // Resolved long reference
#define OTYPE_GLOBAL_FUNC    0x11 // Global Function
#define OTYPE_LOCAL_LABEL    0x12 // Local Label
#define OTYPE_INIT_DATA      0x13 // Initialized global data
#define OTYPE_UNINIT_DATA    0x14 // Uninitialized global data
#define OTYPE_RESOLVED_DATA  0x15 // Resolved global data
#define OTYPE_EXTERN_DATA    0x1d // External global data
#define OTYPE_WEAK_LABEL     0x55 // Weak Label
#define OTYPE_END_OF_CODE    0x20 // End of code/data

#define SECTION_NULL         0
#define SECTION_TEXT         1
#define SECTION_DATA         2
#define SECTION_BSS          3
