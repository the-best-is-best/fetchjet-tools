#!/bin/bash
# Puts the mpv and FFmpeg source tarballs in $FJ_MPV_WORK/dl and checks their sha256.
# FJ_MPV_SOURCE_CACHE: optional ':'-separated folders searched for a tarball with the right sha256 before downloading.
set -euo pipefail
. "$(dirname "$0")/env.sh"

case "$FJ_MPV_VERSION" in
    0.42.0) mpv_sha=bcfebbfa2b65a6d88dc97ea18117831072373e38b5785a2afb874ed4df5070dd ;;
    *) echo "no sha256 for mpv $FJ_MPV_VERSION: add it to fetch-sources.sh" >&2; exit 1 ;;
esac
ffmpeg_sha=733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1

mkdir -p "$FJ_MPV_DL"

get() {
    local url=$1 name=$2 sha=$3 dest="$FJ_MPV_DL/$2"
    if [ -f "$dest" ] && echo "$sha  $dest" | sha256sum -c --status; then
        return
    fi
    local dir f
    IFS=: read -ra dirs <<< "${FJ_MPV_SOURCE_CACHE:-}"
    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*.tar.*; do
            [ -f "$f" ] || continue
            if [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$sha" ]; then
                echo "using $f for $name"
                cp "$f" "$dest"
                return
            fi
        done
    done
    echo "downloading $url"
    curl -sSfL --retry 3 -o "$dest.part" "$url"
    if ! echo "$sha  $dest.part" | sha256sum -c --status; then
        echo "sha256 mismatch for $name" >&2
        exit 1
    fi
    mv "$dest.part" "$dest"
}

get "https://github.com/mpv-player/mpv/archive/refs/tags/v$FJ_MPV_VERSION.tar.gz" "mpv-$FJ_MPV_VERSION.tar.gz" "$mpv_sha"
get "https://ffmpeg.org/releases/ffmpeg-$FJ_FFMPEG_VERSION.tar.xz" "ffmpeg-$FJ_FFMPEG_VERSION.tar.xz" "$ffmpeg_sha"
