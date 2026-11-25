#!/bin/bash
# mpv as one self-contained libmpv.so.2 (x86_64): FFmpeg, dav1d, libass, fontconfig, expat, freetype, fribidi,
# harfbuzz, libplacebo and zlib linked in statically; only glibc, libpulse and libasound stay shared.
# Only the mpv_* functions are exported, so the static FFmpeg never clashes with a system FFmpeg in the same process.
set -euo pipefail
. "$(dirname "$0")/env.sh"
v=$FJ_MPV_VERSION
fj_unpack "mpv-$v"

shared_pc() {
    local name=$1 lib=$2
    local sys=(env -u PKG_CONFIG_LIBDIR -u PKG_CONFIG_PATH pkg-config)
    "${sys[@]}" --exists "$name" || { echo "$name development files not found" >&2; exit 1; }
    cat > "$FJ_MPV_PREFIX/lib/pkgconfig/$name.pc" <<EOF
Name: $name
Description: system $name, linked as a shared library
Version: $("${sys[@]}" --modversion "$name")
Libs: -L$("${sys[@]}" --variable=libdir "$name") -l$lib
Cflags: $("${sys[@]}" --cflags "$name")
EOF
}
shared_pc libpulse pulse
shared_pc alsa asound
meson setup --wipe "$FJ_MPV_BUILD/mpv" "$FJ_MPV_SRC/mpv-$v" --buildtype=release -Db_ndebug=true \
    -Dauto_features=disabled -Dgpl=false -Dlibmpv=true -Dcplayer=false -Dtests=false -Dbuild-date=false \
    -Dpulse=enabled -Dalsa=enabled -Dgl=disabled -Dprefer_static=true --default-library=shared --wrap-mode=nodownload \
    -Dc_args="-Os -ffunction-sections -fdata-sections" \
    -Dc_link_args="-Wl,--gc-sections -Wl,--exclude-libs,ALL -Wl,--version-script=$FJ_MPV_RECIPE/libmpv.map -Wl,-z,defs -Wl,-z,now -Wl,-O1 -Wl,--as-needed -static-libgcc" \
    --prefix="$FJ_MPV_PREFIX/mpv"
ninja -C "$FJ_MPV_BUILD/mpv" -j"$FJ_MPV_JOBS"

mkdir -p "$FJ_MPV_DIST"
out="$FJ_MPV_DIST/libmpv.so.2"
gz="$FJ_MPV_DIST/libmpv-linux-x64-$v.gz"
cp -L "$FJ_MPV_BUILD/mpv/libmpv.so.2" "$out"
chmod 644 "$out"
strip --strip-unneeded "$out"
gzip -9n -c "$out" > "$gz"

bash "$FJ_MPV_RECIPE/check.sh" "$out"
ls -l "$out" "$gz"
sha256sum "$gz"
