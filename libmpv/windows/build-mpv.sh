#!/bin/bash
# libmpv-2.dll (LGPL, FFmpeg / libass / libplacebo linked in) into $FJ_MPV_WORK/dist, plus the gzip that gets published.
set -euo pipefail
. "$(dirname "$0")/env.sh"

fj_unpack "mpv-$FJ_MPV_VERSION" "mpv-$FJ_MPV_VERSION.tar.gz"
rm -rf "$FJ_MPV_BUILD/mpv"
meson setup "$FJ_MPV_BUILD/mpv" "$FJ_MPV_SRC/mpv-$FJ_MPV_VERSION" \
    --buildtype=release -Db_ndebug=true -Dstrip=true -Dauto_features=disabled -Dgpl=false \
    -Dlibmpv=true -Dcplayer=false -Dtests=false -Dwasapi=enabled -Dgl=disabled -Dwin32-threads=enabled \
    -Dc_args="-Os -ffunction-sections -fdata-sections" -Dc_link_args="-Wl,--gc-sections" \
    -Dprefer_static=true --default-library=shared --wrap-mode=nodownload \
    --prefix="$(cygpath -m "$FJ_MPV_OUT/mpv")"
ninja -C "$FJ_MPV_BUILD/mpv" -j "$FJ_JOBS"

mkdir -p "$FJ_MPV_DIST"
dll="$FJ_MPV_DIST/libmpv-2.dll"
gz="$FJ_MPV_DIST/libmpv-windows-x64-$FJ_MPV_VERSION.gz"
llvm-strip --strip-unneeded -o "$dll" "$FJ_MPV_BUILD/mpv/libmpv-2.dll"
gzip -9n -c "$dll" > "$gz"

if llvm-objdump -p "$dll" | grep "DLL Name:" | grep -viE "(kernel32|user32|gdi32|advapi32|shell32|ole32|oleaut32|ws2_32|winmm|shlwapi|bcrypt|ntdll|userenv|version|dbghelp|rpcrt4|usp10|dwrite|uuid|avrt|api-ms-win-.*)\.dll"; then
    echo "libmpv-2.dll needs a DLL that is not part of Windows (listed above)" >&2
    exit 1
fi
ls -l "$dll" "$gz"
sha256sum "$gz"
