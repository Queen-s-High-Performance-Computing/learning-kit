#!/usr/bin/env bash
# Learning track scorer: the same script organizers use for official scores.
#
# Runs COPIES copies of Doom at once. It passes if every copy finishes the
# demo, passes validation, and averages at least 35 fps (Doom's real speed).
# Your score is the largest number of copies that passes.
#
# Usage:   scripts/score.sh <copies> [demo]
# Example: scripts/score.sh 16            (demo1 by default)
# Run it inside a job, never on the login node.

set -euo pipefail

COPIES=${1:?usage: scripts/score.sh <copies> [demo]}
DEMO=${2:-demo1}
MIN_FPS=35
TOLERANCE=5     # frames allowed to differ from the reference (see RULES.md)
TIMEOUT=1800    # give up after 30 minutes

ROOT=$(cd "$(dirname "$0")/.." && pwd)
REF="$ROOT/reference/$DEMO.txt"
[ -f "$REF" ] || { echo "No reference for '$DEMO' (try demo1, demo2 or demo3)."; exit 1; }
[ -x "$ROOT/doom/doomgeneric" ] || { echo "Build first: make -C doom"; exit 1; }
[ -f "$ROOT/freedoom1.wad" ] || { echo "Get the game data first: ./get_freedoom.sh"; exit 1; }
if [ -z "${SLURM_JOB_ID:-}" ]; then
    echo "Not inside a Slurm job. Start one with salloc first (see README.md)."
    exit 1
fi

EXPECTED=$(wc -l < "$REF")
export COPIES DOOM_DEMO="$DEMO" DG_REFERENCE="$REF"
export DOOM_BIN="$ROOT/doom/doomgeneric" DOOM_IWAD="$ROOT/freedoom1.wad"
export RESULTS_DIR="$ROOT/results/copies$COPIES"
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

echo "Running $COPIES copies of $DEMO at once on $(hostname), $(nproc) CPUs..."
start=$(date +%s)
setsid "$ROOT/scripts/run.sh" > "$RESULTS_DIR/run.out" 2>&1 &
pid=$!
trap 'kill -KILL -- "-$pid" 2>/dev/null || true' EXIT   # never leave copies running
trap 'exit 130' INT TERM
( sleep "$TIMEOUT"; kill -KILL -- "-$pid" ) 2>/dev/null &
watchdog=$!
trap 'kill -KILL -- "-$pid" 2>/dev/null || true; pkill -P "$watchdog" 2>/dev/null || true' EXIT
wait "$pid" 2>/dev/null || true
pkill -P "$watchdog" 2>/dev/null || true
while kill -0 -- "-$pid" 2>/dev/null; do sleep 0.2; done
echo "All copies finished in $(( $(date +%s) - start ))s"

cat "$RESULTS_DIR"/*.log 2>/dev/null | awk -v want="$EXPECTED" -v tol="$TOLERANCE" \
    -v copies="$COPIES" -v minfps="$MIN_FPS" '
    /^DGVALID/ {
        split($2, t, "="); split($3, m, "=")
        if (t[2] + 0 == want && m[2] ~ /^[0-9]+$/ && m[2] + 0 >= want - tol) valid++
    }
    /^timed / {
        fps = $(NF - 1); gsub(/[()]/, "", fps); fps += 0
        n++; if (n == 1 || fps < slowest) slowest = fps
    }
    END {
        printf "  valid copies: %d of %d\n", valid, copies
        printf "  slowest copy: %.1f fps (needs %d)\n", slowest, minfps
        if (valid == copies && n == copies && slowest >= minfps)
            printf "PASS: %d copies at once\n", copies
        else
            { printf "FAIL: %d copies at once\n", copies; exit 1 }
    }'
