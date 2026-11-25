# Source it, do not run it. Needs an MSYS2 CLANG64 shell with the packages in packages.txt.
if [ "${MSYSTEM:-}" != "CLANG64" ]; then
    echo "run this inside an MSYS2 CLANG64 shell (MSYSTEM=CLANG64)" >&2
    exit 1
fi
FJ_MPV_RECIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FJ_MPV_RECIPE
export FJ_MPV_VERSION="${FJ_MPV_VERSION:-0.42.0}"
export FJ_FFMPEG_VERSION=7.1.1
mkdir -p "${FJ_MPV_WORK:-./work}"
FJ_MPV_WORK="$(cd "${FJ_MPV_WORK:-./work}" && pwd)"
export FJ_MPV_WORK
export FJ_MPV_DL="$FJ_MPV_WORK/dl"
export FJ_MPV_SRC="$FJ_MPV_WORK/src"
export FJ_MPV_BUILD="$FJ_MPV_WORK/build"
export FJ_MPV_OUT="$FJ_MPV_WORK/out"
export FJ_MPV_DIST="$FJ_MPV_WORK/dist"
export PKG_CONFIG_PATH="$FJ_MPV_RECIPE/pc:$FJ_MPV_OUT/ffmpeg/lib/pkgconfig:$MINGW_PREFIX/lib/pkgconfig"
export FJ_JOBS="${FJ_JOBS:-$(nproc)}"
[ -n "${USERPROFILE:-}" ] || export USERPROFILE="$(cygpath -w "$HOME")"

fj_unpack() {
    mkdir -p "$FJ_MPV_SRC"
    if [ ! -d "$FJ_MPV_SRC/$1" ]; then
        tar -xf "$FJ_MPV_DL/$2" -C "$FJ_MPV_SRC"
    fi
}
