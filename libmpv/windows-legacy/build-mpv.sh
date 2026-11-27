#!/bin/bash
# libmpv-2.dll for Windows 7 / 8 / 8.1: the Windows recipe's libmpv plus win7-shim.c, so it imports nothing Windows 7 lacks.
set -euo pipefail
legacy="$(cd "$(dirname "$0")" && pwd)"
. "$legacy/../windows/env.sh"

fj_unpack "mpv-$FJ_MPV_VERSION" "mpv-$FJ_MPV_VERSION.tar.gz"
rm -rf "$FJ_MPV_BUILD/mpv-win7"
mkdir -p "$FJ_MPV_BUILD/mpv-win7"
shim="$FJ_MPV_BUILD/mpv-win7/win7-shim.o"
clang -Os -c "$legacy/win7-shim.c" -o "$shim"
meson setup "$FJ_MPV_BUILD/mpv-win7/build" "$FJ_MPV_SRC/mpv-$FJ_MPV_VERSION" \
    --buildtype=release -Db_ndebug=true -Dstrip=true -Dauto_features=disabled -Dgpl=false \
    -Dlibmpv=true -Dcplayer=false -Dtests=false -Dwasapi=enabled -Dgl=disabled -Dwin32-threads=enabled \
    -Dc_args="-Os -ffunction-sections -fdata-sections" -Dc_link_args="-Wl,--gc-sections $(cygpath -m "$shim") -lshlwapi" \
    -Dprefer_static=true --default-library=shared --wrap-mode=nodownload \
    --prefix="$(cygpath -m "$FJ_MPV_OUT/mpv-win7")"
ninja -C "$FJ_MPV_BUILD/mpv-win7/build" -j "$FJ_JOBS"

dist="$FJ_MPV_DIST/win7"
mkdir -p "$dist"
dll="$dist/libmpv-2.dll"
gz="$dist/libmpv-windows-x64-win7-$FJ_MPV_VERSION.gz"
llvm-strip --strip-unneeded -o "$dll" "$FJ_MPV_BUILD/mpv-win7/build/libmpv-2.dll"
gzip -9n -c "$dll" > "$gz"

imports="$(llvm-objdump -p "$dll")"
if echo "$imports" | grep "DLL Name:" | grep -viE "(kernel32|user32|gdi32|advapi32|shell32|ole32|oleaut32|ws2_32|winmm|shlwapi|bcrypt|ntdll|userenv|version|dbghelp|rpcrt4|usp10|dwrite|uuid|avrt|api-ms-win-crt-.*|api-ms-win-core-synch-l1-1-0|api-ms-win-core-file-l1-1-0)\.dll"; then
    echo "libmpv-2.dll (Windows 7) needs a DLL that Windows 7 does not have (listed above)" >&2
    echo "$imports" | sed -n '/DLL Name: api-ms-win-core/,/^$/p' >&2
    exit 1
fi
if echo "$imports" | grep -E "WaitOnAddress|WakeByAddress|PathCch|GetSystemTimePreciseAsFileTime|CreateFile2|SetThreadDescription|GetCurrentPackage"; then
    echo "libmpv-2.dll (Windows 7) imports a function Windows 7 does not have (listed above)" >&2
    exit 1
fi
ls -l "$dll" "$gz"
sha256sum "$gz"
