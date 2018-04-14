#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "osint.h"

#define LOADER_BAUD 2000000

static int user_baud = 115200;

#if defined(__CYGWIN__) || defined(__MINGW32__) || defined(__MINGW64__)
  #define PORT_PREFIX "com"
#elif defined(__APPLE__)
  #define PORT_PREFIX "/dev/cu.usbserial"
#else
  #define PORT_PREFIX "/dev/ttyUSB"
#endif

static char buffer[512];
static char binbuffer[101];   // Added for Prop2-v28
static int verbose = 0;

/* Usage - display a usage message and exit */
static void Usage(void)
{
printf("\
loadp2 - a loader for the propeller 2 - version 0.005, 2018-04-04\n\
usage: loadp2\n\
         [ -p port ]               serial port\n\
         [ -b baud ]               baud rate (default is %d)\n\
         [ -s address ]            starting address in hex (default is 0)\n\
         [ -t ]                    enter terminal mode after running the program\n\
         [ -T ]                    enter PST-compatible terminal mode\n\
         [ -v ]                    enable verbose mode\n\
         [ -? ]                    display a usage message and exit\n\
         file                      file to load\n", user_baud);
    exit(1);
}

int loadfile(char *fname, int address)
{
    FILE *infile;
    int num, size, i;

    infile = fopen(fname, "rb");
    if (!infile)
    {
        printf("Could not open %s\n", fname);
        return 1;
    }
    fseek(infile, 0, SEEK_END);
    size = ftell(infile);
    fseek(infile, 0, SEEK_SET);
    if (verbose) printf("Loading %s - %d bytes\n", fname, size);
    hwreset();
    msleep(50);
    tx((uint8_t *)"> Prop_Hex 0 0 0 0", 18);

    while ((num=fread(binbuffer, 1, 101, infile)))
    {
        for( i = 0; i < num; i++ )
            sprintf( &buffer[i*3], " %2.2x", binbuffer[i] & 255 );
        tx( (uint8_t *)buffer, strlen(buffer) );
    }
    tx((uint8_t *)"~", 1);   // Added for Prop2-v28

    msleep(50);
    if (verbose) printf("%s loaded\n", fname);
    return 0;
}

int findp2(char *portprefix, int baudrate)
{
    int i, num;
    char Port[20];
    char buffer[101];

    if (verbose) printf("Searching serial ports for a P2\n");
    for (i = 0; i < 20; i++)
    {
        sprintf(Port, "%s%d", portprefix, i);
        if (serial_init(Port, baudrate))
        {
            hwreset();
            msleep(50);
            tx((uint8_t *)"> Prop_Chk 0 0 0 0  ", 20);
            msleep(50);
            num = rx_timeout((uint8_t *)buffer, 100, 10);
            if (num >= 0) buffer[num] = 0;
            else buffer[0] = 0;
            if (!strncmp(buffer, "\r\nProp_Ver ", 11))
            {
                if (verbose) printf("P2 version %c found on serial port %s\n", buffer[11], Port);
                return 1;
            }
            serial_done();
        }
    }
    return 0;
}

int atox(char *ptr)
{
    int value;
    sscanf(ptr, "%x", &value);
    return value;
}

int main(int argc, char **argv)
{
    int i;
    int runterm = 0;
    int pstmode = 0;
    char *fname = 0;
    char *port = 0;
    int address = 0;

    // Parse the command-line parameters
    for (i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (argv[i][1] == 'p')
            {
                if(argv[i][2])
                    port = &argv[i][2];
                else if (++i < argc)
                    port = argv[i];
                else
                    Usage();
            }
            else if (argv[i][1] == 'b')
            {
                if(argv[i][2])
                    user_baud = atoi(&argv[i][2]);
                else if (++i < argc)
                    user_baud = atoi(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 's')
            {
                if(argv[i][2])
                    address = atox(&argv[i][2]);
                else if (++i < argc)
                    address = atox(argv[i]);
                else
                    Usage();
            }
            else if (argv[i][1] == 't')
                runterm = 1;
            else if (argv[i][1] == 'T')
                runterm = pstmode = 1;
            else if (argv[i][1] == 'v')
                verbose = 1;
            else
            {
                printf("Invalid option %s\n", argv[i]);
                Usage();
            }
        }
        else
        {
            if (fname) Usage();
            fname = argv[i];
        }
    }

    if (!fname) Usage();
    if (!port)
    {
        if (!findp2(PORT_PREFIX, LOADER_BAUD))
        {
            printf("Could not find a P2\n");
            exit(1);
        }
    }
    else if (1 != serial_init(port, LOADER_BAUD))
    {
        printf("Could not open port %s\n", argv[1]);
        exit(1);
    }

    if (loadfile(fname, address))
    {
        serial_done();
        exit(1);
    }

    if (runterm)
    {
        serial_baud(user_baud);
        printf("[ Entering terminal mode.  Press ESC to exit. ]\n");
        terminal_mode(1,pstmode);
    }

    serial_done();
    return 0;
}
