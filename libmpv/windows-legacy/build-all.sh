#!/bin/bash
# Usage, in an MSYS2 CLANG64 shell: FJ_MPV_WORK=<work folder> ./build-all.sh   (result in $FJ_MPV_WORK/dist/win7)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
for step in "$here/../windows/fetch-sources.sh" "$here/../windows/build-ffmpeg.sh" "$here/build-mpv.sh"; do
    start=$SECONDS
    "$step"
    echo "$(basename "$step"): $((SECONDS - start)) s"
done
