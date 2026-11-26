// SPDX-License-Identifier: MIT
//
// The PS side of the pl-interface test (docs/pl-interface.md). It runs as root on the board, with
// pl_interface.bit in the PL. It uses only the interface of the contract:
//   /dev/uioN named "pl"      the registers on M_AXI_GP0, and IRQF2P[0]
//   /dev/mem with O_SYNC      the reserved region 0x1F000000, 16 MiB, for the S_AXI_HP0 master
//
//   cc -O2 -Wall -o pltest pltest.c
//   ./pltest [-n count]            count: the transfers of the short-transfer test (default 10000)
//
// The program does not write outside the reserved region and the registers of the design. Without
// a design that answers, a read of the registers stops the PS until a power cycle. Thus the program
// first checks DONE of the devcfg (the PL is configured) and FCLK0 (on in the SLCR).

#include <dirent.h>
#include <fcntl.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#define BUF_ADDR 0x1F000000u
#define BUF_SIZE 0x01000000u
#define SYSCLK_HZ 125e6

enum { ID = 0x00, SCRATCH = 0x04, CTRL = 0x08, STATUS = 0x0C, ADDR = 0x10, LEN = 0x14, SEED = 0x18,
       ERRORS = 0x1C, CYCLES = 0x20, FCLKCNT = 0x24, SYSCNT = 0x28 };
enum { CTRL_START = 1, CTRL_READ = 2, CTRL_SWIRQ = 4 };
enum { ST_BUSY = 1, ST_DONE = 2, ST_RESP_ERR = 4, ST_IRQ = 8 };

static volatile uint32_t *regs;
static volatile uint32_t *buf;
static int uio_fd;
static int failures;

static uint32_t rd(unsigned off) { return regs[off / 4]; }
static void wr(unsigned off, uint32_t v) { regs[off / 4] = v; }

// The buffer is Normal non-cacheable memory (O_SYNC): the stores can wait in a write buffer. The DSB
// completes them before the store to the registers starts the PL.
static void dsb(void) { __asm__ volatile("dsb sy" ::: "memory"); }

static double now(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

static void check(int ok, const char *what)
{
    printf("%s %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) failures++;
}

static void *map_phys(uint32_t addr, uint32_t size, int flags)
{
    int fd = open("/dev/mem", O_RDWR | flags);
    if (fd < 0) { perror("/dev/mem"); exit(1); }
    void *p = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, addr);
    if (p == MAP_FAILED) { perror("mmap /dev/mem"); exit(1); }
    close(fd);
    return p;
}

static uint32_t slcr_read(uint32_t addr)
{
    volatile uint32_t *p = map_phys(addr & ~0xFFFu, 0x1000, O_SYNC);
    uint32_t v = p[(addr & 0xFFF) / 4];
    munmap((void *)p, 0x1000);
    return v;
}

// The UIO device whose name is "pl".
static void open_uio(void)
{
    DIR *d = opendir("/sys/class/uio");
    struct dirent *e;
    char path[300], name[64];
    if (!d) { perror("/sys/class/uio"); exit(1); }
    while ((e = readdir(d))) {
        if (strncmp(e->d_name, "uio", 3)) continue;
        snprintf(path, sizeof path, "/sys/class/uio/%s/name", e->d_name);
        FILE *f = fopen(path, "r");
        if (!f) continue;
        int ok = fgets(name, sizeof name, f) && !strcmp(name, "pl\n");
        fclose(f);
        if (!ok) continue;
        snprintf(path, sizeof path, "/dev/%s", e->d_name);
        uio_fd = open(path, O_RDWR);
        if (uio_fd < 0) { perror(path); exit(1); }
        // Map 0 of the UIO device is the GP0 window of the device tree (1 MiB); the offset selects it.
        regs = mmap(NULL, 0x100000, PROT_READ | PROT_WRITE, MAP_SHARED, uio_fd, 0);
        if (regs == MAP_FAILED) { perror("mmap uio"); exit(1); }
        printf("uio: %s\n", path);
        closedir(d);
        return;
    }
    fprintf(stderr, "no UIO device named \"pl\"\n");
    exit(1);
}

static void irq_enable(void)
{
    int32_t one = 1;
    if (write(uio_fd, &one, 4) != 4) { perror("uio write"); exit(1); }
}

// Waits for the interrupt; returns 0 after the timeout.
static int irq_wait(int ms)
{
    struct pollfd p = { .fd = uio_fd, .events = POLLIN };
    uint32_t count;
    if (poll(&p, 1, ms) != 1) return 0;
    if (read(uio_fd, &count, 4) != 4) { perror("uio read"); exit(1); }
    return 1;
}

static void fill(uint32_t first_word, uint32_t words, uint32_t seed)
{
    for (uint32_t i = 0; i < words; i++) {
        buf[2 * (first_word + i)] = i;
        buf[2 * (first_word + i) + 1] = seed ^ i;
    }
}

static uint32_t compare(volatile uint32_t *b, uint32_t first_word, uint32_t words, uint32_t seed)
{
    uint32_t bad = 0;
    for (uint32_t i = 0; i < words; i++)
        if (b[2 * (first_word + i)] != i || b[2 * (first_word + i) + 1] != (seed ^ i)) bad++;
    return bad;
}

// One transfer of the PL; with irq, it waits for IRQF2P[0], else it polls BUSY.
static uint32_t transfer(int read, uint32_t offset, uint32_t len, uint32_t seed, int irq)
{
    wr(STATUS, ST_DONE | ST_RESP_ERR);
    wr(ADDR, BUF_ADDR + offset);
    wr(LEN, len);
    wr(SEED, seed);
    if (irq) irq_enable();
    dsb();
    wr(CTRL, (read ? CTRL_READ : 0) | CTRL_START);
    if (irq) {
        if (!irq_wait(1000)) { printf("no interrupt\n"); return 0; }
    } else {
        double t0 = now();
        while (rd(STATUS) & ST_BUSY)
            if (now() - t0 > 1) { printf("timeout\n"); return 0; }
    }
    uint32_t st = rd(STATUS);
    wr(STATUS, ST_DONE | ST_RESP_ERR);
    return st;
}

int main(int argc, char **argv)
{
    unsigned count = 10000;
    int c;
    while ((c = getopt(argc, argv, "n:")) != -1)
        if (c == 'n') count = strtoul(optarg, NULL, 0);
        else { fprintf(stderr, "usage: pltest [-n count]\n"); return 2; }

    // PCFG_DONE in INT_STS of the devcfg, and the FCLK0 control of Linux (FPGA0_THR_CNT bit 0, see
    // docs/pl-interface.md).
    uint32_t int_sts = slcr_read(0xF800700C), thr = slcr_read(0xF8000178);
    printf("devcfg INT_STS 0x%08x, FPGA0_THR_CNT 0x%08x, LVL_SHFTR_EN 0x%08x, FPGA_RST_CTRL 0x%08x\n",
           int_sts, thr, slcr_read(0xF8000900), slcr_read(0xF8000240));
    if (!(int_sts & 4) || (thr & 1)) {
        fprintf(stderr, "the PL is not configured, or FCLK0 is off: stop\n");
        return 1;
    }

    open_uio();
    check(rd(ID) == 0x504C4931, "ID register is \"PLI1\"");
    uint32_t pat[] = { 0, 0xFFFFFFFF, 0xA5A5A5A5, 0x5A5A5A5A, 0x12345678 };
    int ok = 1;
    for (unsigned i = 0; i < sizeof pat / sizeof pat[0]; i++) { wr(SCRATCH, pat[i]); ok &= rd(SCRATCH) == pat[i]; }
    for (int b = 0; b < 32; b++) { wr(SCRATCH, 1u << b); ok &= rd(SCRATCH) == 1u << b; }
    check(ok, "SCRATCH register keeps 37 values");

    // The clocks: FCLK0 against the monotonic clock of Linux, and against SYSCLK of the PHY.
    uint32_t f0 = rd(FCLKCNT), s0 = rd(SYSCNT);
    double t0 = now();
    usleep(1000000);
    uint32_t f1 = rd(FCLKCNT), s1 = rd(SYSCNT);
    double t1 = now();
    double fclk = (f1 - f0) / (t1 - t0), ratio = SYSCLK_HZ * (double)(f1 - f0) / (double)(s1 - s0);
    printf("FCLK0 %.3f MHz (Linux clock), %.4f MHz (SYSCLK at 125 MHz)\n", fclk / 1e6, ratio / 1e6);
    check(fclk > 99e6 && fclk < 101e6, "FCLK0 is 100 MHz");

    // The interrupt: SWIRQ sets IRQF2P[0] without a transfer.
    irq_enable();
    wr(CTRL, CTRL_SWIRQ);
    int got = irq_wait(1000);
    wr(CTRL, 0);
    irq_enable();
    int spurious = irq_wait(100);
    check(got && !spurious, "SWIRQ gives one interrupt, and none after it is cleared");

    buf = map_phys(BUF_ADDR, BUF_SIZE, O_SYNC);
    uint32_t words = BUF_SIZE / 8;

    // The PL writes the whole region; the CPU compares.
    memset((void *)buf, 0, BUF_SIZE);
    uint32_t st = transfer(0, 0, BUF_SIZE, 0xC0FFEE00, 1);
    double secs = rd(CYCLES) / fclk;
    printf("PL write of 16 MiB: STATUS 0x%x, %u cycles, %.1f MiB/s\n", st, rd(CYCLES), 16 / secs);
    check((st & (ST_DONE | ST_RESP_ERR)) == ST_DONE, "PL write ends with DONE, no error response");
    check(compare(buf, 0, words, 0xC0FFEE00) == 0, "CPU reads the pattern of the PL in all 16 MiB");

    // The CPU writes the whole region; the PL compares.
    fill(0, words, 0x0BADF00D);
    st = transfer(1, 0, BUF_SIZE, 0x0BADF00D, 1);
    secs = rd(CYCLES) / fclk;
    printf("PL read of 16 MiB: STATUS 0x%x, ERRORS %u, %.1f MiB/s\n", st, rd(ERRORS), 16 / secs);
    check((st & (ST_DONE | ST_RESP_ERR)) == ST_DONE && rd(ERRORS) == 0, "PL reads the pattern of the CPU in all 16 MiB");
    buf[2 * 12345 + 1] ^= 0x100;
    transfer(1, 0, BUF_SIZE, 0x0BADF00D, 1);
    check(rd(ERRORS) == 1, "PL finds one changed word");

    // Short transfers at many offsets, without a delay between the CPU and the PL.
    unsigned bad_r = 0, bad_w = 0, bad_st = 0;
    srand(1);
    for (unsigned n = 0; n < count; n++) {
        uint32_t len = 128u * (1 + rand() % 32);
        uint32_t off = 128u * (rand() % ((BUF_SIZE - len) / 128));
        uint32_t seed = rand();
        fill(off / 8, len / 8, seed);
        st = transfer(1, off, len, seed, 0);
        if ((st & (ST_DONE | ST_RESP_ERR)) != ST_DONE) bad_st++;
        if (rd(ERRORS)) bad_r++;
        st = transfer(0, off, len, ~seed, 0);
        if ((st & (ST_DONE | ST_RESP_ERR)) != ST_DONE) bad_st++;
        if (compare(buf, off / 8, len / 8, ~seed)) bad_w++;
    }
    printf("%u short transfers each way: %u bad status, %u PL reads and %u CPU reads with a difference\n",
           count, bad_st, bad_r, bad_w);
    check(!bad_st && !bad_r && !bad_w, "short transfers, CPU to PL and PL to CPU");

    // The same with a cacheable mapping (no O_SYNC): the CPU can read old data from its cache.
    munmap((void *)buf, BUF_SIZE);
    volatile uint32_t *cbuf = map_phys(BUF_ADDR, 0x10000, 0);
    uint32_t seen = 0;
    for (uint32_t i = 0; i < 0x10000 / 4; i++) seen += cbuf[i];  // the lines are now in the cache
    transfer(0, 0, 0x10000, 0x77777777, 1);
    uint32_t stale = compare(cbuf, 0, 0x10000 / 8, 0x77777777);
    printf("without O_SYNC: %u of %u words read old data after a PL write (sum %u)\n", stale, 0x10000 / 8, seen);
    munmap((void *)cbuf, 0x10000);

    printf("%s: %d failures\n", failures ? "FAIL" : "PASS", failures);
    return failures ? 1 : 0;
}
