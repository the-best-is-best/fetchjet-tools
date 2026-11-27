#!/bin/bash
# libmpv-2.dll for Windows 7 / 8 / 8.1: the Windows recipe's libmpv plus legacy-shim.c, so it imports nothing Windows 7 lacks.
set -euo pipefail
legacy="$(cd "$(dirname "$0")" && pwd)"
. "$legacy/../windows/env.sh"

fj_unpack "mpv-$FJ_MPV_VERSION" "mpv-$FJ_MPV_VERSION.tar.gz"
rm -rf "$FJ_MPV_BUILD/mpv-legacy"
mkdir -p "$FJ_MPV_BUILD/mpv-legacy"
shim="$FJ_MPV_BUILD/mpv-legacy/legacy-shim.o"
clang -Os -c "$legacy/legacy-shim.c" -o "$shim"
meson setup "$FJ_MPV_BUILD/mpv-legacy/build" "$FJ_MPV_SRC/mpv-$FJ_MPV_VERSION" \
    --buildtype=release -Db_ndebug=true -Dstrip=true -Dauto_features=disabled -Dgpl=false \
    -Dlibmpv=true -Dcplayer=false -Dtests=false -Dwasapi=enabled -Dgl=disabled -Dwin32-threads=enabled \
    -Dc_args="-Os -ffunction-sections -fdata-sections" -Dc_link_args="-Wl,--gc-sections $(cygpath -m "$shim") -lusp10 -lshlwapi" \
    -Dprefer_static=true --default-library=shared --wrap-mode=nodownload \
    --prefix="$(cygpath -m "$FJ_MPV_OUT/mpv-legacy")"
ninja -C "$FJ_MPV_BUILD/mpv-legacy/build" -j "$FJ_JOBS"

dist="$FJ_MPV_DIST/legacy"
mkdir -p "$dist"
dll="$dist/libmpv-2.dll"
gz="$dist/libmpv-windows-x64-legacy-$FJ_MPV_VERSION.gz"
llvm-strip --strip-unneeded -o "$dll" "$FJ_MPV_BUILD/mpv-legacy/build/libmpv-2.dll"
gzip -9n -c "$dll" > "$gz"

imports="$(llvm-objdump -p "$dll")"
if echo "$imports" | grep "DLL Name:" | grep -viE "(kernel32|user32|gdi32|advapi32|shell32|ole32|oleaut32|ws2_32|winmm|shlwapi|bcrypt|ntdll|userenv|version|dbghelp|rpcrt4|usp10|dwrite|uuid|avrt|api-ms-win-crt-.*|api-ms-win-core-synch-l1-1-0|api-ms-win-core-file-l1-1-0)\.dll"; then
    echo "libmpv-2.dll (legacy) needs a DLL that Windows 7 does not have (listed above)" >&2
    echo "$imports" | sed -n '/DLL Name: api-ms-win-core/,/^$/p' >&2
    exit 1
fi
if echo "$imports" | sed -n '/DLL Name: GDI32.dll/,/^$/p' | grep -E "Script[A-Z]"; then
    echo "libmpv-2.dll (legacy) takes Uniscribe from GDI32.dll, which has it only since Windows 8 (listed above)" >&2
    exit 1
fi
if echo "$imports" | grep -E "WaitOnAddress|WakeByAddress|PathCch|PathAlloc|MTAUsage|GetSystemTimePreciseAsFileTime|CreateFile2|SetThreadDescription|GetCurrentPackage"; then
    echo "libmpv-2.dll (legacy) imports a function Windows 7 does not have (listed above)" >&2
    exit 1
fi
ls -l "$dll" "$gz"
sha256sum "$gz"
