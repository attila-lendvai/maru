#include <stdio.h>
#include <stdlib.h>

int fibs(int n)
{
  return (n < 2) ? 1 : (fibs(n - 1) + fibs(n - 2) + 1);
}

int main(int argc, char **argv)
{
    while (--argc) {
	int arg= atoi(*++argv);
	printf("C: nfibs(%d) = %d\n", arg, fibs(arg));
    }
    return 0;
}
