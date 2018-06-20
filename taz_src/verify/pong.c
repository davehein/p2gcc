int height = 3;
int xmax = 78;
int xmin = 1;
int ymax = 22;
int ymin = 1;
int left = 0;
int right = 0;
int x = 0;
int y = 0;
int xvel = 0;
int yvel = 0;
int score0 = 0;
int score1 = 0;
int center = 0;
int xold = 1;
int yold = 1;
unsigned char digit[50] = {0x3f, 0x33, 0x33, 0x33, 0x3f, 0x0c, 0x1c, 0x0c,
    0x0c, 0x1e, 0x3f, 0x03, 0x3f, 0x30, 0x3f, 0x3f, 0x03, 0x0f, 0x03, 0x3f,
    0x33, 0x33, 0x3f, 0x03, 0x03, 0x3f, 0x30, 0x3f, 0x03, 0x3f, 0x3f, 0x30,
    0x3f, 0x33, 0x3f, 0x3f, 0x03, 0x06, 0x06, 0x06, 0x3f, 0x33, 0x3f, 0x33,
    0x3f, 0x3f, 0x33, 0x3f, 0x03, 0x03};

int isrflag = 0;
int isrval;
int isr_dummy;

void isr(unsigned int val, int count)
{
    inline("getct temp2");
    inline("add temp2, #25000000/115200");
    count = 8;
    while (count--)
    {
        inline("addct1 temp2, #50000000/115200");
        inline("waitct1");
        val = (val >> 1) | (inb & 0x80000000);
    }
    inline("addct1 temp2, #50000000/115200");
    inline("waitct1");
    isrval = val >> 24;
    isrflag = 1;
    inline("add sp, #4");
    inline("reti1");
}

void install_isr(void)
{
    int isr_address;
    isr_address = &isr_dummy;
    isr_address += 4;
    inline("rdlong ijmp1, sp"); // Move isr_address to ijmp1
    inline("setedg #$bf");      // Set up event for falling edge on pin 63
    inline("setint1 #5");       // Set interrupt 1 for edge event
}

int kbhit()
{
    return isrflag;
}

int getc_isr()
{
    while (!isrflag) {}
    isrflag = 0;
    return isrval;
}

int main(int argc,  char **argv)
{
  int time, deltat;
  install_isr();
  splash();
  initialize();
  deltat = 50000000 / 20;
  time = getcnt();
  while (1)
  {
    check_input();
    update_position();
    check_score();
    plotit(xold, yold, getval(xold, yold));
    plotit(x, y, '@');
    xold = x;
    yold = y;
    time += deltat;
    while ((getcnt() - time) < deltat) time = time;
  }
  putch(13);
  return 0;
}

int getcnt(void)
{
    inline("getct reg0");
}

// Initialize
void initialize(void)
{
  int i;
  putch(0);
  center = (xmin + xmax) / 2;
  x = 1;
  y = 10;
  xvel = 1;
  yvel = 1;
  left = (ymin + ymax) / 2;
  right = left;
  moveto(xmin - 1, ymin - 1);
  i = xmin - 1;
  while (i++ <= xmax + 1)
  {
    putch('#');
  }
  moveto(xmin - 1, ymax + 1);
  i = xmin - 1;
  while (i++ <= xmax + 1)
  {
    putch('#');
  }
  i = ymin;
  while (i <= ymax)
  {
    moveto(center, i);
    putch('.');
    i++;
  }
  plotpaddle(xmin - 1, left);
  plotpaddle(xmax + 1, right);
  putnum(center - 8, ymin + 1, 0);
  putnum(center + 3, ymin + 1, 0);
  moveto(xmin + 1, ymin);
}

void update_position(void)
{
  x += xvel;
  y += yvel;
  if (y < ymin)
  {
    y = ymin - y;
    yvel = 0 - yvel;
    putch(7);
  }
  else if ( y > ymax)
  {
    y = 2 * ymax - y;
    yvel = 0 - yvel;
    putch(7);
  }
}

void check_score(void)
{
  if (x <= xmin)
  {
    if (y <= left + height && y >= left - height)
    {
      x = 2 * xmin - x;
      xvel = 0 - xvel;
      putch(7);
    }
    else
    {
      scoreit(1);
    }
  }
  else if ( x >= xmax)
  {
    if (y <= right + height &&y >= right - height)
    {
      x = 2 * xmax - x;
      xvel = 0 - xvel;
      putch(7);
    }
    else
    {
      scoreit(0);
    }
  }
}

void check_input(void)
{
  int val;
  while (kbhit())
  {
    val = getc_isr();
    if (val == 'x')
    {
      putch(0);
      exit(0);
    }
    if (val == 'q')
    {
      move_left_up();
      move_left_up();
    }
    if (val == 'a')
    {
      move_left_down();
      move_left_down();
    }
    if (val == 'p')
    {
      move_right_up();
      move_right_up();
    }
    if (val == 'l')
    {
      move_right_down();
      move_right_down();
    }
  }
}

void move_left_up(void)
{
  if (left > ymin + height)
  {
    plotit(xmin - 1, left + height, ' ');
    left--;
    plotit(xmin - 1, left - height, '#');
  }
}

void move_left_down(void)
{
  if (left < ymax - height)
  {
    plotit(xmin - 1, left - height, ' ');
    left++;
    plotit(xmin - 1, left + height, '#');
  }
}

void move_right_up(void)
{
  if (right > ymin + height)
  {
    plotit(xmax + 1, right + height, ' ');
    right--;
    plotit(xmax + 1, right - height, '#');
  }
}

void move_right_down(void)
{
  if (right < ymax - height)
  {
    plotit(xmax + 1, right - height, ' ');
    right++;
    plotit(xmax + 1, right + height, '#');
  }
}

void scoreit(int player)
{
  if (player)
  {
    score1 = (score1 + 1) % 10;
    putnum(center + 3, ymin + 1, score1);
    if (right > (ymin + ymax) / 2)
    {
      y = right - height - 3;
    }
    else
    {
      y = right + height + 3;
    }
    x = xmax;
    xvel = 0 - 1;
  }
  else
  {
    score0 = (score0 + 1) % 10;
    putnum(center - 8, ymin + 1, score0);
    if (left > (ymin + ymax) / 2)
    {
      y = left - height - 3;
    }
    else
    {
      y = left + height + 3;
    }
    x = xmin;
    xvel = 1;
  }
  yvel = 1;
}

void splash(void)
{
  putch(0);
  printf("PONG\r");
  printf("----\r");
  printf("Press 'q' and 'a' to move the");
  printf(" left paddle up and down\r");
  printf("Press 'p' and 'l' to move the");
  printf(" right paddle up and down\r");
  printf("Press 'x' to exit\r");
  printf("Press any key to start\r");
  getc_isr();
}

void plotit(int xpos,  int ypos,  int val)
{
  moveto(xpos, ypos);
  putch(val);
}

void moveto(int xpos,  int ypos)
{
  putch(2);
  putch(xpos);
  putch(ypos);
}

int getval(int xpos,  int ypos)
{
  int ptr, val;
  if (xpos == center)
  {
    return '.';
  }
  if (ypos < ymin + 1 || ypos > ymin + 5)
  {
    return ' ';
  }
  if (xpos < center - 8 || xpos > center + 8)
  {
    return ' ';
  }
  if (xpos > center - 3 &&xpos < center + 3)
  {
    return ' ';
  }
  if (xpos < center)
  {
    val = score0;
    xpos -= center - 8;
  }
  else
  {
    val = score1;
    xpos -= center + 3;
  }
  val = digit[val * 5 + ypos - ymin - 1];
  if (val & (0x20 >> xpos))
  {
    return '#';
  }
  else
  {
    return ' ';
  }
}

void putnum(int xpos,  int ypos,  int num)
{
  char *ptr;
  int temp, i, j;
  i = 5;
  ptr = digit + (num % 10) * 5;
  while (i--)
  {
    j = 6;
    temp = *ptr++;
    moveto(xpos, ypos++);
    while (j--)
    {
      if (temp &0x20)
      {
        putch('#');
      }
      else
      {
        putch(' ');
      }
      temp <<= 1;
    }
  }
}

void plotpaddle(int xpos,  int ypos)
{
  int i;
  i = ypos - height;
  while (i <= ypos + height)
  {
    plotit(xpos, i, '#');
    i++;
  }
}
