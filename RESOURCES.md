# Slurm and ideas

## Slurm in five commands

Frontenac is shared by hundreds of researchers. **Slurm** is the scheduler: you ask it for CPUs, memory and time, it starts your **job** when they're free, and it stops the job when the time runs out.

| Command | What it does |
|---|---|
| `salloc --time=00:30:00 --cpus-per-task=8 --mem-per-cpu=1G` | Start an interactive job: 8 CPUs, 1 GB per CPU, 30 minutes |
| `sbatch job.sh` | Submit a script to run on its own, without you waiting |
| `squeue -u $USER` | See your jobs, and whether they're waiting or running |
| `scancel <jobid>` | Cancel a job |
| `sinfo` | See the cluster's nodes and partitions |

Tips:
- **Use at most 16 CPUs per job.** All teams share `frnt201`.
- **Ask for what you need.** Bigger and longer requests wait longer in the queue.
- **Use `--mem-per-cpu`, not `--mem`.** Frontenac rejects `--mem` for multi-CPU jobs.
- **When the time runs out, the job ends, but your files stay.**

A batch script for a longer test:
```bash
#!/bin/bash
#SBATCH --time=00:45:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1G
cd ~/<your-team-repo>
scripts/score.sh 200
```
Submit it with `sbatch job.sh`. Output appears in `slurm-<jobid>.out`.

## What limits the number of copies?

Work through these one at a time, measuring as you go.

1. **CPU time.** Each copy needs enough CPU to draw 35 frames a second. If one CPU manages about 1,000 fps flat out, how many copies could it hold in theory? Does the real number match?
2. **Memory.** Every copy uses memory. Find out how much:
   ```
   /usr/bin/time -v doom/doomgeneric -iwad freedoom1.wad -timedemo demo1 2>&1 | grep "Maximum resident"
   ```
   Multiply by your copies, then compare with what your job asked for.
3. **Start-up.** Starting hundreds of copies at the same moment means they all load the game data at once. Does starting them in small waves help?
4. **Fairness.** The score is set by the **slowest** copy. If Linux gives some copies more CPU than others, the slowest one drags you down. Look at the spread of fps in `results/`.
5. **Making each copy cheaper.** Compiler flags in `doom/Makefile` make every copy faster, so more fit. Start with `-O2` instead of `-Os`.

## Useful commands

- `nproc`: how many CPUs your job has
- `lscpu`: the CPU model, cores, and threads per core
- `top` or `htop`: watch CPU and memory while copies run (press `q` to quit)
- `free -g`: memory on the node
- `ulimit -u`: the most processes you may run

## Reading

- Frontenac wiki: https://info.cac.queensu.ca/
- Slurm `sbatch` options: https://slurm.schedmd.com/sbatch.html
- GCC optimize options: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
