#!/bin/bash
# Static zlib, expat, freetype, fribidi, harfbuzz, fontconfig, libass, dav1d and libplacebo (all -fPIC) for the
# Linux x86_64 libmpv. libplacebo's float parsing needs libstdc++: its .pc gets -lstdc++, which meson links from
# libstdc++.a (prefer_static), so the result does not need libstdc++.so.
set -euo pipefail
. "$(dirname "$0")/env.sh"

meson_static() {
    local name=$1; shift
    fj_unpack "$name"
    rm -rf "$FJ_MPV_BUILD/$name"
    meson setup "$FJ_MPV_BUILD/$name" "$FJ_MPV_SRC/$name" $FJ_MPV_MESON_STATIC "$@"
    ninja -C "$FJ_MPV_BUILD/$name" -j"$FJ_MPV_JOBS"
    ninja -C "$FJ_MPV_BUILD/$name" install
}

fj_unpack zlib-1.3.1
rm -rf "$FJ_MPV_BUILD/zlib"
mkdir -p "$FJ_MPV_BUILD/zlib"
(cd "$FJ_MPV_BUILD/zlib" && "$FJ_MPV_SRC/zlib-1.3.1/configure" --static --prefix="$FJ_MPV_PREFIX" \
    && make -j"$FJ_MPV_JOBS" && make install)

fj_unpack expat-2.7.1
rm -rf "$FJ_MPV_BUILD/expat"
cmake -S "$FJ_MPV_SRC/expat-2.7.1" -B "$FJ_MPV_BUILD/expat" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$FJ_MPV_PREFIX" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DEXPAT_SHARED_LIBS=OFF -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF \
    -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_PKGCONFIG=ON
cmake --build "$FJ_MPV_BUILD/expat" -j"$FJ_MPV_JOBS"
cmake --install "$FJ_MPV_BUILD/expat"

meson_static freetype-2.13.3 -Dbrotli=disabled -Dbzip2=disabled -Dharfbuzz=disabled -Dpng=disabled -Dzlib=none

meson_static fribidi-1.0.18 -Ddocs=false -Dbin=false -Dtests=false

meson_static harfbuzz-15.2.0 -Dauto_features=disabled -Dtests=disabled -Ddocs=disabled -Dutilities=disabled

fj_unpack fontconfig-2.16.0
rm -rf "$FJ_MPV_BUILD/fontconfig" "$FJ_MPV_BUILD/fontconfig-stage"
meson setup "$FJ_MPV_BUILD/fontconfig" "$FJ_MPV_SRC/fontconfig-2.16.0" $FJ_MPV_MESON_STATIC \
    -Ddoc=disabled -Dnls=disabled -Dtests=disabled -Dtools=disabled -Dcache-build=disabled -Dxml-backend=expat \
    -Dsysconfdir=/etc -Dlocalstatedir=/var -Dbaseconfig-dir=/etc/fonts -Dconfig-dir=/etc/fonts/conf.d \
    -Dtemplate-dir=/usr/share/fontconfig/conf.avail -Dxml-dir=/usr/share/xml/fontconfig \
    -Dcache-dir=/var/cache/fontconfig
ninja -C "$FJ_MPV_BUILD/fontconfig" -j"$FJ_MPV_JOBS"
DESTDIR="$FJ_MPV_BUILD/fontconfig-stage" meson install -C "$FJ_MPV_BUILD/fontconfig" --no-rebuild
cp -a "$FJ_MPV_BUILD/fontconfig-stage$FJ_MPV_PREFIX/." "$FJ_MPV_PREFIX/"

meson_static libass-0.17.5 -Dauto_features=disabled -Dfontconfig=enabled -Dasm=enabled

meson_static dav1d-1.5.1 -Denable_tools=false -Denable_tests=false -Denable_examples=false

meson_static libplacebo-7.387.0 -Dauto_features=disabled -Dvulkan=disabled -Dopengl=disabled -Dd3d11=disabled \
    -Ddemos=false -Dtests=false
sed -i 's/^Libs: .*/& -lstdc++/' "$FJ_MPV_PREFIX/lib/pkgconfig/libplacebo.pc"
