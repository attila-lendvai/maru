// spawn_run.c

#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>

extern char **environ;

char** posix_envp()
{
    return environ;
}

/*
 * Spawn a program using fork + execve with optional stdout/stderr redirection.
 *
 * Parameters:
 *   stdout_fd - file descriptor to redirect stdout to, or -1 to leave unchanged
 *   stderr_fd - file descriptor to redirect stderr to, or -1 to leave unchanged
 *
 * Returns:
 *   child PID on success
 *   -1 on failure
 */
pid_t posix_spawn_program(const char *path, char *const argv[], char *const envp[],
                          int stdout_fd, int stderr_fd)
{
    // this works, but it has some issues...

    pid_t pid = fork();

    if (pid == 0) { // Child

        if (stdout_fd >= 0 && stdout_fd != STDOUT_FILENO) { // dup2(1, 1) is a NOP
            if (dup2(stdout_fd, STDOUT_FILENO) < 0) {
                perror("dup2(stdout)");
                _exit(127);
            }
            close(stdout_fd);
        }

        if (stderr_fd >= 0 && stderr_fd != STDERR_FILENO) { // dup2(2, 2) is a NOP
            if (dup2(stderr_fd, STDERR_FILENO) < 0) {
                perror("dup2(stderr)");
                _exit(127);
            }
            close(stderr_fd);
        }

        execve(path, argv, envp ? envp : environ);

        // execve only returns on failure
        perror(path);
        _exit(127);
    }

    // Parent
    return pid;
}

int posix_waitpid(pid_t pid, int options)
{
    int status;

    for (;;) {
        pid_t r = waitpid(pid, &status, options);

        if (r < 0) {
            if (errno == EINTR) {
                continue;
            }

            perror("waitpid");
            return -1;
        }

        break;
    }

    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }

    if (WIFSIGNALED(status)) {
        return 128 + WTERMSIG(status);
    }

    return -1;
}

/*
  KLUDGE mode_t is passed as variadic, which has different ABI rules
  than non-variadic args, and on aarch64 darwin it actually is
  different enough that it breaks.

  TODO The proper fix is to implement variadic stuff in the compiler
  backends, but it's not worth the effort compared to a simple
  workaround like this.

*/
int posix_open(const char *path, int flags, int mode)
{
    return open(path, flags, mode);
}
