/* cat [FILE...]      no FILE (or "-") -> read stdin
   System calls: open, read, write, close                                  */

/* ===================== helpers (no hidden system calls) ===================== */
#include <fcntl.h>      /* open, O_RDONLY, O_WRONLY, O_CREAT, O_TRUNC, O_APPEND */
#include <unistd.h>     /* read, write, close */
#include <string.h>     /* strlen, strcmp, strstr, memcpy  (pure user-mode) */

#define BUF_SIZE 4096   /* bytes per read() */
#define MAX_LINE 4096   /* max stored line length; longer lines are cut */

/* write ALL n bytes (write() may write fewer than asked) */
static inline int write_all(int fd, const char *buf, size_t n)
{
    while (n > 0) {
        ssize_t w = write(fd, buf, n);
        if (w < 0) return -1;
        buf += w;
        n -= (size_t)w;
    }
    return 0;
}

static inline void write_str(int fd, const char *s) { write_all(fd, s, strlen(s)); }

/* number -> text, right-aligned to `width` (0 = no padding) */
static inline void write_num(int fd, long x, int width)
{
    char s[32];
    int i = 32, neg = x < 0;
    unsigned long u = neg ? -(unsigned long)x : (unsigned long)x;
    do { s[--i] = (char)('0' + u % 10); u /= 10; } while (u > 0);
    if (neg) s[--i] = '-';
    while (32 - i < width) s[--i] = ' ';
    write_all(fd, s + i, (size_t)(32 - i));
}

/* text -> number; returns 1 on success, 0 if not a valid non-negative integer */
static inline int parse_num(const char *s, long *out)
{
    long v = 0;
    if (*s == '\0') return 0;
    for (; *s; ++s) {
        if (*s < '0' || *s > '9') return 0;
        v = v * 10 + (*s - '0');
    }
    *out = v;
    return 1;
}

/* ============================== program ============================== */

static void copy_fd(int fd)
{
    char buf[BUF_SIZE];
    ssize_t n;
    while ((n = read(fd, buf, BUF_SIZE)) > 0)   /* no line logic needed: */
        write_all(1, buf, (size_t)n);           /* copy chunks as they are */
}

int main(int argc, char **argv)
{
    int rc = 0;
    if (argc == 1) { copy_fd(0); return 0; }

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "-") == 0) { copy_fd(0); continue; }
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) {                             /* optional message on stderr */
            write_str(2, "cat: cannot open "); write_str(2, argv[i]); write_str(2, "\n");
            rc = 1;
            continue;
        }
        copy_fd(fd);
        close(fd);
    }
    return rc;
}
