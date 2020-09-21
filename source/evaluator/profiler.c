/*
  An optional C file to install the signal handler for the profiler
  when feature/profiler is enabled.
 */

#define _ISOC99_SOURCE 1
#define _DEFAULT_SOURCE 1

#include <stdio.h>
#include <signal.h>
#include <sys/time.h>

extern void install_profiler_handler(void (*handler)(int))
{
    struct sigaction sa;
    sa.sa_handler = handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    if (sigaction(SIGVTALRM, &sa, 0))
        perror("vtalrm");
}

extern void set_profiler_interval(int microseconds) // 0 for disable
{
    struct itimerval itv = { { 0, microseconds }, { 0, microseconds } };
    setitimer(ITIMER_VIRTUAL, &itv, 0);
}
