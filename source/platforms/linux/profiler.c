/* profiler.c
 *
 * Freestanding profiler support: install a SIGVTALRM handler and
 * configure a virtual timer interval using direct syscalls.
 *
 */

#include <x86_64-linux-gnu/asm/unistd_64.h>
#include <x86_64-linux-gnu/asm/signal.h>
#include <linux/time.h>

/* Kernel sigset: on x86_64 the rt_sigaction syscall expects 8 bytes (1 word) */
#define KERNEL_SIGSET_SIZE 8

/* Kernel's sigaction structure layout for the rt_sigaction syscall */
struct k_sigaction {
    void (*k_sa_handler)(int);
    unsigned long sa_flags;
    void (*sa_restorer)(void);
    unsigned long sa_mask;
};

/* timeval / itimerval for setitimer syscall */
struct timeval_k {
    long tv_sec;
    long tv_usec;
};

struct itimerval_k {
    struct timeval_k it_interval;
    struct timeval_k it_value;
};

/* Minimal syscall wrappers */
static inline long syscall3(long n, long a1, long a2, long a3)
{
    long ret;
    __asm__ volatile (
        "syscall\n\t"
        : "=a"(ret)
        : "a"(n), "D"(a1), "S"(a2), "d"(a3)
        : "rcx", "r11", "memory"
    );
    return ret;
}

static inline long syscall4(long n, long a1, long a2, long a3, long a4)
{
    long ret;
    __asm__ volatile (
        "movq %5, %%r10\n\t"
        "syscall\n\t"
        : "=a"(ret)
        : "a"(n), "D"(a1), "S"(a2), "d"(a3), "r"(a4)
        : "rcx", "r11", "r10", "memory"
    );
    return ret;
}

/* sigreturn trampoline: called by kernel after signal handler returns.
 * Must match glibc's __restore_rt which simply does: mov $15,%rax; syscall */
__asm__ (
    ".text\n"
    ".globl __restore_rt\n"
    ".type __restore_rt, @function\n"
    "__restore_rt:\n"
    "    mov $" "15" ", %rax\n"
    "    syscall\n"
);

extern void __restore_rt(void);

/* Install a SIGVTALRM handler */
extern void install_profiler_handler(void (*handler)(int))
{
    struct k_sigaction kact;
    kact.k_sa_handler = handler;
    kact.sa_flags = SA_RESTORER;
    kact.sa_restorer = __restore_rt;
    kact.sa_mask = 0UL;

    long r = syscall4(__NR_rt_sigaction,
                      SIGVTALRM,
                      (long)&kact,
                      0,
                      KERNEL_SIGSET_SIZE);
    (void)r;
}

/* Set the virtual timer interval (microseconds, 0 to disable) */
extern void set_profiler_interval(int microseconds)
{
    struct itimerval_k kv;

    if (microseconds == 0) {
        kv.it_interval.tv_sec = 0;
        kv.it_interval.tv_usec = 0;
        kv.it_value.tv_sec = 0;
        kv.it_value.tv_usec = 0;
    } else {
        kv.it_interval.tv_sec = microseconds / 1000000;
        kv.it_interval.tv_usec = microseconds % 1000000;
        kv.it_value = kv.it_interval;
    }

    long r = syscall3(__NR_setitimer,
                      ITIMER_VIRTUAL,
                      (long)&kv,
                      0);
    (void)r;
}
