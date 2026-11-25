#!/bin/bash
# One self-contained libmpv.2.dylib for macOS arm64 (minimum macOS 12.0), gzipped as libmpv-macos-arm64-<version>.gz.
# Usage: FJ_MPV_WORK=<work folder> [FJ_MPV_VERSION=0.42.0] libmpv/macos/build-all.sh   (result in $FJ_MPV_WORK/dist)
# The static dependencies and FFmpeg are built once and reused while $FJ_MPV_WORK/out/.deps-done exists
# (delete that file, or set FJ_MPV_REBUILD_DEPS=1, after changing build-deps.sh or build-ffmpeg.sh).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/env.sh"
"$here/fetch-sources.sh"
if [ -n "${FJ_MPV_REBUILD_DEPS:-}" ] || [ ! -f "$FJ_MPV_PREFIX/.deps-done" ]; then
    "$here/build-deps.sh"
    "$here/build-ffmpeg.sh"
    touch "$FJ_MPV_PREFIX/.deps-done"
else
    echo "build-all: reusing the dependencies in $FJ_MPV_PREFIX"
fi
"$here/build-mpv.sh"
