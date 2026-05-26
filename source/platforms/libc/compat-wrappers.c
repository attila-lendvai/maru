/*
  Wrappers to extend compatibility.
 */

#include <stdio.h>
#include <errno.h>

// Reason: on Darwin stdin/stdout/stderr are macros:
//     #define stderr (*__stderrp)

FILE *maru_get_stdin(void)  { return stdin; }
FILE *maru_get_stdout(void) { return stdout; }
FILE *maru_get_stderr(void) { return stderr; }

// Reason: errno is marked thread local and the C compiler generates
// specific code for reading it.
int maru_get_errno(void)  { return errno; }

/*
 * chdir
 */

#if defined(_WIN32)

#include <direct.h>

int maru_chdir(const char *path) {
    return _chdir(path);
}

#else

#include <unistd.h>

int maru_chdir(const char *path) {
    return chdir(path);
}

char *maru_getcwd(char *buffer, size_t size) {
    return getcwd(buffer, size);
}

#endif
