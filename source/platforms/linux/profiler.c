/* profiler.c
 *
 * Freestanding profiler support: install a SIGVTALRM handler and
 * configure a virtual timer interval using direct syscalls.

TODO doesn't work. but this is riddled with an impossible amount of
accidental complexity that feels like a waste of time to grapple
with...

 */

typedef unsigned long uint64_t;
typedef long int64_t;

/* Syscall numbers x86_64 Linux */
#define SYS_rt_sigaction 13
#define SYS_setitimer   38
#define SYS_rt_sigreturn 15

/* ITIMER_VIRTUAL = 1 on x86_64 */
#define ITIMER_VIRTUAL 1

/* Kernel sigset size for rt_sigaction: 128 bytes = 16 unsigned longs */
typedef unsigned long kernel_sigword_t;
#define KERNEL_SIGSET_WORDS 16

typedef struct {
    kernel_sigword_t bits[KERNEL_SIGSET_WORDS];
} k_sigset_t;

struct k_sigaction {
    void (*k_sa_handler)(int);
    unsigned long sa_flags;
    void (*sa_restorer)(void);
    k_sigset_t sa_mask;
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

/* Minimal syscall wrapper (up to 6 args) */
static inline long syscall6(long n,
                            long a1, long a2, long a3,
                            long a4, long a5, long a6)
{
    long ret;
    __asm__ volatile (
        "movq %1, %%rax\n\t"
        "movq %2, %%rdi\n\t"
        "movq %3, %%rsi\n\t"
        "movq %4, %%rdx\n\t"
        "movq %5, %%r10\n\t"
        "movq %6, %%r8\n\t"
        "movq %7, %%r9\n\t"
        "syscall\n\t"
        "movq %%rax, %0\n\t"
        : "=r"(ret)
        : "r"(n), "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a5), "r"(a6)
        : "rax", "rdi", "rsi", "rdx", "r10", "r8", "r9", "rcx", "r11", "memory"
    );
    return ret;
}

/* Helper: clear k_sigset_t */
static inline void k_sigemptyset(k_sigset_t *s)
{
    for (int i = 0; i < KERNEL_SIGSET_WORDS; ++i)
        s->bits[i] = 0UL;
}

/* Inline sigreturn trampoline for x86_64 */
__asm__ (
    ".global sigreturn_trampoline\n"
    "sigreturn_trampoline:\n"
    "    mov $15, %rax\n"   /* SYS_rt_sigreturn */
    "    syscall\n"
);

extern void sigreturn_trampoline(void);

/* Install a SIGVTALRM handler */
extern void install_profiler_handler(void (*handler)(int))
{
    struct k_sigaction kact;
    kact.k_sa_handler = handler;
    kact.sa_flags = 0x4000000;       /* SA_RESTORER */
    kact.sa_restorer = sigreturn_trampoline;
    k_sigemptyset(&kact.sa_mask);

    long sigset_size = (long)(KERNEL_SIGSET_WORDS * sizeof(kernel_sigword_t));

    long r = syscall6(SYS_rt_sigaction,
                      26,            /* SIGVTALRM */
                      (long)&kact,
                      0,             /* oldact */
                      sigset_size,
                      0, 0);
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

    long r = syscall6(SYS_setitimer,
                      ITIMER_VIRTUAL,
                      (long)&kv,
                      0,
                      0, 0, 0);
    (void)r;
}
