# DOOMATHON Learning track: rules

## Score

Your score is the **largest number of copies** for which `scripts/score.sh <copies>` passes on one whole Frontenac CPU node. A run passes when **every** copy:

1. finishes the demo,
2. passes validation (see below), and
3. runs at **35 fps or more** on average, the real speed of the original game.

- **Hardware:** one exclusive node of type **[NODE TYPE]** with **[N] cores**. CPU only; no GPUs.
- **Demo:** `demo1`.

Write your claimed number in your README. Organizers run the scorer at that number; if it fails, they retry at 90% of it, then 80%, and so on.

## Valid copies

`doom/platform.c` fingerprints the frame drawn at every game tic and compares it with `reference/`. When a copy finishes it prints:
```
DGVALID tics=7116 matched=7115
```
A copy is valid only if **every tic was drawn** and **almost every frame matches** (at most 5 may differ). The small allowance exists because one frame changes slightly from run to run in the original engine itself.

## What you may change

- Anything in `doom/` **except `platform.c`**: engine code, `launcher.c`, the `Makefile` and compiler flags
- `scripts/run.sh`: how the copies are started and arranged
- Anything new you add, such as helper scripts or notes

## What you may not do

1. **Edit `platform.c` or `reference/`.** Organizers replace both with the official copies.
2. **Change what's drawn.** Every frame must be the full image the original draws. No lower resolution, no skipped frames.
3. **Fake copies.** Each copy is its own Doom process playing the whole demo, all running at the same time. No caching or reusing results.
4. **Leave the node.** `run.sh` runs everything on the scoring node itself: no `srun`, `sbatch` or `ssh`.
5. **Hide processes from the scorer.** No `setsid`, `nohup`, `disown` or daemons.
6. **Share accounts.** Never log in as someone else.

Organizers review the final code. Anything that breaks these rules scores zero.

## Submitting

1. By the showcase deadline (**to be announced**), tag the commit you want scored and push the tag:
   ```
   git tag final
   git push origin final
   ```
2. Your `README.md` must say:
   - your claimed number of copies
   - what you changed and why it helped
   - what stops you going higher (CPU time, memory, process limits)
   - which AI tools you used, if any, and how

## Also

- AI tools are allowed; disclose them in your README.
- One track per person. Club execs may take part, but not in a track they organize or judge.
- Winning teams get priority when club projects are handed out.
