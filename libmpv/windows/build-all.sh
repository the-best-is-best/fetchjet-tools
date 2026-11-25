#!/bin/bash
# Usage, in an MSYS2 CLANG64 shell: FJ_MPV_WORK=<work folder> ./build-all.sh   (result in $FJ_MPV_WORK/dist)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
for step in fetch-sources build-ffmpeg build-mpv; do
    start=$SECONDS
    "$here/$step.sh"
    echo "$step: $((SECONDS - start)) s"
done
