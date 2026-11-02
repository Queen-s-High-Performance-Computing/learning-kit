// QHPC DOOMATHON platform layer.
//
// ORGANIZER-OWNED FILE: at scoring time this file is replaced with the
// official copy, so changes you make here will not count.
//
// It runs Doom headless (no window, no input) and checks every demo.
// For each game tic it fingerprints the frame on screen and compares it
// with a reference recording of the original game. When a demo ends it
// prints one line:
//
//     DGVALID tics=<tics drawn> matched=<tics matching the reference>
//
// Environment variables:
//   DG_REFERENCE=<file>  compare against this reference (scripts/run.sh sets it)
//   DG_RECORD=<file>     write a new reference instead (organizers only)

#include "doomgeneric.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

extern int gametic;

// Fingerprint every 61st pixel (~4,200 of 256,000 per frame): cheap enough
// not to distort the benchmark, but almost any change to a frame changes it.
#define SAMPLE_STRIDE 61
#define FNV_OFFSET 1469598103934665603ULL
#define FNV_PRIME 1099511628211ULL

static uint64_t *ref_print;  // ref_print[t - ref_first] = fingerprint of tic t
static int ref_first, ref_count;
static FILE *record_file;

static long demo_tics, demo_matched;
static int pending_tic = -1;  // tic whose latest frame is held in pending_print
static uint64_t pending_print;

static uint64_t frame_print(void)
{
    uint64_t h = FNV_OFFSET;
    for (int i = 0; i < DOOMGENERIC_RESX * DOOMGENERIC_RESY; i += SAMPLE_STRIDE)
    {
        h ^= (uint64_t)(DG_ScreenBuffer[i] & 0xFFFFFF);  // RGB only, ignore alpha
        h *= FNV_PRIME;
    }
    return h;
}

// Count the last frame drawn for the pending tic. Only the last frame of a
// tic counts: extra frames within one tic (the screen-melt transition)
// depend on wall-clock timing, so no reference could predict them.
static void commit_tic(void)
{
    if (pending_tic < 0)
        return;
    if (record_file)
        fprintf(record_file, "%d %016llx\n", pending_tic,
                (unsigned long long)pending_print);
    int k = pending_tic - ref_first;
    if (ref_print && k >= 0 && k < ref_count && ref_print[k] == pending_print)
        demo_matched++;
    demo_tics++;
    pending_tic = -1;
}

static void report_demo(void)
{
    commit_tic();
    if (demo_tics == 0)
        return;
    if (ref_print)
        printf("DGVALID tics=%ld matched=%ld\n", demo_tics, demo_matched);
    else
        printf("DGVALID tics=%ld matched=unchecked\n", demo_tics);
    fflush(stdout);
    if (record_file)
        fflush(record_file);
    demo_tics = demo_matched = 0;
}

static void load_reference(const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f)
    {
        fprintf(stderr, "DOOMATHON: cannot open reference %s\n", path);
        exit(2);
    }
    int tic, cap = 8192;
    unsigned long long print;
    ref_print = malloc(cap * sizeof *ref_print);
    while (fscanf(f, "%d %llx", &tic, &print) == 2)
    {
        if (ref_count == 0)
            ref_first = tic;
        if (ref_count == cap)
            ref_print = realloc(ref_print, (cap *= 2) * sizeof *ref_print);
        ref_print[ref_count++] = print;
    }
    fclose(f);
}

void DG_Init(void)
{
    const char *ref = getenv("DG_REFERENCE");
    const char *rec = getenv("DG_RECORD");
    if (ref && *ref)
        load_reference(ref);
    if (rec && *rec)
        record_file = fopen(rec, "w");
    // Doom ends a timedemo by calling exit(), which runs this.
    atexit(report_demo);
}

void DG_DrawFrame(void)
{
    if (pending_tic >= 0 && gametic < pending_tic)
        report_demo();  // tic counter went backwards: a new demo started
    else if (gametic != pending_tic)
        commit_tic();   // moved on to a new tic
    pending_tic = gametic;
    pending_print = frame_print();
}

void DG_SleepMs(uint32_t ms)
{
    usleep(ms * 1000);
}

uint32_t DG_GetTicksMs(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (uint32_t)(t.tv_sec * 1000 + t.tv_nsec / 1000000);
}

int DG_GetKey(int *pressed, unsigned char *key)
{
    (void)pressed;
    (void)key;
    return 0;  // no keyboard: demos play themselves
}

void DG_SetWindowTitle(const char *title)
{
    (void)title;
}
