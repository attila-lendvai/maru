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

/*
 * stat
 */

#if defined(_WIN32)

__time64_t maru_file_modification_time (const char *path) {
    struct _stat64 st;
    _stat64(path, &st);
    return st.st_mtime;
}

#else

#include <unistd.h>
#include <time.h>
#include <sys/stat.h>

time_t maru_file_modification_time (const char *path) {
    struct stat st;
    stat(path, &st);
    return st.st_mtime;
}

#endif
