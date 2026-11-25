#!/usr/bin/env bash
# Repackages the prebuilt PDFium of bblanchon/pdfium-binaries (Apache 2.0 / BSD) into one gzip-compressed
# library per platform: pdfium-<platform>-<chromium>.gz. Every source archive is checked against its pinned sha256.
set -euo pipefail

CHROMIUM="${1:?chromium build number, for example 8179}"
OUT="${2:?output folder}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SUMS="$HERE/sources-$CHROMIUM.sha256"
[ -f "$SUMS" ] || { echo "no pinned checksums for chromium/$CHROMIUM ($SUMS)" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"

pack() {
    local archive="$1" inside="$2" platform="$3"
    local url="https://github.com/bblanchon/pdfium-binaries/releases/download/chromium%2F$CHROMIUM/$archive"
    curl -fsSL --retry 3 -o "$WORK/$archive" "$url"
    local want
    want="$(awk -v f="$archive" '$2 == f { print $1 }' "$SUMS")"
    [ -n "$want" ] || { echo "no sha256 for $archive" >&2; exit 1; }
    echo "$want  $WORK/$archive" | sha256sum -c -
    mkdir -p "$WORK/$platform"
    tar -xzf "$WORK/$archive" -C "$WORK/$platform"
    gzip -9 -n -c "$WORK/$platform/$inside" > "$OUT/pdfium-$platform-$CHROMIUM.gz"
    if [ ! -f "$OUT/LICENSE.pdfium.txt" ] && [ -f "$WORK/$platform/LICENSE" ]; then
        cp "$WORK/$platform/LICENSE" "$OUT/LICENSE.pdfium.txt"
    fi
}

pack pdfium-win-x64.tgz bin/pdfium.dll windows-x64
pack pdfium-linux-x64.tgz lib/libpdfium.so linux-x64
pack pdfium-mac-arm64.tgz lib/libpdfium.dylib macos-arm64

(cd "$OUT" && sha256sum pdfium-*.gz)
