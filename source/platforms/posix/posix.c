// spawn_run.c

#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

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
pid_t posix_spawn_program(const char *path, char *const argv[], char *const envp[], int stdout_fd, int stderr_fd)
{
    pid_t pid = fork();

    if (pid == 0) {
        // Child
        if (stdout_fd >= 0) {
            dup2(stdout_fd, STDOUT_FILENO);
            close(stdout_fd);
        }
        if (stderr_fd >= 0) {
            dup2(stderr_fd, STDERR_FILENO);
            close(stderr_fd);
        }

        execve(path, argv, envp ? envp : environ);

        // execve only returns on failure
        fprintf(stderr, "execve failed: %s\n", strerror(errno));
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
