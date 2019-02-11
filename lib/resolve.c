#include <string.h>
#include <unistd.h>

static void movestr(char *ptr1, char *ptr2)
{
  while (*ptr2)
    *ptr1++ = *ptr2++;
  *ptr1 = 0;
}

void resolve_path(char *fname, char *path)
{
  char *ptr;
  char *ptr1;
  int pathLen;

  if (!strcmp(fname, "."))
    fname++;
  else if (!strncmp(fname, "./", 2))
    fname += 2;
  if (*fname == '/')
    strcpy(path, fname);
  else if (!*fname)
    getcwd(path, 80);
  else
  {
    getcwd(path, 80);
    //printf("resolve_path0: %s -> %s + %s\n", fname, path, fname);
    pathLen = strlen(path);
    if (path[pathLen - 1] != '/')
      strcat(path, "/");
    strcat(path, fname);
  }
  // Process ..
  //printf("resolve_path1: %s -> %s\n", fname, path);
  ptr = path;
  while (*ptr)
  {
    if (!strncmp(ptr, "/..", 3) && (ptr[3] == 0 || ptr[3] == '/'))
    {
      if (ptr == path)
        movestr(ptr, ptr + 3);
      else
      {
        ptr1 = ptr - 1;
        while (ptr1 != path)
        {
          if (*ptr1 == '/')
            break;
          ptr1--;
        }
        movestr(ptr1, ptr + 3);
        ptr = ptr1;
      }
    }
    else if (!ptr[1] && ptr != path)
      *ptr = 0;
    else if (ptr[1] == '/')
      movestr(ptr, ptr + 1);
    else
    {
      ptr++;
      while (*ptr)
      {
        if (*ptr == '/')
          break;
        ptr++;
      }
    }
  }
  if (!*path)
    strcpy(path, "/");
  //printf("resolve_path2: %s -> %s\n", fname, path);
}
