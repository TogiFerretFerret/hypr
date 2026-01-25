#include <stdarg.h>

/* Define direct syscall wrappers declared in assembly */
int write(int fd, const void *buf, unsigned int count);
int read(int fd, void *buf, unsigned int count);

int strlen(const char *str) {
    const char *s = str;
    while (*s) s++;
    return s - str;
}

void puts(const char *s) {
    write(1, s, strlen(s));
    write(1, "\n", 1);
}

void putchar(char c) {
    write(1, &c, 1);
}

void print_dec(int n) {
    char buf[32];
    int i = 0;
    int sign = n < 0;
    if (sign) n = -n;
    if (n == 0) { putchar(0); return; }
    while (n > 0) {
        buf[i++] = (n % 10) + 0;
        n /= 10;
    }
    if (sign) putchar(-);
    while (i > 0) putchar(buf[--i]);
}

void printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    while (*fmt) {
        if (*fmt == "%") {
            fmt++;
            if (*fmt == "d") {
                print_dec(va_arg(args, int));
            } else if (*fmt == "s") {
                const char *s = va_arg(args, char *);
                write(1, s, strlen(s));
            } else if (*fmt == "c") {
                char c = (char)va_arg(args, int);
                write(1, &c, 1);
            } else if (*fmt == "%") {
                putchar("%");
            }
        } else {
            putchar(*fmt);
        }
        fmt++;
    }
    va_end(args);
}
