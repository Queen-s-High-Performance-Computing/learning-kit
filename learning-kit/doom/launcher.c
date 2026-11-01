// QHPC DOOMATHON launcher: the program's entry point.
//
// TEAM-OWNED FILE: change it however you like.
//
// As shipped, it plays one demo and exits (Doom exits by itself at the end
// of a -timedemo run). Running more demos per process, so start-up cost is
// paid only once, is one of the optimizations open to you.

#include "doomgeneric.h"

int main(int argc, char **argv)
{
    doomgeneric_Create(argc, argv);

    for (;;)
        doomgeneric_Tick();

    return 0;
}
