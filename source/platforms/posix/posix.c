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

char* platform_envp()
{
    return environ;
}

/*
 * Spawn a program using fork + execve.
 *
 * Returns:
 *   child PID on success
 *   -1 on failure
 */
pid_t maru_spawn_program(const char *path, char *const argv[], char *const envp[])
{
    pid_t pid = fork();

    if (pid == 0) {
        // Child
        execve(path, argv, envp ? envp : environ);

        // execve only returns on failure
        fprintf(stderr, "execve failed: %s\n", strerror(errno));
        _exit(127);
    }

    // Parent
    return pid;
}

/*
 * Spawn a program and wait for it to finish.
 *
 * Returns:
 *   exit status of child          (0-255)
 *   128 + signal number           if killed by signal
 *   -1 on failure
 */
int maru_run_program(const char *path, char *const argv[], char *const envp[])
{
    pid_t pid = maru_spawn_program(path, argv, envp);

    if (pid < 0) {
        perror("maru_spawn_program failed");
        return -1;
    }

    int status;

    for (;;) {
        pid_t r = waitpid(pid, &status, 0);

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
