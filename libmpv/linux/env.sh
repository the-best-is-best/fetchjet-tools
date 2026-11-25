# Shared settings for the Linux x86_64 libmpv build. Source it, do not run it.
# FJ_MPV_WORK: work folder (sources in $FJ_MPV_WORK/dl as tarballs, build trees and the result go there too).
# Needs: gcc, g++, make, cmake, nasm, pkg-config, meson >= 1.3 + ninja + jinja2 (system or a python venv in
# $FJ_MPV_WORK/venv), and the libpulse / alsa development headers.
: "${FJ_MPV_WORK:?set FJ_MPV_WORK to a work folder}"
export FJ_MPV_WORK
export FJ_MPV_VERSION="${FJ_MPV_VERSION:-0.42.0}"
export FJ_MPV_RECIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FJ_MPV_SRC="$FJ_MPV_WORK/src"
export FJ_MPV_BUILD="$FJ_MPV_WORK/build"
export FJ_MPV_PREFIX="$FJ_MPV_WORK/out"
export FJ_MPV_DIST="$FJ_MPV_WORK/dist"
if [ -x "$FJ_MPV_WORK/venv/bin/meson" ]; then
    export PATH="$FJ_MPV_WORK/venv/bin:$PATH"
fi
export PKG_CONFIG_PATH="$FJ_MPV_PREFIX/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$FJ_MPV_PREFIX/lib/pkgconfig"
export CC=gcc CXX=g++
export CFLAGS="-O2 -fPIC -ffunction-sections -fdata-sections -fno-semantic-interposition -I$FJ_MPV_PREFIX/include"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$FJ_MPV_PREFIX/lib"
FJ_MPV_JOBS="$(nproc)"
export FJ_MPV_JOBS
FJ_MPV_MESON_STATIC="--buildtype=release -Db_ndebug=true -Db_staticpic=true --default-library=static --prefix=$FJ_MPV_PREFIX --libdir=lib --wrap-mode=nodownload"
export FJ_MPV_MESON_STATIC

fj_unpack() {
    local name=$1
    mkdir -p "$FJ_MPV_SRC"
    if [ ! -d "$FJ_MPV_SRC/$name" ]; then
        tar -xf "$FJ_MPV_WORK/dl/$name".tar.* -C "$FJ_MPV_SRC"
    fi
}
