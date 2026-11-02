#!/usr/bin/env bash
# Downloads the pinned game data (Freedoom 0.13.0) and checks it is the exact
# file everyone scores with. Run on the login node: compute nodes have no internet.
set -euo pipefail
cd "$(dirname "$0")"
URL=https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip
SHA256=7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d

if [ -f freedoom1.wad ] && echo "$SHA256  freedoom1.wad" | sha256sum -c --quiet 2>/dev/null; then
    echo "freedoom1.wad is already here and correct."
    exit 0
fi
curl -fL -o freedoom.zip "$URL"
unzip -o -j freedoom.zip freedoom-0.13.0/freedoom1.wad
rm -f freedoom.zip
echo "$SHA256  freedoom1.wad" | sha256sum -c
