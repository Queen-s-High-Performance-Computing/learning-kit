# DOOMATHON: Learning track starter kit

**Goal:** run as many copies of Doom **at the same time** as you can on one Frontenac CPU node, with **every copy keeping up at 35 fps or more**, the speed the original game runs at.

Each copy plays a *demo*, a recorded game that Doom plays back by itself. Read [RULES.md](RULES.md) before you start, and [RESOURCES.md](RESOURCES.md) for Slurm help and ideas.

## What's in here

| Path | What it is | Can you change it? |
|---|---|---|
| `doom/` | The Doom engine ([doomgeneric](https://github.com/ozkl/doomgeneric)), its `Makefile` and `launcher.c` | Yes |
| `doom/platform.c` | Runs Doom headless and checks every copy | **No** (replaced at scoring) |
| `scripts/run.sh` | How your team launches the copies | Yes |
| `scripts/score.sh` | The official scorer | No |
| `reference/` | Correct frame fingerprints for demo1–demo3 | No |
| `get_freedoom.sh` | Downloads the game data | No |

## Quickstart

You need a Frontenac account with MFA, and you need to have accepted the GitHub org invite.

**1. Log in**
```
ssh <username>@login.cac.queensu.ca
```

**2. Get your team's code** (git only works on the login node; compute nodes have no internet)
```
git clone https://github.com/Queen-s-High-Performance-Computing/<your-team-repo>.git
cd <your-team-repo>
```
Your repo is private. When git asks for a password, paste a GitHub **personal access token** (GitHub → Settings → Developer settings → Personal access tokens), not your GitHub password.

**3. Get the game data and build**
```
./get_freedoom.sh
module load gcc
make -C doom -j8
```
You'll see compiler warnings. That's normal for 1990s code. The build worked if `doom/doomgeneric` exists.

**4. Start a job.** Never run Doom on the login node.
```
salloc --time=00:30:00 --cpus-per-task=4 --mem-per-cpu=1G
cd ~/<your-team-repo>
```

**5. Score yourself.** Try 4 copies at once:
```
scripts/score.sh 4
```
You should see something like:
```
Running 4 copies of demo1 at once on frnt201, 4 CPUs...
All copies finished in 5s
  valid copies: 4 of 4
  slowest copy: 1070.2 fps (needs 35)
PASS: 4 copies at once
```
Now raise the number until it fails. The largest number that passes is your score. Each copy's output is in `results/`.

**6. Save your work.** Type `exit` to leave the job, then:
```
git add -A
git commit -m "describe what you changed"
git push
```

**Week-1 checkpoint (November 16):** post a screenshot of your first `PASS:` line in the club channel.

## Common problems

| Problem | Fix |
|---|---|
| `Not inside a Slurm job` | Start a job with `salloc` first (step 4) |
| `Please specify memory per cpu using --mem-per-cpu` | Use `--mem-per-cpu`, not `--mem` |
| `Build first` or `Get the game data first` | Run step 3 again |
| `has exceeded its time limit` | Your files are safe. Start a new `salloc` with a longer `--time` |
| `valid copies` is lower than the number you ran | Some copies crashed or ran out of memory. Look in their `results/` logs |
| `git push` asks for a password and fails | Use a personal access token, and run git on the login node |

## Licence

`doom/` is doomgeneric, licensed under the GNU GPL v2 (see `LICENSE`). Keep the licence file in your repo.
