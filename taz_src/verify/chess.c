//############################################################################
//# This program implements the game of chess on the Parallax P2 processor.
//#
//# Copyright (c) 2013-2015, Dave Hein
//# MIT Licensed
//############################################################################

// The chess board state is maintained in a 160-byte character array that
// contains the following informtion:













char *symbols;

// Directions that the pieces can move
int king_moves[8] = {11, 13, -13, -11, -1, 12, 1, -12};
int knight_moves[8] = {-23, -10, 14, 25, 23, 10, -14, -25};

// The piece values
int values[] = { 0, 20, 64, 65, 100, 195, 10000, 0};

// Pawn position values
signed char pawn_values[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 10, 10, 10, 10, 10, 10, 10, 10, 0, 0,
    0, 0, 2, 2, 4, 6, 6, 4, 2, 2, 0, 0,
    0, 0, 1, 1, 2, 6, 6, 2, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 5, 5, 0, 0, 0, 0, 0,
    0, 0, 1, -1, -2, 0, 0, -2, -1, 1, 0, 0,
    0, 0, 1, 2, 2, -5, -5, 2, 2, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

// Knight position values
signed char knight_values[] = {
    0, 0,-10, -8, -6, -6, -6, -6, -8,-10, 0, 0,
    0, 0, -8, -4, 0, 0, 0, 0, -4, -8, 0, 0,
    0, 0, -6, 0, 2, 3, 3, 2, 0, -6, 0, 0,
    0, 0, -6, 1, 3, 4, 4, 3, 1, -6, 0, 0,
    0, 0, -6, 0, 3, 4, 4, 3, 0, -6, 0, 0,
    0, 0, -6, 1, 2, 3, 3, 2, 1, -6, 0, 0,
    0, 0, -8, -4, 0, 1, 1, 0, -4, -8, 0, 0,
    0, 0,-10, -8, -4, -6, -6, -4, -8,-10, 0, 0};

// Bishop position values
signed char bishop_values[] = {
    0, 0, -4, -2, -2, -2, -2, -2, -2, -4, 0, 0,
    0, 0, -2, 0, 0, 0, 0, 0, 0, -2, 0, 0,
    0, 0, -2, 0, 1, 2, 2, 1, 0, -2, 0, 0,
    0, 0, -2, 1, 1, 2, 2, 1, 1, -2, 0, 0,
    0, 0, -2, 0, 2, 2, 2, 2, 0, -2, 0, 0,
    0, 0, -2, 2, 2, 2, 2, 2, 2, -2, 0, 0,
    0, 0, -2, 1, 0, 0, 0, 0, 1, -2, 0, 0,
    0, 0, -4, -2, -8, -2, -2, -8, -2, -4, 0, 0};

// King position values
signed char king_values[] = {
    0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
    0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
    0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
    0, 0, -6, -8, -8,-10,-10, -8, -8, -6, 0, 0,
    0, 0, -4, -6, -6, -8, -8, -6, -6, -4, 0, 0,
    0, 0, -2, -4, -4, -4, -4, -4, -4, -2, 0, 0,
    0, 0, 4, 4, 0, 0, 0, 0, 4, 4, 0, 0,
    0, 0, 4, 6, 2, 0, 0, 2, 6, 4, 0, 0};

// Null position values used for the queen and rooks
signed char null_values[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

signed char *pos_values[8] = { null_values, pawn_values, knight_values,
bishop_values, null_values, null_values, king_values, null_values};

unsigned char black_rank[8] = {4, 2, 3, 5, 6, 3, 2, 4};
unsigned char white_rank[8] = {4 | 0x80, 2 | 0x80, 3 | 0x80,
    5 | 0x80, 6 | 0x80, 3 | 0x80, 2 | 0x80, 4 | 0x80};

// Global variables
int MoveFunction;      // Function that is called for each move
int movenum;           // current move number
int person_old;        // postion selected by person to move from
int person_new;        // postion selected by person to move to
int playdepth;         // number of moves to look ahead
int validmove;         // indicates if a human's move is valid
int compcolor;         // color that the computer is playing
int human_playing;     // indicates that a person is playing
char inbuf[80];        // buffer for human input
char positionstr[3];   // Used by PositionToString

int PieceFunctions[8] = {0, 4, 5, 6, 7, 8, 9, 0};

// Return the value of a piece at a particular position on the board
int get_pos_value(int piece, int position)
{
    signed char *ptr;
    ptr = pos_values[piece];
    return ptr[position];
}

// Prepare to search the next level
void InitializeNextLevel(unsigned char *level, unsigned char *next_level)
{
    memcpy(next_level, level, 160);
    next_level[149] = next_level[149] + 1;
}

void ChangeColor(unsigned char *level)
{
    level[148] = level[148] ^ 0x80;
}

int BoardValue(unsigned char *level)
{
    short *slevel;
    slevel = level;
    return slevel[144>>1];
}

// Convert a numeric position value to a string
char *PositionToString(int position)
{
    int row, col;
    row = position / 12;
    col = position % 12;
    positionstr[0] = col - 2 + 'a';
    positionstr[1] = 10 - row + '0';
    positionstr[2] = 0;
    return positionstr;
}

// Convert a postion string to a numeric value
int StringToPostion(char *str)
{
    unsigned int col;
    unsigned int row;
    col = tolower(str[0]) - 'a';
    row = str[1] - '1';
    if (col > 7 || row > 7) return -1;
    return (7 - row + 2) * 12 + col + 2;
}

// Print the board
void PrintBoard(unsigned char *level)
{
    int i, j;
    unsigned char *ptr;
    ptr = level + (12 * 2);
    printf("\n ");
    for (i = 'a'; i <= 'h'; i++) printf("|%c ", i);
    printf("|");
    for (i = 0; i < 8; i++)
    {
        printf("\n-+--+--+--+--+--+--+--+--+");
        printf("\n%c", '8' - i);
        for (j = 2; j < 10; j++)
        {
            if (ptr[j])
            {
                printf("|%c", symbols[ptr[j] & 0x07]);
                if (ptr[j] & 0x80)
                    printf("W");
                else
                    printf("B");
            }
            else if ((i^j)&1)
                printf("|--");
            else
                printf("|  ");
        }
        printf("|");
        ptr += 12;
    }
    printf("\n-+--+--+--+--+--+--+--+--+");
    printf("\n\n");
}

// Determine if the board position contains the current color's piece
int IsMyPiece(unsigned char *level, int offs)
{
    unsigned char *brd;
    brd = level;
    if (brd[offs] == 0) return 0;
    if (brd[offs] == 0xff) return 0;
    return ((brd[offs] & 0x80) == level[148]);
}

// Determine if the board position contains the other color's piece
int IsOtherPiece(unsigned char *level, int offs)
{
    unsigned char *brd;
    brd = level;
    if (brd[offs] == 0) return 0;
    if (brd[offs] == 0xff) return 0;
    return ((brd[offs] & 0x80) != level[148]);
}

// Determine if the board position does not contain the
// current color's piece and is in bounds.
int IsMoveOK(unsigned char *level, int offs)
{
    unsigned char *brd;
    brd = level;
    return (!IsMyPiece(level, offs) && brd[offs] != 0xff);
}

// Generate moves in a certain direction for a bishop, rook or queen
void AnalyzeDirectionalMoves(unsigned char *level, int direction)
{
    unsigned char *brd;
    brd = level;
    level[151] = level[150];
    while (1)
    {
        //level[151] += direction;
        level[151] = level[151] + direction;
        if (IsMyPiece(level, level[151]) || brd[level[151]] == 0xff) break;
        CallMoveFunction(MoveFunction, level);
        if (brd[level[151]] != 0) break;
    }
}

// Determine if the king's space is under attack
int IsCheck(unsigned char *level)
{
    int color;
    unsigned char *king_ptr;
    int i, row_step, offs, incr, flags, piece;
    color = level[148];
    king_ptr = level;
    if (color)
    {
        row_step = -12;
        king_ptr += level[154];
    }
    else
    {
        row_step = 12;
        king_ptr += level[155];
    }
    color ^= 0x80;
    // Check for pawns
    if ((king_ptr[row_step + 1] & (0x80 | 0x07)) == (color | 1))
        return 1;
    if ((king_ptr[row_step - 1] & (0x80 | 0x07)) == (color | 1))
        return 1;
    // Check for knights
    for (i = 0; i < 8; i++)
    {
        if ((king_ptr[knight_moves[i]] & (0x80 | 0x07)) == (color | 2))
            return 1;
    }
    // Check for king, queen, bishop or rook
    for (i = 0; i < 8; i++)
    {
        offs = incr = king_moves[i];
        if ((king_ptr[offs] & (0x80 | 0x07)) == (color | 6))
            return 1;
        while (king_ptr[offs] == 0)
            offs += incr;
        flags = king_ptr[offs];
        if ((flags & 0x80) != color)
            continue;
        piece = flags & 0x07;
        if (piece == 5)
            return 1;
        if (i < 4)
        {
            if (piece == 3)
                return 1;
        }
        else
        {
            if (piece == 4)
                return 1;
        }
    }
    return 0;
}

// This routine catches invalid piece values, and should never be called
void Invalid(unsigned char *level)
{
    printf("Invalid piece\n");
    exit(1);
}

// Generate all possible moves for a pawn
void Pawn(unsigned char *level)
{
    int row_step;
    unsigned char *brd;
    row_step = 12;
    brd = level;
    if (level[148])
        row_step = -12;
    // Check capture to the left
    level[151] = level[150] - 1 + row_step;
    if (IsOtherPiece(level, level[151]) || level[156] == level[150] - 1)
    {
        CallMoveFunction(MoveFunction, level);
    }
    // Check capture to the right
    //level[151] += 2;
    level[151] = level[151] + 2;
    if (IsOtherPiece(level, level[151]) || level[156] == level[150] + 1)
    {
        CallMoveFunction(MoveFunction, level);
    }
    // Check moving forward one space
    //level[151] -= 1;
    level[151] = level[151] - 1;
    if (IsMoveOK(level, level[151]) && !IsOtherPiece(level, level[151]))
    {
        CallMoveFunction(MoveFunction, level);
    }
    else
        return;
    if (brd[level[150]] & 0x40)
        return;
    // Check moving forward two spaces
    //level[151] += row_step;
    level[151] = level[151] + row_step;
    if (IsMoveOK(level, level[151]) && !IsOtherPiece(level, level[151]))
    {
        CallMoveFunction(MoveFunction, level);
    }
}

// Generate all possible moves for a knight
void Knight(unsigned char *level)
{
    int i;
    unsigned char *brd;
    brd = level;
    for (i = 0; i < 8; i++)
    {
        level[151] = level[150] + knight_moves[i];
        if (IsMoveOK(level, level[151]))
        {
            CallMoveFunction(MoveFunction, level);
        }
    }
}

// Generate all possible moves for a bishop
void Bishop(unsigned char *level)
{
    int i;
    for (i = 0; i < 4; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Generate all possible moves for a rook
void Rook(unsigned char *level)
{
    int i;
    unsigned char *brd;
    brd = level;
    for (i = 4; i < 8; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Generate all possible moves for a queen
void Queen(unsigned char *level)
{
    int i;
    for (i = 0; i < 8; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Determine if this space is under attack
int IsSpaceUnderAttack(unsigned char *level, int position)
{
    int retval, king_pos;
    if (level[148])
    {
        king_pos = level[154];
        level[154] = position;
        retval = IsCheck(level);
        level[154] = king_pos;
    }
    else
    {
        king_pos = level[155];
        level[155] = position;
        retval = IsCheck(level);
        level[155] = king_pos;
    }
    return retval;
}

void CastleRight(unsigned char *level)
{
    unsigned char *brd;
    int old_pos;
    brd = level;
    old_pos = level[150];
    if (brd[old_pos + 1]) return;
    if (brd[old_pos + 2]) return;
    if (brd[old_pos + 3] & 0x40) return;
    if (IsCheck(level)) return;
    if (IsSpaceUnderAttack(level, level[150] + 1)) return;
    level[151] = level[150] + 2;
    CallMoveFunction(MoveFunction, level);
}

void CastleLeft(unsigned char *level)
{
    unsigned char *brd;
    int old_pos;
    brd = level;
    old_pos = level[150];
    if (brd[old_pos - 1]) return;
    if (brd[old_pos - 2]) return;
    if (brd[old_pos - 3]) return;
    if (brd[old_pos - 4] & 0x40) return;
    if (IsCheck(level)) return;
    if (IsSpaceUnderAttack(level, level[150] - 1)) return;
    level[151] = level[150] - 2;
    CallMoveFunction(MoveFunction, level);
}

// Generate all possible moves for a king
void King(unsigned char *level)
{
    int i;
    unsigned char *brd;
    brd = level;
    // Check 8 single-space moves
    for (i = 0; i < 8; i++)
    {
        level[151] = level[150] + king_moves[i];
        if (IsMoveOK(level, level[151]))
        {
            CallMoveFunction(MoveFunction, level);
        }
    }
    // Check castling
    if (!(brd[level[150]] & 0x40))
    {
        CastleRight(level);
        CastleLeft(level);
    }
}

// Call the piece move generator function if this the color is correct
void MoveIfMyPiece(unsigned char *level)
{
    int piece;
    unsigned char *brd;
    brd = level;
    if (IsMyPiece(level, level[150]))
    {
        piece = brd[level[150]] & 0x07;
        CallMoveFunction(PieceFunctions[piece], level);
    }
}

// Generate all moves on the board and analyze them
void AnalyzeAllMoves(unsigned char *level)
{
    int row, col, rowinc;
    if (level[148] == 0x00)
    {
        level[150] = ((12 * 2) + 2); // start at the left top
        rowinc = 12 - 8;
    }
    else
    {
        level[150] = ((12 * 9) + 2); // start at the left bottom
        rowinc = -12 - 8;
    }
    for (row = 0; row < 8; row++)
    {
        for (col = 0; col < 8; col++)
        {
            MoveIfMyPiece(level);
            //level[150] += 1;
            level[150] = level[150] + 1;
        }
        //level[150] += rowinc;
        level[150] = level[150] + rowinc;
    }
}

// Remove a piece from the board and subtract its value
void RemovePiece(unsigned char *level, int position)
{
    unsigned char *brd;
    int entry;
    int piece;
    int value;
    short *slevel;
    brd = level;
    entry = brd[position];
    piece = entry & 0x07;
    value = values[piece];
    slevel = level;
    if (entry == 0) return;
    if (entry == 0xff)
    {
        printf("RemovePiece: %d is out of bounds\n", position);
        exit(1);
    }
    if (entry & 0x80)
    {
        //value += pos_values[piece][position - (2 * 12)];
        value += get_pos_value(piece, position - (2 * 12));
        //slevel[144>>1] -= value;
        slevel[144>>1] = slevel[144>>1] - value;
    }
    else
    {
        //value += pos_values[piece][(12 * 10) - 1 - position];
        value += get_pos_value(piece, (12 * 10) - 1 - position);
        //slevel[144>>1] += value;
        slevel[144>>1] = slevel[144>>1] + value;
    }
    brd[position] = 0;
}

// Add a piece to the board and add its value
void AddPiece(unsigned char *level, int position, int entry)
{
    unsigned char *brd;
    int piece;
    int value;
    short *slevel;
    brd = level;
    piece = entry & 0x07;
    value = values[piece];
    slevel = level;
    if (brd[position])
    {
        printf("AddPiece: %d occupied\n", position);
        exit(1);
    }
    if (brd[position])
    {
        printf("RemovePiece: %d is out of bounds\n", position);
        exit(1);
    }
    if (entry & 0x80)
    {
        //value += pos_values[piece][position - (2 * 12)];
        value += get_pos_value(piece, position - (2 * 12));
        //slevel[144>>1] += value;
        slevel[144>>1] = slevel[144>>1] + value;
    }
    else
    {
        //value += pos_values[piece][(12 * 10) - 1 - position];
        value += get_pos_value(piece, (12 * 10) - 1 - position);
        //slevel[144>>1] -= value;
        slevel[144>>1] = slevel[144>>1] - value;
    }
    brd[position] = entry | 0x40;
}

// Move a piece from one place to another and adjust the board's value
void MovePiece(unsigned char *level, int old_pos, int new_pos)
{
    unsigned char *brd;
    int entry1;
    int entry2;
    int piece;
    int value;
    short *slevel;
    slevel = level;
    brd = level;
    entry1 = brd[old_pos];
    entry2 = brd[new_pos];
    piece = entry1 & 0x07;
    //printf("MovePiece: %d from", piece);
    //printf(" %s to", PositionToString(old_pos));
    //printf(" %s - ", PositionToString(new_pos));
    if (entry1 == 0) return;
    if (entry1 == 0xff)
    {
        printf("MovePiece: %d is out of bounds\n", old_pos);
        exit(1);
    }
    if (entry2)
        RemovePiece(level, new_pos);
    RemovePiece(level, old_pos);
    AddPiece(level, new_pos, entry1);
    //printf("%d\n", slevel[144>>1]);
}

// Move a piece and remove an opponent's piece if taken
// Check for castling, en passant capture and pawn promotion
void PerformMove(unsigned char *level)
{
    unsigned char *brd;
    int val1;
    int val2;
    int en_passant;
    int value;
    brd = level;
    val1 = brd[level[150]];
    val2 = brd[level[151]];
    en_passant = level[156];
    value = values[val2 & 0x07];

    // Clear en_passant flag.  May be set later.
    level[156] = 0;

    // Check if taking opponent's piece
    if (val2) RemovePiece(level, level[151]);

    // Check if moving king
    if ((val1 & 0x07) == 6)
    {
        // Update it's position
        if (val1 & 0x80)
            level[154] = level[151];
        else
            level[155] = level[151];
        // Check for castle right
        if (level[151] == level[150] + 2)
        {
            if (level[149] == 0) printf("CASTLE RIGHT\n\n");
            MovePiece(level, level[150] + 3, level[150] + 1);
        }
        // Check for castle left
        if (level[151] == level[150] - 2)
        {
            if (level[149] == 0) printf("CASTLE LEFT\n\n");
            MovePiece(level, level[150] - 4, level[150] - 1);
        }
    }

    // Check if moving pawn
    if ((val1 & 0x07) == 1)
    {
        if (val1 & 0x80)
        {
            // Set the en passant flag if moving pawn two spaces
            if (level[151] == level[150] - (2 * 12))
            {
                level[156] = level[151];
            }
            // Check for en passant capture
            else if (level[151] == en_passant - 12)
            {
                if (level[149] == 0) printf("EN PASSANT\n\n");
                RemovePiece(level, en_passant);
            }
            // Promote pawn to queen if reaching final rank
            else if (level[151] <= ((12 * 2) + 9))
            {
                RemovePiece(level, level[150]);
                AddPiece(level, level[151], 0x80 | 5);
                return;
            }
        }
        else
        {
            // Set the en passant flag if moving pawn two spaces
            if (level[151] == level[150] + (2 * 12))
            {
                level[156] = level[151];
            }
            // Check for en passant capture
            else if (level[151] == en_passant + 12)
            {
                if (level[149] == 0) printf("EN PASSANT\n\n");
                RemovePiece(level, en_passant);
            }
            // Promote pawn to queen if reaching final rank
            else if (level[151] >= ((12 * 9) + 2))
            {
                RemovePiece(level, level[150]);
                AddPiece(level, level[151], 0x00 | 5);
                return;
            }
        }
    }
    MovePiece(level, level[150], level[151]);
}

// Analyze move from old_pos to new_pos.  If we have reached the maximum depth
// check if the board value is better than the values from the previous moves.
// If we have not reached the maximum depth, determine the best counter-move
// at the next level, and check if better than any previous move.
// In the case of a tie, pick the new move 25% of the time.
void AnalyzeMove(unsigned char *level)
{
    unsigned char next_level[160];
    int update, value;
    unsigned char *ptr;
    short *slevel;
    short *snext_level;
    ptr = level;
    slevel = level;
    snext_level = next_level;

    if (ptr[level[150]] == 0xff || ptr[level[151]] == 0xff)
    {
        printf("BAD MOVE: %2.2x-%2.2x\n", level[150], level[151]);
        exit(0);
    }

    InitializeNextLevel(level, next_level);
    PerformMove(next_level);
    if (IsCheck(next_level)) return;
    value = BoardValue(next_level);

    // Stop searching if checkmate
    if (value > 5000 || value < -5000)
    {
        slevel[146>>1] = value;
        level[152] = level[150];
        level[153] = level[151];
    }
    else if (next_level[149] == playdepth)
    {
        if (level[148])
            update = (value > slevel[146>>1]);
        else
            update = (value < slevel[146>>1]);
        if (update)
        {
            slevel[146>>1] = value;
            level[152] = level[150];
            level[153] = level[151];
        }
    }
    else
    {
        ChangeColor(next_level);
        if (next_level[148] == 0x00)
            snext_level[146>>1] = 0x7fff;
        else
            snext_level[146>>1] = -0x7fff;
        next_level[152] = 0;
        next_level[153] = 0;
        AnalyzeAllMoves(next_level);
        if (!next_level[152])
        {
            // Check for check
            if (IsCheck(next_level))
            {
                if (level[148])
                    snext_level[146>>1] = 10000;
                else
                    snext_level[146>>1] = -10000;
            }
            else
                snext_level[146>>1] = 0; // Should go for draw only if way behind
        }
        value = snext_level[146>>1];
        if (value == slevel[146>>1])
        {
            update = ((rand() & 3) == 0);
        }
        else
        {
            if (level[148])
                update = (value > slevel[146>>1]);
            else
                update = (value < slevel[146>>1]);
        }
        if (update)
        {
            slevel[146>>1] = value;
            level[152] = level[150];
            level[153] = level[151];
        }
    }
}

int IsCheckMate(unsigned char *level)
{
    int retval;
    int playdepth_save;
    short *slevel;
    retval = 0;
    playdepth_save = playdepth;
    slevel = level;
    playdepth = 2;
    MoveFunction = 1;
    if (level[148] == 0x00)
        slevel[146>>1] = 0x7fff;
    else
        slevel[146>>1] = -0x7fff;
    level[152] = 0;
    level[153] = 0;
    AnalyzeAllMoves(level);
    //printf("slevel[146>>1] = %d\n", slevel[146>>1]);
    if (slevel[146>>1] > 5000 || slevel[146>>1] < -5000)
    {
        printf("CHECKMATE\n");
        retval = 1;
    }
    playdepth = playdepth_save;
    return retval;
}

// Analyze all possible moves and select the best one
int PerformComputerMove(unsigned char *level)
{
    int value;
    short *slevel;
    slevel = level;

    MoveFunction = 1;
    if (level[148] == 0x00)
        slevel[146>>1] = 0x7fff;
    else
        slevel[146>>1] = -0x7fff;
    //printf("PerformComputerMove: slevel[146>>1] = %d\n", slevel[146>>1]);
    level[152] = 0;
    level[153] = 0;
    AnalyzeAllMoves(level);

    // Check if best_old was updated, which indicates at least one move
    if (level[152])
    {
        if (level[152] == level[153])
            printf("STALEMATE\n");
        level[150] = level[152];
        level[151] = level[153];
        PerformMove(level);
    }
    else
    {
        printf("Couldn't find a move\n");
        printf("STALEMATE\n");
    }
    value = BoardValue(level);
    if (value > 5000 || value < -5000)
    {
        //printf("value = %d\n", value);
        printf("CHECKMATE\n");
        return 0;
    }
    if (movenum > 200)
    {
        printf("STALEMATE\n");
        return 0;
    }
    if (level[148])
        printf("White's Move %d: ", ++movenum);
    else
        printf("Blacks's Move %d: ", movenum);
    printf(" %s", PositionToString(level[152]));
    printf("-%s\n", PositionToString(level[153]));
    return 1;
}

// Check if the person's intended move matches any generated moves
void CheckPersonMove(unsigned char *level)
{
    unsigned char next_level[160];

    // Is there a match?
    if ((level[150] == person_old) && (person_new == level[151]))
    {
        InitializeNextLevel(level, next_level);
        PerformMove(next_level);
        if (!IsCheck(next_level))
        {
            validmove = 1;
            memcpy(level, next_level, 160);
        }
    }
}

// Prompt for a move and check if it's valid
int PerformPersonMove(unsigned char *level)
{
    unsigned char next_level[160];
    validmove = 0;
    if (level[148])
        movenum++;

    // Loop until we get a valid move
    while (!validmove)
    {
        if (level[148])
            printf("White's Move %d: ", movenum);
        else
            printf("Blacks's Move %d: ", movenum);
        gets(inbuf);
        if (toupper(inbuf[0]) == 'Q') return 0;
        person_old = StringToPostion(inbuf);
        person_new = StringToPostion(inbuf + 3);
        if (person_old >= 0 && person_new >= 0 && inbuf[2] == '-')
        {
            MoveFunction = 2;
            level[150] = person_old;
            memcpy(next_level, level, 160);
            MoveIfMyPiece(next_level);
        }
    }

    next_level[149] = 0;
    memcpy(level, next_level, 160);
    return 1;
}

// Prompt person for color, and set the computer's color
void GetColor()
{
    printf("Do you want White (Y/N): ");
    gets(inbuf);
    //compcolor = (toupper(inbuf[0]) == 'Y') ? 0x00 : 0x80;
    if (toupper(inbuf[0]) == 'Y')
        compcolor = 0;
    else
        compcolor = 0x80;
}

// Prompt for the playing level
void GetPlayLevel()
{
    playdepth = 0;
    while (playdepth < 1 || playdepth > 5)
    {
        printf("Enter Play Level (1-%d): ", 5);
        gets(inbuf);
        sscanf(inbuf, "%d", &playdepth);
    }
}

void Initialize(unsigned char *level)
{
    unsigned char *ptr;
    short *slevel;
    ptr = level + ((12 * 2) + 2);
    slevel = level;
    memset(level, 0xff, (12 * 12));
    memcpy(ptr, black_rank, 8);
    memset(ptr + 12, 0x00 | 1, 8);
    memset(ptr + (12 * 2), 0, 8);
    memset(ptr + (12 * 3), 0, 8);
    memset(ptr + (12 * 4), 0, 8);
    memset(ptr + (12 * 5), 0, 8);
    memset(ptr + (12 * 6), 0x80 | 1, 8);
    memcpy(ptr + (12 * 7), white_rank, 8);
    movenum = 0;
    level[149] = 0;
    level[148] = 0x80;
    slevel[144>>1] = 0;
    level[154] = ((12 * 9) + 2) + 4;
    level[155] = ((12 * 2) + 2) + 4;
    level[156] = 0;
}

int PlayChess()
{
    int retval;
    unsigned char level[160];
    GetPlayLevel();
    printf("Do you want to play against the computer? (Y/N): ");
    gets(inbuf);
    human_playing = (toupper(inbuf[0]) == 'Y');
    if (human_playing)
        GetColor();
    else
        compcolor = 0x80;
    Initialize(level);
    PrintBoard(level);
    while (1)
    {
        //printf("compcolor = %d, level[148] = %d\n", compcolor, level[148]);
        if (compcolor == level[148])
            retval = PerformComputerMove(level);
        else
            retval = PerformPersonMove(level);
        if (!retval) return 1;
        PrintBoard(level);
        if (IsCheck(level))
            printf("Illegal move into check %d\n", level[148]);
        ChangeColor(level);
        if (IsCheck(level))
        {
            if (IsCheckMate(level)) break;
            printf("CHECK\n\n");
        }
        if (!human_playing)
            compcolor ^= 0x80;
    }
    return 0;
}

// Call the appropriate move function based on the function number
void CallMoveFunction(int funcnum, unsigned char *level)
{
    if (funcnum == 1)
        AnalyzeMove(level);
    else if (funcnum == 2)
        CheckPersonMove(level);
    else if (funcnum == 4)
        Pawn(level);
    else if (funcnum == 5)
        Knight(level);
    else if (funcnum == 6)
        Bishop(level);
    else if (funcnum == 7)
        Rook(level);
    else if (funcnum == 8)
        Queen(level);
    else if (funcnum == 9)
        King(level);
    else
        Invalid(level);
}

int main()
{
    printf("P2 Chess\n");
    symbols = "xPNBRQKx";
    pos_values[0] = null_values;
    pos_values[1] = pawn_values;
    pos_values[2] = knight_values;
    pos_values[3] = bishop_values;
    pos_values[4] = null_values;
    pos_values[5] = null_values;
    pos_values[6] = king_values;
    pos_values[7] = null_values;
    srand(1);
    while (1)
    {
        if (PlayChess()) break;
    }
    return 1;
}

//+--------------------------------------------------------------------
//|  TERMS OF USE: MIT License
//+--------------------------------------------------------------------
//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files
//(the "Software"), to deal in the Software without restriction,
//including without limitation the rights to use, copy, modify, merge,
//publish, distribute, sublicense, and/or sell copies of the Software,
//and to permit persons to whom the Software is furnished to do so,
//subject to the following conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//+------------------------------------------------------------------
