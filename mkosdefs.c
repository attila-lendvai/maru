#include <stdio.h>

#define STR(X)		#X

#define defint(X)	printf("(define %s %d)\n", #X, X)
#define defstr(X)	printf("(define %s \"%s\")\n", #X, STR(X))

int main()
{
# ifdef __APPLE__
    defint(__APPLE__);
# endif
# ifdef __ELF__
    defint(__ELF__);
# endif
# ifdef __LITTLE_ENDIAN__
    defint(__LITTLE_ENDIAN__);
# endif
# ifdef __MACH__
    defint(__MACH__);
# endif
# ifdef __USER_LABEL_PREFIX__
    defstr(__USER_LABEL_PREFIX__);
# endif
# ifdef __i386__
    defint(__i386__);
# endif
# ifdef __i586__
    defint(__i586__);
# endif
# ifdef __linux__
    defint(__linux__);
# endif
    return 0;
}
