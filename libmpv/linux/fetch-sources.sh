#!/bin/bash
# Downloads the sources of the Linux x86_64 libmpv build into $FJ_MPV_WORK/dl (about 49 MB, harfbuzz alone is 21 MB)
# and checks each file against its sha256. A file already in dl/ with the right sha256 is not downloaded again.
# Header-only fast_float and the Vulkan headers go to $FJ_MPV_PREFIX/include (libplacebo compiles its Vulkan stubs
# even with Vulkan off).
set -euo pipefail
. "$(dirname "$0")/env.sh"
mkdir -p "$FJ_MPV_WORK/dl"
cd "$FJ_MPV_WORK/dl"

get() {
    local url=$1 file=$2 sum=$3
    if [ -f "$file" ] && echo "$sum  $file" | sha256sum -c --quiet - 2>/dev/null; then
        return
    fi
    curl -sSfL --retry 3 -o "$file.part" "$url"
    if ! echo "$sum  $file.part" | sha256sum -c --quiet -; then
        echo "sha256 mismatch: $file ($url)" >&2
        rm -f "$file.part"
        exit 1
    fi
    mv "$file.part" "$file"
}

get https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz ffmpeg-7.1.1.tar.xz \
    733984395e0dbbe5c046abda2dc49a5544e7e0e1e2366bba849222ae9e3a03b1
case "$FJ_MPV_VERSION" in
    0.42.0) mpv_sum=bcfebbfa2b65a6d88dc97ea18117831072373e38b5785a2afb874ed4df5070dd ;;
    *) echo "no sha256 for mpv $FJ_MPV_VERSION: add it to fetch-sources.sh" >&2; exit 1 ;;
esac
get "https://github.com/mpv-player/mpv/archive/refs/tags/v$FJ_MPV_VERSION.tar.gz" "mpv-$FJ_MPV_VERSION.tar.gz" "$mpv_sum"
get https://downloads.videolan.org/pub/videolan/dav1d/1.5.1/dav1d-1.5.1.tar.xz dav1d-1.5.1.tar.xz \
    401813f1f89fa8fd4295805aa5284d9aed9bc7fc1fdbe554af4292f64cbabe21
get https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz libass-0.17.5.tar.xz \
    2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc
get https://github.com/fribidi/fribidi/releases/download/v1.0.18/fribidi-1.0.18.tar.xz fribidi-1.0.18.tar.xz \
    1de5e8073d035388b71d0b2d452b1da1f8caeea8a7702997b401fe1b6250727f
get https://github.com/harfbuzz/harfbuzz/releases/download/15.2.0/harfbuzz-15.2.0.tar.xz harfbuzz-15.2.0.tar.xz \
    e2ec49090744383cdbe7df808c1cedaafba06a97be8dc4211fe546ba585f12cb
get https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz freetype-2.13.3.tar.xz \
    0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
get https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.16.0.tar.xz fontconfig-2.16.0.tar.xz \
    6a33dc555cc9ba8b10caf7695878ef134eeb36d0af366041f639b1da9b6ed220
get https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz expat-2.7.1.tar.xz \
    354552544b8f99012e5062f7d570ec77f14b412a3ff5c7d8d0dae62c0d217c30
get https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.xz zlib-1.3.1.tar.xz \
    38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32
get https://github.com/haasn/libplacebo/archive/refs/tags/v7.387.0.tar.gz libplacebo-7.387.0.tar.gz \
    f9e62d3774a9c4cfd198ec3abaa88294aaade2e31c04d5ab02bcf4abc98b1df5
get https://github.com/fastfloat/fast_float/releases/download/v8.4.0/fast_float.h fast_float-8.4.0.h \
    0be4b15abbd60476b602aacc6d1c04ed857b03f6a0867adf5962a4079c60c449

vk=https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/vulkan-sdk-1.4.363.0/include
mkdir -p vulkan-headers
while read -r sum path; do
    path=${path%$'\r'}
    get "$vk/$path" "vulkan-headers/${path//\//_}" "$sum"
done < "$FJ_MPV_RECIPE/vulkan-headers.sha256"

include="$FJ_MPV_PREFIX/include"
mkdir -p "$include/fast_float" "$include/vulkan" "$include/vk_video"
cp fast_float-8.4.0.h "$include/fast_float/fast_float.h"
while read -r sum path; do
    path=${path%$'\r'}
    cp "vulkan-headers/${path//\//_}" "$include/$path"
done < "$FJ_MPV_RECIPE/vulkan-headers.sha256"
