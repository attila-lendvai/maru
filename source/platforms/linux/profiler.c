/* profiler.c
 *
 * Freestanding profiler support: install a SIGVTALRM handler and
 * configure a virtual timer interval using direct syscalls.
 *
 */

#include <linux/time.h>

#if defined(__x86_64__)

#include <asm/unistd_64.h>
#include <asm/signal.h>

#define KERNEL_SIGSET_SIZE 8

struct k_sigaction {
    void (*k_sa_handler)(int);
    unsigned long sa_flags;
    void (*sa_restorer)(void);
    unsigned long sa_mask;
};

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

__asm__ (
    ".text\n"
    ".globl __restore_rt\n"
    ".type __restore_rt, @function\n"
    "__restore_rt:\n"
    "    mov $15, %rax\n"
    "    syscall\n"
);

extern void __restore_rt(void);

#elif defined(__i386__)

#include <asm/unistd_32.h>
#include <asm/signal.h>

#define KERNEL_SIGSET_SIZE 8

struct k_sigaction {
    void (*k_sa_handler)(int);
    unsigned long sa_mask[2];
    unsigned long sa_flags;
    void (*sa_restorer)(void);
};

static inline long syscall3(long n, long a1, long a2, long a3)
{
    long ret;
    __asm__ volatile (
        "int $0x80"
        : "=a"(ret)
        : "a"(n), "b"(a1), "c"(a2), "d"(a3)
        : "memory"
    );
    return ret;
}

static inline long syscall4(long n, long a1, long a2, long a3, long a4)
{
    long ret;
    __asm__ volatile (
        "push %%ebp\n\t"
        "mov %5, %%ebp\n\t"
        "int $0x80\n\t"
        "pop %%ebp"
        : "=a"(ret)
        : "a"(n), "b"(a1), "c"(a2), "d"(a3), "g"(a4)
        : "memory"
    );
    return ret;
}

__asm__ (
    ".text\n"
    ".globl __restore_rt\n"
    ".type __restore_rt, @function\n"
    "__restore_rt:\n"
    "    mov $173, %eax\n"
    "    int $0x80\n"
);

extern void __restore_rt(void);

#elif defined(__aarch64__)

#include <asm/unistd.h>
#include <asm/signal.h>

#define KERNEL_SIGSET_SIZE 8

struct k_sigaction {
    void (*k_sa_handler)(int);
    unsigned long sa_flags;
    unsigned long sa_mask;
};

static inline long syscall3(long n, long a1, long a2, long a3)
{
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a1;
    register long x1 __asm__("x1") = a2;
    register long x2 __asm__("x2") = a3;
    __asm__ volatile (
        "svc 0"
        : "+r"(x0)
        : "r"(x1), "r"(x2), "r"(x8)
        : "memory"
    );
    return x0;
}

static inline long syscall4(long n, long a1, long a2, long a3, long a4)
{
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a1;
    register long x1 __asm__("x1") = a2;
    register long x2 __asm__("x2") = a3;
    register long x3 __asm__("x3") = a4;
    __asm__ volatile (
        "svc 0"
        : "+r"(x0)
        : "r"(x1), "r"(x2), "r"(x3), "r"(x8)
        : "memory"
    );
    return x0;
}

#else
#error "Unsupported architecture"
#endif

/* Install a SIGVTALRM handler */
extern void install_profiler_handler(void (*handler)(int))
{
    struct k_sigaction kact;
    kact.k_sa_handler = handler;
#if defined(__x86_64__)
    kact.sa_flags = SA_RESTORER;
    kact.sa_restorer = __restore_rt;
    kact.sa_mask = 0UL;
#elif defined(__i386__)
    kact.sa_flags = SA_RESTORER;
    kact.sa_restorer = __restore_rt;
    kact.sa_mask[0] = 0UL;
    kact.sa_mask[1] = 0UL;
#elif defined(__aarch64__)
    kact.sa_flags = 0;
    kact.sa_mask = 0UL;
#else
#error "Unsupported architecture"
#endif

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
    struct itimerval kv;

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
