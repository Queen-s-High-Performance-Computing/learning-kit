# DOOMATHON: Learning track starter kit

**Goal:** run as many copies of Doom **at the same time** as you can on `frnt201`, the club's node on Frontenac, with **every copy keeping up at 35 fps or more**, the speed the original game runs at.

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

## How you'll work

You edit code on **your laptop** and push it to GitHub. On Frontenac you only **pull** it on the login node, then build and run it in a job.
```
laptop: edit → commit → push  ──►  GitHub  ──►  Frontenac login node: pull  ──►  job: build → score
```
Don't edit code on the cluster. The only files worth editing there are your own job scripts.

You need a Frontenac account with MFA, and you need to have accepted the GitHub org invite.

## One-time setup

**1. On your laptop: connect to GitHub with an SSH key.** In a terminal (PowerShell on Windows):
```
ssh-keygen -t ed25519 -C "<your-github-email>"    # press Enter at every prompt
cat ~/.ssh/id_ed25519.pub                         # copy the whole line it prints
```
On GitHub: **Settings → SSH and GPG keys → New SSH key**, paste the line, and save. Then check it:
```
ssh -T git@github.com        # type "yes" if asked; it should say "Hi <your-github-name>!"
```

**2. On your laptop: clone your team's repo**
```
git clone git@github.com:Queen-s-High-Performance-Computing/<your-team-repo>.git
```

**3. For the cluster: make a GitHub token.** The cluster pulls over HTTPS, which needs a token rather than your password. On GitHub: **Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token (classic)**. Tick the **`repo`** scope, set the expiry to 30 days, and copy the token somewhere safe. GitHub shows it only once.

**4. On the cluster: clone your team's repo and get the game data**
```
ssh <username>@login.cac.queensu.ca
git config --global credential.helper 'cache --timeout=28800'   # remember the token for 8 hours
git clone https://github.com/Queen-s-High-Performance-Computing/<your-team-repo>.git
cd <your-team-repo>
./get_freedoom.sh
```
When git asks, enter your GitHub username, and paste the **token** as the password.

## Every time you test a change

**1. On your laptop:** edit, then
```
git commit -am "describe what you changed"
git push
```

**2. On the Frontenac login node: pull**
```
cd ~/<your-team-repo>
git pull
```

**3. Start a job, then build and score inside it.** Never run Doom on the login node.
```
salloc --time=00:30:00 --cpus-per-task=16 --mem-per-cpu=1G
cd ~/<your-team-repo>
module load gcc
make -C doom clean && make -C doom -j16
scripts/score.sh 4
```
All teams share `frnt201`, so use at most 16 CPUs per job. Your practice numbers will vary while other teams are running. The clean build makes sure changes to compiler flags take effect. You'll see compiler warnings; that's normal for 1990s code. You should then see something like:
```
Running 4 copies of demo1 at once on frnt201, 16 CPUs...
All copies finished in 5s
  valid copies: 4 of 4
  slowest copy: 1070.2 fps (needs 35)
PASS: 4 copies at once
```
Raise the number until it fails. The largest number that passes is your score. Each copy's output is in `results/`.

Type `exit` to end the job.

**Or run it as a batch job,** so you don't wait at the terminal. Pull first (step 2), then save this as `~/test.sh`:
```bash
#!/bin/bash
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1G
#SBATCH --output=test-%j.out
cd ~/<your-team-repo>
module load gcc
make -C doom clean && make -C doom -j16
scripts/score.sh 4
```
Submit it with `sbatch ~/test.sh`. The results appear in `test-<jobid>.out`, and `squeue -u $USER` shows whether it's still running.

**Week-1 checkpoint (November 16):** post a screenshot of your first `PASS:` line in the club channel.

## Common problems

| Problem | Fix |
|---|---|
| `Not inside a Slurm job` | Start a job with `salloc` first |
| `Please specify memory per cpu using --mem-per-cpu` | Use `--mem-per-cpu`, not `--mem` |
| `Get the game data first` | Run `./get_freedoom.sh` in your repo on the cluster |
| `Authentication failed` on the cluster | Paste the token, not your GitHub password, and check it has the `repo` scope |
| `git pull` says your local changes would be overwritten | You edited on the cluster. Run `git stash`, then `git pull` |
| `has exceeded its time limit` | Your files are safe. Start a new job with a longer `--time` |
| Every demo is `invalid` | Your change altered what's drawn. See *Valid demos* in RULES.md |
| `ssh -T git@github.com` hangs on your laptop | Your network blocks SSH's port. See *SSH over port 443* below |
| `Permission denied (publickey)` on your laptop | Your key isn't on GitHub yet, or you copied only part of the line |
| `valid copies` is lower than the number you ran | Some copies crashed or ran out of memory. Look in their `results/` logs |

### SSH over port 443

Some networks block SSH's normal port. GitHub also accepts SSH on port 443. On your laptop, add this to `~/.ssh/config` (create the file if it doesn't exist):
```
Host github.com
    HostName ssh.github.com
    Port 443
```

## Licence

`doom/` is doomgeneric, licensed under the GNU GPL v2 (see `LICENSE`). Keep the licence file in your repo.
