#!/usr/bin/env bash
# TEAM-OWNED: how your team launches Doom. Change it however you like.
#
# scripts/score.sh runs this and waits for it to finish.
# It provides: COPIES DOOM_BIN DOOM_IWAD DOOM_DEMO DG_REFERENCE RESULTS_DIR
#
# Must-follow rules (see RULES.md):
#   - start exactly $COPIES copies, each playing the demo once, all at the same time
#   - run everything on this node: no srun, sbatch or ssh
#   - keep every process in this process group: no setsid, nohup or disown
#   - send each copy's output to its own *.log file in $RESULTS_DIR
#
# Baseline strategy: start every copy at once and let Linux share the CPUs.

for i in $(seq 0 $((COPIES - 1))); do
    workdir="$RESULTS_DIR/c$i"   # each copy needs its own folder for its config file
    mkdir -p "$workdir"
    (
        cd "$workdir"
        "$DOOM_BIN" -iwad "$DOOM_IWAD" -timedemo "$DOOM_DEMO" || true
    ) > "$RESULTS_DIR/c$i.log" 2>&1 &
done
wait
