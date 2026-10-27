#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

/* Birth time of p; falls back to mtime (with a note) if fb and birth time is unknown. 0 if unknown, -1 on error. */
static long long get_time(const char *p, int fb) {
    long long b, m;
#ifdef __linux__
    struct statx s;
    if (statx(AT_FDCWD, p, 0, STATX_BTIME | STATX_MTIME, &s)) return -1;
    b = s.stx_mask & STATX_BTIME ? s.stx_btime.tv_sec : 0;
    m = s.stx_mtime.tv_sec;
#else
    struct stat s;
    if (stat(p, &s)) return -1;
    b = s.st_birthtime;
    m = s.st_mtime;
#endif
    if (b > 0) return b;
    if (!fb || m <= 0) return 0;
    fputs("Note: birth time unknown, using last-modified time.\n", stderr);
    return m;
}

static const char *fmt = "%s: %lld\n";

static time_t add(struct tm x, int mon, int day) {
    x.tm_mon += mon;
    x.tm_mday += day;
    x.tm_isdst = -1;
    return mktime(&x);
}

/* Calendar age from t to now in local time: o = {seconds, minutes, hours, days, months, years}. */
static void split(long long t, long long now, long long o[6]) {
    time_t tt = t, nn = now;
    struct tm a = *localtime(&tt), b = *localtime(&nn);
    int m = (b.tm_year - a.tm_year) * 12 + b.tm_mon - a.tm_mon, d;
    while (m > 0 && add(a, m, 0) > nn) m--; /* whole months: step back while birth + m months is still in the future */
    time_t at = m ? add(a, m, 0) : tt;
    /* whole days: a DST day is 23 or 25 hours, so start one above the 24-hour estimate */
    for (d = (nn - at) / 86400 + 1; d > 0 && add(a, m, d) > nn; d--);
    if (d) at = add(a, m, d);
    long long s = now - at;
    o[0] = s % 60;
    o[1] = s / 60 % 60;
    o[2] = s / 3600;
    o[3] = d;
    o[4] = m % 12;
    o[5] = m / 12;
}

static void counted(long long t, long long now) {
    static const char *n[] = {"Seconds", "Minutes", "Hours", "Days", "Months", "Years"};
    long long o[6];
    if (now < t) now = t; /* clock behind birth time, e.g. no RTC */
    split(t, now, o);
    char d[64];
    time_t tt = t;
    strftime(d, sizeof d, "%a %b %e %H:%M:%S %Y", localtime(&tt));
    puts("System age:");
    puts(d);
    for (int i = 0; i < 6; i++) printf(fmt, n[i], o[i]);
}

static int usage(const char *n) {
    fprintf(stderr,
        "Usage: %s [-w] [-f <path>]\n\n"
        "Shows system age. (Based on when '/' was created.)\n"
        "  -f <path> ... Use the age of the given file instead.\n"
        "  -w        ... Watch: update every second until Ctrl+C.\n", n);
    return 1;
}

int main(int c, char **v) {
    const char *f = 0;
    int w = 0, o, tty = isatty(1);
    while ((o = getopt(c, v, "wf:")) != -1) {
        if (o == 'w') w = 1;
        else if (o == 'f') f = optarg;
        else return usage(v[0]);
    }
    if (optind < c) return usage(v[0]);
    if (tty) fmt = "\033[0;32m%s:\033[0m %lld\n";

    const char *p = f ? f : "/";
    long long t = get_time(p, f != 0);
    if (t < 0) { perror(p); return 1; }
    if (!t) { fprintf(stderr, "Error: time of '%s' is unknown on this system.%s\n", p, f ? "" : " Try -f <path>."); return 1; }
    struct timespec n, d;
    do {
        if (w && tty) fputs("\033[H\033[2J", stdout); /* clear screen */
        clock_gettime(CLOCK_REALTIME, &n);
        counted(t, n.tv_sec);
        fflush(stdout);
        /* sleep until the next whole second, so the counter never skips one */
        long ns = 1000000000 - n.tv_nsec;
        d.tv_sec = ns / 1000000000;
        d.tv_nsec = ns % 1000000000;
    } while (w && !nanosleep(&d, 0));
    return 0;
}
