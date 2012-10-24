#include <stdio.h>

int fibs(long n)
{
  return (n < 2) ? 1 : (fibs(n - 1) + fibs(n - 2) + 1);
}

int main()
{
  printf("%d\n", fibs(40));
  return 0;
}
