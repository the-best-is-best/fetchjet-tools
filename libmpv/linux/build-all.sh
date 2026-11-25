#!/bin/bash
# One self-contained libmpv.so.2 for Linux x86_64, gzipped as libmpv-linux-x64-<version>.gz.
# Usage: FJ_MPV_WORK=<work folder> bash libmpv/linux/build-all.sh   (result in $FJ_MPV_WORK/dist)
# The dependency and FFmpeg steps are skipped when $FJ_MPV_PREFIX already holds a build made by the same scripts.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/env.sh"

recipe_sum() {
    (cd "$here" && cat env.sh fetch-sources.sh vulkan-headers.sha256 "$@") | sha256sum | cut -c1-64
}

step() {
    local stamp="$FJ_MPV_PREFIX/.stamp-$1"; shift
    local sum
    sum=$(recipe_sum "$@")
    if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$sum" ]; then
        echo "skip ${*: -1}: already built by the same scripts"
        return
    fi
    rm -f "$stamp"
    bash "$here/${*: -1}"
    echo "$sum" > "$stamp"
}

bash "$here/fetch-sources.sh"
step deps build-deps.sh
step ffmpeg build-deps.sh build-ffmpeg.sh
bash "$here/build-mpv.sh"
