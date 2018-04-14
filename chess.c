/*
############################################################################
# This program implements the game of chess on a processor that has multiple
# cores.  It works by generating a list of moves, and then each core will
# get a move from the list and evaluate it.  This is done by using pthreads,
# where each pthread is mapped to an additional core.  The number of
# pthreads is determined by NUM_PTHREADS.  For a dual-core x86 processor,
# NUM_PTHREADS is set to 1.  The main thread runs on one core, and the
# pthread runs on the second core.  Setting NUM_PTHREADS to 0 will cause the
# program to run a single-threaded mode without using pthreads.
#
# This program also run on the Parallax Propeller processor, and uses 6 of
# the 8 cogs that are available.  The number of cogs used is limited by the
# amount of hub memory available.
#
# Copyright (c) 2013, Dave Hein
# MIT Licensed
############################################################################
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#ifdef __PROPELLER__
#include <propeller.h>

#define MAX_DEPTH 4
#define NUM_PTHREADS 0
#define PTHREAD_STACKSIZE 1176
#else
#define MAX_DEPTH 5
#define NUM_PTHREADS 1
#endif

#define uchar unsigned char

#define BOARD_BORDER   2
#define BOARD_WIDTH   12
#define BOARD_HEIGHT  12
#define BOARD_SIZE    (BOARD_WIDTH * BOARD_HEIGHT)

#define OUT_OF_BOUNDS 0xff
#define PIECE_MASK    0x07
#define COLOR_MASK    0x80
#define WHITE         0x80
#define BLACK         0x00
#define PIECE_MOVED   0x40

#define POSITION_A8   ((BOARD_WIDTH * 2) + 2)
#define POSITION_H8   ((BOARD_WIDTH * 2) + 9)
#define POSITION_A1   ((BOARD_WIDTH * 9) + 2)
#define POSITION_D5   ((BOARD_WIDTH * 5) + 5)
#define POSITION_E5   ((BOARD_WIDTH * 5) + 6)
#define POSITION_D4   ((BOARD_WIDTH * 6) + 5)
#define POSITION_E4   ((BOARD_WIDTH * 6) + 6)

// Piece numbers
#define PAWN          1
#define KNIGHT        2
#define BISHOP        3
#define ROOK          4
#define QUEEN         5
#define KING          6

// Directions
#define N  (-BOARD_WIDTH)
#define S  BOARD_WIDTH
#define E  1
#define W  (-1)
#define NW (N + W)
#define SW (S + W)
#define NE (N + E)
#define SE (S + E)
#define NNW (N + N + W)
#define NNE (N + N + E)
#define SSW (S + S + W)
#define SSE (S + S + E)
#define WSW (W + S + W)
#define WNW (W + N + W)
#define ESE (E + S + E)
#define ENE (E + N + E)

typedef struct levelS {
    uchar board[BOARD_SIZE];
    short value;
    short best_value;
    uchar color;
    uchar depth;
    uchar old_pos;
    uchar new_pos;
    uchar best_old;
    uchar best_new;
    uchar wking_pos;
    uchar bking_pos;
    uchar en_passant;
} levelT;

typedef void (*FuncPtr)(levelT *);

// Function prototypes
void PerformMove(levelT *level);
void QueueUpMove(levelT *level);
void AnalyzeMoveQueue(levelT *level);
void StartPthreads(void);
void GenerateQueuedMoves(levelT *level);

char *symbols = "xPNBRQKx";

// Directions that the pieces can move
int king_moves[8] = {SW, SE, NW, NE, W, S, E, N};
int knight_moves[8] = {NNE, ENE, ESE, SSE, SSW, WSW, WNW, NNW};

// The piece values
int values[] = { 0, 20, 64, 65, 100, 195, 10000, 0};

// Pawn position values
signed char pawn_values[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0, 10, 10, 10, 10, 10, 10, 10, 10,  0,  0,
    0,  0,  2,  2,  4,  6,  6,  4,  2,  2,  0,  0,
    0,  0,  1,  1,  2,  6,  6,  2,  1,  1,  0,  0,
    0,  0,  0,  0,  0,  5,  5,  0,  0,  0,  0,  0,
    0,  0,  1, -1, -2,  0,  0, -2, -1,  1,  0,  0,
    0,  0,  1,  2,  2, -5, -5,  2,  2,  1,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 };

// Knight position values
signed char knight_values[] = {
    0,  0,-10, -8  -6, -6, -6, -6, -8,-10,  0,  0,
    0,  0, -8, -4,  0,  0,  0,  0, -4, -8,  0,  0,
    0,  0, -6,  0,  2,  3,  3,  2,  0, -6,  0,  0,
    0,  0, -6,  1,  3,  4,  4,  3,  1, -6,  0,  0,
    0,  0, -6,  0,  3,  4,  4,  3,  0, -6,  0,  0,
    0,  0, -6,  1,  2,  3,  3,  2,  1, -6,  0,  0,
    0,  0, -8, -4,  0,  1,  1,  0, -4, -8,  0,  0,
    0,  0,-10, -8  -4, -6, -6, -4, -8,-10,  0,  0};

// Bishop position values
signed char bishop_values[] = {
    0,  0, -4, -2, -2, -2, -2, -2, -2, -4,  0,  0,
    0,  0, -2,  0,  0,  0,  0,  0,  0, -2,  0,  0,
    0,  0, -2,  0,  1,  2,  2,  1,  0, -2,  0,  0,
    0,  0, -2,  1,  1,  2,  2,  1,  1, -2,  0,  0,
    0,  0, -2,  0,  2,  2,  2,  2,  0, -2,  0,  0,
    0,  0, -2,  2,  2,  2,  2,  2,  2, -2,  0,  0,
    0,  0, -2,  1,  0,  0,  0,  0,  1, -2,  0,  0,
    0,  0, -4, -2, -8, -2, -2, -8, -2, -4,  0,  0};

// King position values
signed char king_values[] = {
    0,  0, -6, -8, -8,-10,-10, -8, -8, -6,  0,  0,
    0,  0, -6, -8, -8,-10,-10, -8, -8, -6,  0,  0,
    0,  0, -6, -8, -8,-10,-10, -8, -8, -6,  0,  0,
    0,  0, -6, -8, -8,-10,-10, -8, -8, -6,  0,  0,
    0,  0, -4, -6, -6, -8, -8, -6, -6, -4,  0,  0,
    0,  0, -2, -4, -4, -4, -4, -4, -4, -2,  0,  0,
    0,  0,  4,  4,  0,  0,  0,  0,  4,  4,  0,  0,
    0,  0,  4,  6,  2,  0,  0,  2,  6,  4,  0,  0};

// Null position values used for the queen and rooks
signed char null_values[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0 };

signed char *pos_values[8] = { null_values, pawn_values, knight_values,
bishop_values, null_values, null_values, king_values, null_values};

uchar black_rank[8] = {ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK};
uchar white_rank[8] = {ROOK | WHITE, KNIGHT | WHITE, BISHOP | WHITE,
    QUEEN | WHITE, KING | WHITE, BISHOP | WHITE, KNIGHT | WHITE, ROOK | WHITE};

// Global variables
FuncPtr MoveFunction;  // Function that is called for each move
int movenum;           // current move number
int person_old;        // postion selected by person to move from
int person_new;        // postion selected by person to move to
int playdepth;         // number of moves to look ahead
int validmove;         // indicates if a human's move is valid
int compcolor;         // color that the computer is playing
int human_playing;     // indicates that a person is playing
char inbuf[80];        // buffer for human input

// Prepare to search the next level
static void InitializeNextLevel(levelT *level, levelT *next_level)
{
    memcpy(next_level, level, sizeof(levelT)); // copy board to next level.
    next_level->depth++;
}

static void ChangeColor(levelT *level)
{
    level->color ^= COLOR_MASK;
}

static int BoardValue(levelT *level)
{
    return level->value;
}

// Convert a numeric position value to a string
char *PositionToString(int position)
{
    int row, col;
    static char str[3];

    row = position / BOARD_WIDTH;
    col = position % BOARD_WIDTH;

    str[0] = col - 2 + 'a';
    str[1] = 10 - row + '0';
    str[2] = 0;

    return str;
}

// Convert a postion string to a numeric value
int StringToPostion(char *str)
{
    unsigned int col = tolower(str[0]) - 'a';
    unsigned int row = str[1] - '1';

    if (col > 7 || row > 7) return -1;
    return (7 - row + 2) * BOARD_WIDTH + col + 2;
}

// Print the board
void PrintBoard(levelT *level)
{
    int i, j;
    uchar *ptr = level->board + (BOARD_WIDTH * BOARD_BORDER);

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
                printf("|%c", symbols[ptr[j] & PIECE_MASK]);
                if (ptr[j] & COLOR_MASK)
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
        ptr += BOARD_WIDTH;
    }
    printf("\n-+--+--+--+--+--+--+--+--+");
    printf("\n\n");
}

// Determine if the board position contains the current color's piece
int IsMyPiece(levelT *level, int offs)
{
    uchar *brd = level->board;

    if (brd[offs] == 0) return 0;
    if (brd[offs] == OUT_OF_BOUNDS) return 0;
    return ((brd[offs] & COLOR_MASK) == level->color);
}

// Determine if the board position contains the other color's piece
int IsOtherPiece(levelT *level, int offs)
{
    uchar *brd = level->board;

    if (brd[offs] == 0) return 0;
    if (brd[offs] == OUT_OF_BOUNDS) return 0;
    return ((brd[offs] & COLOR_MASK) != level->color);
}

// Determine if the board position does not contain the
// current color's piece and is in bounds.
int IsMoveOK(levelT *level, int offs)
{
    uchar *brd = level->board;
    return (!IsMyPiece(level, offs) && brd[offs] != OUT_OF_BOUNDS);
}

// Generate moves in a certain direction for a bishop, rook or queen
void AnalyzeDirectionalMoves(levelT *level, int direction)
{
    uchar *brd = level->board;

    level->new_pos = level->old_pos;
    while (1)
    {
        level->new_pos += direction;
        if (IsMyPiece(level, level->new_pos) || brd[level->new_pos] == OUT_OF_BOUNDS) break;
        (*MoveFunction)(level);
        if (brd[level->new_pos] != 0) break;
    }
}

// Determine if the king's space is under attack
int IsCheck(levelT *level)
{
    int color = level->color;
    uchar *king_ptr = level->board;
    int i, row_step, offs, incr, flags, piece;

    if (color)
    {
        row_step = -BOARD_WIDTH;
        king_ptr += level->wking_pos;
    }
    else
    {
        row_step = BOARD_WIDTH;
        king_ptr += level->bking_pos;
    }

    color ^= COLOR_MASK;

    // Check for pawns
    if ((king_ptr[row_step + 1] & (COLOR_MASK | PIECE_MASK)) == (color | PAWN))
        return 1;

    if ((king_ptr[row_step - 1] & (COLOR_MASK | PIECE_MASK)) == (color | PAWN))
        return 1;

    // Check for knights
    for (i = 0; i < 8; i++)
    {
        if ((king_ptr[knight_moves[i]] & (COLOR_MASK | PIECE_MASK)) == (color | KNIGHT))
            return 1;
    }

    // Check for king, queen, bishop or rook
    for (i = 0; i < 8; i++)
    {
        offs = incr = king_moves[i];

        if ((king_ptr[offs] & (COLOR_MASK | PIECE_MASK)) == (color | KING))
            return 1;

        while (king_ptr[offs] == 0)
            offs += incr;

        flags = king_ptr[offs];

        if ((flags & COLOR_MASK) != color)
            continue;

        piece = flags & PIECE_MASK;

        if (piece == QUEEN)
            return 1;

        if (i < 4)
        {
            if (piece == BISHOP)
                return 1;
        }
        else
        {
            if (piece == ROOK)
                return 1;
        }
    }
    return 0;
}

// This routine catches invalid piece values, and should never be called
void Invalid(levelT *level)
{
    printf("Invalid piece\n");
    exit(1);
}

// Generate all possible moves for a pawn
void Pawn(levelT *level)
{
    int row_step = BOARD_WIDTH;
    uchar *brd = level->board;

    if (level->color)
        row_step = -BOARD_WIDTH;

    // Check capture to the left
    level->new_pos = level->old_pos - 1 + row_step;
    if (IsOtherPiece(level, level->new_pos) || level->en_passant == level->old_pos - 1)
        (*MoveFunction)(level);

    // Check capture to the right
    level->new_pos += 2;
    if (IsOtherPiece(level, level->new_pos) || level->en_passant == level->old_pos + 1)
        (*MoveFunction)(level);

    // Check moving forward one space
    level->new_pos -= 1;
    if (IsMoveOK(level, level->new_pos) && !IsOtherPiece(level, level->new_pos))
        (*MoveFunction)(level);
    else
        return;

    // Check moving forward two spaces
    if (brd[level->old_pos] & PIECE_MOVED)
        return;

    level->new_pos += row_step;
    if (IsMoveOK(level, level->new_pos) && !IsOtherPiece(level, level->new_pos))
        (*MoveFunction)(level);
}

// Generate all possible moves for a knight
void Knight(levelT *level)
{
    int i;
    uchar *brd = level->board;

    for (i = 0; i < 8; i++)
    {
        level->new_pos = level->old_pos + knight_moves[i];
        if (IsMoveOK(level, level->new_pos))
            (*MoveFunction)(level);  // then generate move
    }
}

// Generate all possible moves for a bishop
void Bishop(levelT *level)
{
    int i;

    for (i = 0; i < 4; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Generate all possible moves for a rook
void Rook(levelT *level)
{
    int i;
    uchar *brd = level->board;

    for (i = 4; i < 8; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Generate all possible moves for a queen
void Queen(levelT *level)
{
    int i;

    for (i = 0; i < 8; i++)
        AnalyzeDirectionalMoves(level, king_moves[i]);
}

// Determine if this space is under attack
int IsSpaceUnderAttack(levelT *level, int position)
{
    int retval, king_pos;

    if (level->color)
    {
        king_pos = level->wking_pos;
        level->wking_pos = position;
        retval = IsCheck(level);
        level->wking_pos = king_pos;
    }
    else
    {
        king_pos = level->bking_pos;
        level->bking_pos = position;
        retval = IsCheck(level);
        level->bking_pos = king_pos;
    }

    return retval;
}

void CastleRight(levelT *level)
{
    uchar *brd = level->board;
    int old_pos = level->old_pos;

    if (brd[old_pos + 1]) return;
    if (brd[old_pos + 2]) return;
    if (brd[old_pos + 3] & PIECE_MOVED) return;
    if (IsCheck(level)) return;
    if (IsSpaceUnderAttack(level, level->old_pos + 1)) return;
    level->new_pos = level->old_pos + 2;
    (*MoveFunction)(level);
}

void CastleLeft(levelT *level)
{
    uchar *brd = level->board;
    int old_pos = level->old_pos;

    if (brd[old_pos - 1]) return;
    if (brd[old_pos - 2]) return;
    if (brd[old_pos - 3]) return;
    if (brd[old_pos - 4] & PIECE_MOVED) return;
    if (IsCheck(level)) return;
    if (IsSpaceUnderAttack(level, level->old_pos - 1)) return;
    level->new_pos = level->old_pos - 2;
    (*MoveFunction)(level);
}

// Generate all possible moves for a king
void King(levelT *level)
{
    int i;
    uchar *brd = level->board;

    // Check 8 single-space moves
    for (i = 0; i < 8; i++)
    {
        level->new_pos = level->old_pos + king_moves[i];
        if (IsMoveOK(level, level->new_pos))
            (*MoveFunction)(level);
    }

    // Check castling
    if (!(brd[level->old_pos] & PIECE_MOVED))
    {
        CastleRight(level);
        CastleLeft(level);
    }
}

FuncPtr PieceFunctions[8] = {Invalid, Pawn, Knight, Bishop, Rook, Queen, King, Invalid};

// Call the piece move generator function if this the color is correct
void MoveIfMyPiece(levelT *level)
{
    int piece;
    uchar *brd = level->board;

    if (IsMyPiece(level, level->old_pos))
    {
        piece = brd[level->old_pos] & PIECE_MASK;
        (*PieceFunctions[piece])(level);
    }
}

// Generate all moves on the board and analyze them
void AnalyzeAllMoves(levelT *level)
{
    int row, col, rowinc;

    if (level->color == BLACK)
    {
        level->old_pos = POSITION_A8; // start at the left top
        rowinc = BOARD_WIDTH - 8;
    }
    else
    {
        level->old_pos = POSITION_A1; // start at the left bottom
        rowinc = -BOARD_WIDTH - 8;
    }

    for (row = 0; row < 8; row++)
    {
        for (col = 0; col < 8; col++)
        {
            MoveIfMyPiece(level);
            level->old_pos++;
        }
        level->old_pos += rowinc;
    }
}

// Remove a piece from the board and subtract its value
void RemovePiece(levelT *level, int position)
{
    uchar *brd = level->board;
    int entry = brd[position];
    int piece = entry & PIECE_MASK;
    int value = values[piece];

    if (entry == 0) return;

    if (entry == OUT_OF_BOUNDS)
    {
        printf("RemovePiece: %d is out of bounds\n", position);
        exit(1);
    }

    if (entry & COLOR_MASK)
    {
        value += pos_values[piece][position - (2 * BOARD_WIDTH)];
        level->value -= value;
    }
    else
    {
        value += pos_values[piece][(BOARD_WIDTH * 10) - 1 - position];
        level->value += value;
    }

    brd[position] = 0;
}

// Add a piece to the board and add its value
void AddPiece(levelT *level, int position, int entry)
{
    uchar *brd = level->board;
    int piece = entry & PIECE_MASK;
    int value = values[piece];

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

    if (entry & COLOR_MASK)
    {
        value += pos_values[piece][position - (2 * BOARD_WIDTH)];
        level->value += value;
    }
    else
    {
        value += pos_values[piece][(BOARD_WIDTH * 10) - 1 - position];
        level->value -= value;
    }

    brd[position] = entry | PIECE_MOVED;
}

// Move a piece from one place to another and adjust the board's value
void MovePiece(levelT *level, int old_pos, int new_pos)
{
    uchar *brd = level->board;
    int entry1 = brd[old_pos];
    int entry2 = brd[new_pos];
    int piece = entry1 & PIECE_MASK;
    int value = values[piece];

    if (entry1 == 0) return;

    if (entry1 == OUT_OF_BOUNDS)
    {
        printf("MovePiece: %d is out of bounds\n", old_pos);
        exit(1);
    }

    if (entry2)
        RemovePiece(level, new_pos);

    RemovePiece(level, old_pos);
    AddPiece(level, new_pos, entry1);
}

// Move a piece and remove an opponent's piece if taken
// Check for castling, en passant capture and pawn promotion
void PerformMove(levelT *level)
{
    uchar *brd = level->board;
    int val1 = brd[level->old_pos];
    int val2 = brd[level->new_pos];
    int en_passant = level->en_passant;
    int value = values[val2 & PIECE_MASK];

    // Clear en_passant flag.  May be set later.
    level->en_passant = 0;

    // Check if taking opponent's piece
    if (val2) RemovePiece(level, level->new_pos);

    // Check if moving king
    if ((val1 & PIECE_MASK) == KING)
    {
        // Update it's position
        if (val1 & COLOR_MASK)
            level->wking_pos = level->new_pos;
        else
            level->bking_pos = level->new_pos;

        // Check for castle right
        if (level->new_pos == level->old_pos + 2)
        {
            if (level->depth == 0) printf("CASTLE RIGHT\n\n");
            MovePiece(level, level->old_pos + 3, level->old_pos + 1);
        }
        
        // Check for castle left
        if (level->new_pos == level->old_pos - 2)
        {
            if (level->depth == 0) printf("CASTLE LEFT\n\n");
            MovePiece(level, level->old_pos - 4, level->old_pos - 1);
        }
    }

    if ((val1 & PIECE_MASK) == PAWN)
    {
        if (val1 & COLOR_MASK)
        {
            // Set the en passant flag if moving pawn two spaces
            if (level->new_pos == level->old_pos - (2 * BOARD_WIDTH))
            {
                level->en_passant = level->new_pos;
            }
            // Check for en passant capture
            else if (level->new_pos == en_passant - BOARD_WIDTH)
            {
                if (level->depth == 0) printf("EN PASSANT\n\n");
                RemovePiece(level, en_passant);
            }
            // Promote pawn to queen if reaching final rank
            else if (level->new_pos <= POSITION_H8)
            {
                RemovePiece(level, level->old_pos);
                AddPiece(level, level->new_pos, WHITE | QUEEN);
                return;
            }
        }
        else
        {
            // Set the en passant flag if moving pawn two spaces
            if (level->new_pos == level->old_pos + (2 * BOARD_WIDTH))
            {
                level->en_passant = level->new_pos;
            }
            // Check for en passant capture
            else if (level->new_pos == en_passant + BOARD_WIDTH)
            {
                if (level->depth == 0) printf("EN PASSANT\n\n");
                RemovePiece(level, en_passant);
            }
            // Promote pawn to queen if reaching final rank
            else if (level->new_pos >= POSITION_A1)
            {
                RemovePiece(level, level->old_pos);
                AddPiece(level, level->new_pos, BLACK | QUEEN);
                return;
            }
        }
    }

    MovePiece(level, level->old_pos, level->new_pos);
}

#ifdef DEBUG
int IsBoardValid(levelT *level)
{
    int row, col;
    uchar *ptr = level->board;

    for (row = 0; row < BOARD_HEIGHT; row++)
    {
        for (col = 0; col < BOARD_WIDTH; col++)
        {
            if (*ptr == 0) {}
            else if (*ptr == OUT_OF_BOUNDS)
            {
                if (row >= 2 && row < 10 && col >= 2 && col < 10)
                    return 0;
            }
            else if (*ptr == 0x80)
                return 0;
            else if (*ptr & 0x38)
                return 0;
            else if (((*ptr) & PIECE_MASK) == 7)
                return 0;
            ptr++;
        }
    }
    return 1;
}
#endif

// Analyze move from old_pos to new_pos.  If we have reached the maximum depth
// check if the board value is better than the values from the previous moves.
// If we have not reached the maximum depth, determine the best counter-move
// at the next level, and check if better than any previous move.
// In the case of a tie, pick the new move 25% of the time.
void AnalyzeMove(levelT *level)
{
    levelT next_level;
    int update, value;
    uchar *ptr = level->board;

    if (ptr[level->old_pos] == OUT_OF_BOUNDS || ptr[level->new_pos] == OUT_OF_BOUNDS)
    {
        printf("BAD MOVE: %2.2x-%2.2x\n", level->old_pos, level->new_pos);
        exit(0);
    }

    InitializeNextLevel(level, &next_level);
    PerformMove(&next_level);

    if (IsCheck(&next_level)) return;

#ifdef DEBUG
    if (!IsBoardValid(level))
    {
        printf("BAD BOARD!\n");
        exit(0);
    }
#endif

    value = BoardValue(&next_level);

    // Stop searching if checkmate
    if (value > 5000 || value < -5000)
    {
        level->best_value = value;
        level->best_old = level->old_pos;
        level->best_new = level->new_pos;
    }
    else if (next_level.depth == playdepth)
    {
        if (level->color)
            update = (value > level->best_value);
        else
            update = (value < level->best_value);

        if (update)
        {
            level->best_value = value;
            level->best_old = level->old_pos;
            level->best_new = level->new_pos;
        }
    }
    else
    {
        ChangeColor(&next_level);
        if (next_level.color == BLACK)
            next_level.best_value = 0x7fff;
        else
            next_level.best_value = -0x7fff;
        next_level.best_old = 0;
        next_level.best_new = 0;

        AnalyzeAllMoves(&next_level);

        if (!next_level.best_old)
        {
            // Check for check
            if (IsCheck(&next_level))
            {
                if (level->color)
                    next_level.best_value = 10000;
                else
                    next_level.best_value = -10000;
            }
            else
                next_level.best_value = 0;  // Should go for draw only if way behind
        }

        value = next_level.best_value;

        if (value == level->best_value)
        {
            update = ((rand() & 3) == 0);
        }
        else
        {
            if (level->color)
                update = (value > level->best_value);
            else
                update = (value < level->best_value);
        }

        if (update)
        {
            level->best_value = value;
            level->best_old = level->old_pos;
            level->best_new = level->new_pos;
        }
    }
}

int IsCheckMate(levelT *level)
{
    int retval = 0;
    int playdepth_save = playdepth;

    playdepth = 2;

    MoveFunction = AnalyzeMove;
    if (level->color == BLACK)
        level->best_value = 0x7fff;
    else
        level->best_value = -0x7fff;
    level->best_old = 0;
    level->best_new = 0;

    AnalyzeAllMoves(level);

    if (level->best_value > 5000 || level->best_value < -5000)
    {
        printf("CHECKMATE\n");
        retval = 1;
    }

    playdepth = playdepth_save;
    
    return retval;
}

// Analyze all possible moves and select the best one
int PerformComputerMove(levelT *level)
{
    int value;

#if NUM_PTHREADS
    GenerateQueuedMoves(level);
#endif

    MoveFunction = AnalyzeMove;
    if (level->color == BLACK)
        level->best_value = 0x7fff;
    else
        level->best_value = -0x7fff;
    level->best_old = 0;
    level->best_new = 0;

#if NUM_PTHREADS
    AnalyzeMoveQueue(level);
#else
    AnalyzeAllMoves(level);
#endif

    // Check if best_old was updated, which indicates at least one move
    if (level->best_old)
    {
        if (level->best_old == level->best_new)
            printf("STALEMATE\n");
        level->old_pos = level->best_old;
        level->new_pos = level->best_new;
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
        printf("CHECKMATE\n");
        return 0;
    }

    if (movenum > 200)
    {
        printf("STALEMATE\n");
        return 0;
    }

    if (level->color)
        printf("White's Move %d: ", ++movenum);
    else
        printf("Blacks's Move %d: ", movenum);
    printf(" %s", PositionToString(level->best_old));
    printf("-%s\n", PositionToString(level->best_new));
    // printf("value = %d, best_value = %d\n", value, level->best_value);

    return 1;
}

// Check if the person's intended move matches any generated moves
void CheckPersonMove(levelT *level)
{
    levelT next_level;

    // Is there a match?
    if ((level->old_pos == person_old) && (person_new == level->new_pos))
    {
        InitializeNextLevel(level, &next_level);
        PerformMove(&next_level);
        if (!IsCheck(&next_level))
        {
            validmove = 1;
            memcpy(level, &next_level, sizeof(levelT));
        }
    }
}

static void CheckExit(char *ptr)
{
    if (!strcmp(ptr, "exit")) exit(0);
    if (!strcmp(ptr, "EXIT")) exit(0);
}

// Prompt for a move and check if it's valid
int PerformPersonMove(levelT *level)
{
    levelT next_level;

    validmove = 0;

    if (level->color)
        movenum++;

    // Loop until we get a valid move
    while (!validmove)
    {
        if (level->color)
            printf("White's Move %d: ", movenum);
        else
            printf("Blacks's Move %d: ", movenum);

        gets(inbuf);
        CheckExit(inbuf);
        if (toupper(inbuf[0]) == 'Q') return 0;

        person_old = StringToPostion(inbuf);
        person_new = StringToPostion(inbuf + 3);

        if (person_old >= 0 && person_new >= 0 && inbuf[2] == '-')
        {
            MoveFunction = CheckPersonMove;
            level->old_pos = person_old;
            memcpy(&next_level, level, sizeof(levelT));
            MoveIfMyPiece(&next_level);
        }
    }

    next_level.depth = 0;
    memcpy(level, &next_level, sizeof(levelT));
    
    return 1;
}

// Prompt person for color, and set the computer's color
static void GetColor()
{
    printf("Do you want White (Y/N): ");
    gets(inbuf);
    CheckExit(inbuf);
    compcolor = (toupper(inbuf[0]) == 'Y') ? BLACK : WHITE;
}

// Prompt for the playing level
static void GetPlayLevel()
{
    playdepth = 0;
    while (playdepth < 1 || playdepth > MAX_DEPTH)
    {
        printf("Enter Play Level (1-%d): ", MAX_DEPTH);
        gets(inbuf);
        CheckExit(inbuf);
        playdepth = atoi(inbuf);
    }
}

void Initialize(levelT *level)
{
    uchar *ptr = level->board + POSITION_A8;

    memset(level->board, OUT_OF_BOUNDS, BOARD_SIZE);

    memcpy(ptr, black_rank, 8);
    memset(ptr + BOARD_WIDTH, BLACK | PAWN, 8);
    memset(ptr + (BOARD_WIDTH * 2), 0, 8);
    memset(ptr + (BOARD_WIDTH * 3), 0, 8);
    memset(ptr + (BOARD_WIDTH * 4), 0, 8);
    memset(ptr + (BOARD_WIDTH * 5), 0, 8);
    memset(ptr + (BOARD_WIDTH * 6), WHITE | PAWN, 8);
    memcpy(ptr + (BOARD_WIDTH * 7), white_rank, 8);

    movenum = 0;
    level->depth = 0;
    level->color = WHITE;
    level->value = 0;
    level->wking_pos = POSITION_A1 + 4;
    level->bking_pos = POSITION_A8 + 4;
    level->en_passant = 0;
}

void PlayChess()
{
    int retval;
    levelT level;
    
    GetPlayLevel();
    printf("Do you want to play against the computer? (Y/N): ");
    gets(inbuf);
    CheckExit(inbuf);
    human_playing = (toupper(inbuf[0]) == 'Y');

    if (human_playing)
        GetColor();
    else
        compcolor = WHITE;

    Initialize(&level);
    PrintBoard(&level);

    while (1)
    {
        if (compcolor == level.color)
            retval = PerformComputerMove(&level);
        else
            retval = PerformPersonMove(&level);
            
        if (!retval) return;

        PrintBoard(&level);
        if (IsCheck(&level))
            printf("Illegal move into check %d\n", level.color);
        ChangeColor(&level);
        if (IsCheck(&level))
        {
            if (IsCheckMate(&level)) break;
            printf("CHECK\n\n");
        }

        if (!human_playing)
            compcolor ^= COLOR_MASK;
    }
}

int main()
{
#ifdef __PROPELLER__    
    waitcnt(CNT+12000000);
#endif

    printf("Threaded Chess\n");
    
    srand(1);

#if NUM_PTHREADS
    StartPthreads();
#endif

    while (1)
        PlayChess();

    return 1;
}

// ****************************************************************
// Pthread code
// ****************************************************************
#if NUM_PTHREADS
int queue_max = 0;
int queue_num;
int queue_index;
uchar queue_old[200];
uchar queue_new[200];

#ifdef __PROPELLER__
int queue_lock;
#else
pthread_mutex_t queue_lock;
#endif
levelT thread_level[NUM_PTHREADS];
volatile int thread_active[NUM_PTHREADS];

pthread_t threads[NUM_PTHREADS];
#ifdef __PROPELLER__
int stacks[NUM_PTHREADS][PTHREAD_STACKSIZE/4];
int mainstackstart = 0;
int mainstackend;

void InitializeMainStack()
{
    int i;
    int retval = (int)malloc(4);
    
    if (retval)
    {
        mainstackstart = (retval & ~3) + 80;
        mainstackend = ((int)&retval) - 80;
        free((void *)retval);
        retval = (int)(&retval) - retval;
        for (i = mainstackstart; i < mainstackend; i += 4)
            *(int *)i = 0xdeadbeef; 
    }
    
    //printf("Main stack space = %d bytes\n", retval);
}

void CheckPthreadStacks()
{
    int i, j;

    for (j = mainstackstart; j < 0x8000; j += 4)
    {
        if (*(int *)j != 0xdeadbeef) break;
    }
    if (j - mainstackstart < 100)
        printf("Main stack space available = %d bytes\n", j - mainstackstart);
        
    for (i = 0; i < NUM_PTHREADS; i++)
    {
        for (j = 0; j < PTHREAD_STACKSIZE/4; j++)
        {
            if (stacks[i][j] != 0xdeadbeef) break;
        }
        if (j * 4 < 100)
            printf("Pthread %d stack space available = %d bytes\n", i, j * 4);
    }
}
#endif

void GenerateQueuedMoves(levelT *level)
{
    MoveFunction = QueueUpMove;
    queue_num = 0;
    AnalyzeAllMoves(level);
    if (queue_max < queue_num)
        queue_max = queue_num;
    // printf("%d moves queued, %d max queued\n", queue_num, queue_max);
}

static int GetQueuedItem()
{
    int index;
    
#ifdef __PROPELLER__
    while (lockset(queue_lock));
    index = queue_index;
    if (queue_index < queue_num) queue_index++;
    lockclr(queue_lock);
#else
    pthread_mutex_lock(&queue_lock);
    index = queue_index;
    if (queue_index < queue_num) queue_index++;
    pthread_mutex_unlock(&queue_lock);
#endif

    return index;
}

void ProcessMoveQueue(levelT *level)
{
    int index;

    while (1)
    {
        index = GetQueuedItem();
        if (index >= queue_num) break;
        level->old_pos = queue_old[index];
        level->new_pos = queue_new[index];
        (*MoveFunction)(level);
    }
}

// This routine is run in all the pthreads
void *ThreadFunc(void *arg)
{
    int instance = (int)arg;

    while (1)
    {
        usleep(1000);
        if (!thread_active[instance]) continue;
        ProcessMoveQueue(&thread_level[instance]);
        thread_active[instance] = 0;
    }

    return 0;
}

// This routine is run by the main thread
void AnalyzeMoveQueue(levelT *level)
{
    int index, update;

    queue_index = 0;

    // Copy level to other thread's level vars, and set active flag
    for (index = 0; index < NUM_PTHREADS; index++)
    {
        memcpy(&thread_level[index], level, sizeof(levelT));
        thread_active[index] = 1;
    }
    ProcessMoveQueue(level);
#if 0
        printf("Analyze %s", PositionToString(level->old_pos));
        printf("-%s\n", PositionToString(level->new_pos));
#endif

    // Wait for all the ptheads to finish
    while (1)
    {
        for (index = 0; index < NUM_PTHREADS; index++)
        {
            if (thread_active[index]) break;
        }
        if (index == NUM_PTHREADS) break;
    }
    
#ifdef __PROPELLER__
    CheckPthreadStacks();
#endif
    
    // Find the best move from the different threads
    for (index = 0; index < NUM_PTHREADS; index++)
    {
        if (level->color)
            update = (thread_level[index].best_value > level->best_value);
        else
            update = (thread_level[index].best_value < level->best_value);

        if (update)
        {
            level->best_value = thread_level[index].best_value;
            level->best_old   = thread_level[index].best_old;
            level->best_new   = thread_level[index].best_new;
        }
    }
}

#ifdef __PROPELLER__
void StartPthreads(void)
{
    int i, j;
    pthread_attr_t attr;

    for (i = 0; i < NUM_PTHREADS; i++)
    {
        thread_active[i] = 0;
        pthread_attr_init(&attr);
        pthread_attr_setstacksize(&attr, PTHREAD_STACKSIZE);
        pthread_attr_setstackaddr(&attr, stacks[i]);
        for (j = 0; j < PTHREAD_STACKSIZE/4; j++)
            stacks[i][j] = 0xdeadbeef;

        if (pthread_create(&threads[i], &attr, ThreadFunc, (void *)i))
        {
            printf("pthread_create %d failed\n", i);
            exit(1);
        }
    }

    InitializeMainStack();    
    queue_lock = locknew();
}
#else
void StartPthreads()
{
    int i;
    for (i = 0; i < NUM_PTHREADS; i++)
    {
        thread_active[i] = 0;
        if (pthread_create(&threads[i], 0, ThreadFunc, (void *)i))
        {
            printf("pthread_create %d failed\n", i);
            exit(1);
        }
    }
    pthread_mutex_init(&queue_lock, NULL);
}
#endif

void QueueUpMove(levelT *level)
{
    levelT next_level;
    uchar *ptr = level->board;

    if (ptr[level->old_pos] == OUT_OF_BOUNDS || ptr[level->new_pos] == OUT_OF_BOUNDS)
    {
        printf("BAD MOVE: %2.2x-%2.2x\n", level->old_pos, level->new_pos);
        exit(0);
    }

    InitializeNextLevel(level, &next_level);
    PerformMove(&next_level);

    if (IsCheck(&next_level)) return;

#ifdef DEBUG
    if (!IsBoardValid(level))
    {
        printf("BAD BOARD!\n");
        exit(0);
    }
#endif

    queue_old[queue_num] = level->old_pos;
    queue_new[queue_num] = level->new_pos;
    queue_num++;
}
#endif

/*
+--------------------------------------------------------------------
|  TERMS OF USE: MIT License
+--------------------------------------------------------------------
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
+------------------------------------------------------------------
*/
