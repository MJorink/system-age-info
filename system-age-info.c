#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

/* Birth time of p; falls back to mtime if fb and birth time is unknown. -1 on error. */
static long long get_time(const char *p, int fb) {
#ifdef __linux__
    struct statx s;
    if (statx(AT_FDCWD, p, 0, STATX_BTIME | STATX_MTIME, &s)) return -1;
    if ((s.stx_mask & STATX_BTIME) && s.stx_btime.tv_sec) return s.stx_btime.tv_sec;
    return fb ? s.stx_mtime.tv_sec : 0;
#else
    struct stat s;
    if (stat(p, &s)) return -1;
    if (s.st_birthtime > 0) return s.st_birthtime;
    return fb ? s.st_mtime : 0;
#endif
}

static void kv(const char *k, long long v) { printf("\033[0;32m%s:\033[0m %lld\n", k, v); }

static void birth(long long t) {
    char b[64];
    time_t tt = t;
    strftime(b, sizeof b, "%a %b %e %H:%M:%S %Y", localtime(&tt));
    puts(b);
}

static void counted(long long t) {
    long long s = time(0) - t, mi = s / 60, h = s / 3600, d = s / 86400, mo = d / 30, y = d / 365;
    puts("System age:");
    birth(t);
    kv("Seconds", s - mi * 60);
    kv("Minutes", mi - h * 60);
    kv("Hours", h - d * 24);
    kv("Days", d - mo * 30);
    kv("Months", mo - y * 12);
    kv("Years", y);
}

static int usage(const char *n) {
    fprintf(stderr,
        "Usage: %s [-f <path>]\n\n"
        "Shows system age. (Based on when '/' was created.)\n"
        "  -f <path> ... Use the age of the given file instead.\n", n);
    return 1;
}

int main(int c, char **v) {
    if (c == 1) counted(get_time("/", 0));
    else if (c == 3 && !strcmp(v[1], "-f")) {
        long long t = get_time(v[2], 1);
        if (t < 0) { fputs("Error: please provide a valid file path.\n", stderr); return usage(v[0]); }
        counted(t);
    } else return usage(v[0]);
    return 0;
}
