#define type_MMC  1
#define type_SD   2
#define type_SDHC 3
#define ERR_CARD_NOT_RESET    ( - 1)
#define ERR_3v3_NOT_SUPPORTED ( - 2)
#define ERR_OCR_FAILED        ( - 3)
#define CMD0   ( 0x40 + 0) // GO_IDLE_STATE 
#define CMD1   ( 0x40 + 1) // SEND_OP_COND (MMC) 
#define ACMD41 ( 0xC0 + 41) // SEND_OP_COND (SDC) 
#define CMD8   ( 0x40 + 8) // SEND_IF_COND 
#define CMD12  ( 0x40 + 12) // STOP_TRANSMISSION
#define CMD16  ( 0x40 + 16) // SET_BLOCKLEN 
#define CMD58  ( 0x40 + 58) // READ_OCR
#define CMD59  ( 0x40 + 59) // CRC_ON_OFF 

void crash(int error_num)
{
    printf("Crash %d\n", error_num);
    exit(1);
}

int start_explicit(int DO, int CLK, int DI, int CS)
{
    int card_type = 0;
    int tmp, i, j;
    int pinDO, pinCLK, pinDI;
    int maskDO, maskDI, maskCS, maskCLK, maskAll;
    int adrShift;
/*
    Do all of the card initialization in SPIN, then hand off the pin
    information to the assembly cog for hot SPI block R/W action!
*/
    // Start from scratch
    stop();

    // wait ~4 milliseconds
    waitcnt( 500 + (clkfreq>>8) + cnt );
    // (start with cog variables, _BEFORE_ loading the cog)
    pinDO = DO;
    maskDO = 1 << DO;
    pinCLK = CLK;
    maskCLK = 1 << CLK;
    pinDI = DI;
    maskDI = 1 << DI;
    maskCS = 1 << CS;
    adrShift = 9; // block = 512 * index, and 512 = 1<<9
    // pass the output pin mask via the command register
    maskAll = maskCS | (1 << pinCLK) | maskDI;
    DIRA |= maskAll  ;
    // get the card in a ready state: set DI and CS high, send => 74 clocks
    OUTA |= maskAll;
    for (i = 0; i < 4096; i++)
    {
      OUTA |= maskCLK;
      OUTA &= ~maskCLK;
    }
    // time-hack
    //SPI_block_index = cnt;
    // reset the card
    tmp = 0;
    for (i = 0; i <= 9; i++)
    {
      if (tmp != 1)
      {
        tmp = send_cmd_slow( CMD0, 0, 0x95 );
        if (tmp & 4)
        {
          // the card said CMD0 ("go idle") was invalid, so we're possibly stuck in read or write mode
          if (i & 1)
          {
            // exit multiblock read mode
            for (j = 0; j < 4; j++)
              read_32_slow();     // these extra clocks are required for some MMC cards
            send_slow( 0xFD, 8 );   // stop token
            read_32_slow();
            while (read_slow() != 0xFF);
          }
          else
          {
            // exit multiblock read mode
            send_cmd_slow( CMD12, 0, 0x61 );
          }
        }
      }
    }
    if (tmp != 1)
    {
      // the reset command failed!
      crash( ERR_CARD_NOT_RESET );
    }
    // Is this a SD type 2 card?
    if (send_cmd_slow( CMD8, 0x1AA, 0x87 ) == 1)
    {
      // Type2 SD, check to see if it's a SDHC card
      tmp = read_32_slow();
    // check the supported voltage
      if ((tmp & 0x1FF) != 0x1AA)
      {
        crash( ERR_3v3_NOT_SUPPORTED );
      }
      // try to initialize the type 2 card with the High Capacity bit
      while (send_cmd_slow( ACMD41, 1 << 30, 0x77 ));
      // the card is initialized, let's read back the High Capacity bit
      if (send_cmd_slow( CMD58, 0, 0xFD ) != 0)
      {
        crash( ERR_OCR_FAILED );
      }
      // get back the data
      tmp = read_32_slow();
      // check the bit
      if (tmp & (1 << 30))
      {
        card_type = type_SDHC;
        adrShift = 0;
      }
      else
        card_type = type_SD;
    }
    else
    {
      // Either a type 1 SD card, or it's MMC, try SD 1st
      if (send_cmd_slow( ACMD41, 0, 0xE5 ) < 2)
      {
        // this is a type 1 SD card (1 means busy, 0 means done initializing)
        card_type = type_SD;
        while (send_cmd_slow( ACMD41, 0, 0xE5 ));
      }
      else
      {
        // mark that it's MMC, and try to initialize
        card_type = type_MMC;
        while (send_cmd_slow( CMD1, 0, 0xF9 ));
      }
      // some SD or MMC cards may have the wrong block size, set it here
      send_cmd_slow( CMD16, 512, 0x15 );
    }
    // card is mounted, make sure the CRC is turned off
    send_cmd_slow( CMD59, 0, 0x91 );
    //  check the status
    //send_cmd_slow( CMD13, 0, 0x0D )    
    // done with the SPI bus for now
    OUTA |= maskCS;
    // and we no longer need to control any pins from here
    DIRA &= !maskAll;
    // the return variable is card_type   
    return card_type;
}
