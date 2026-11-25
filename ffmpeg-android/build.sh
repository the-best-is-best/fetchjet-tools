#!/bin/bash
# Builds ffmpeg and ffprobe for Android as libffmpeg.so / libffprobe.so (executables named .so so the
# APK installer unpacks them), with http/https through mbedtls, then packs them into one zip:
#   build.sh <out dir> [abis...]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
NDK=${ANDROID_NDK_ROOT:-${ANDROID_NDK_HOME:?set ANDROID_NDK_ROOT}}
case "$(uname -s)" in Darwin) TAG=darwin-x86_64; JOBS=$(sysctl -n hw.ncpu);; *) TAG=linux-x86_64; JOBS=$(nproc);; esac
TC=$NDK/toolchains/llvm/prebuilt/$TAG
DIST=${1:?out dir}; shift
ABIS=${*:-arm64-v8a armeabi-v7a x86_64 x86}
FFMPEG=7.1.1 LAME=3.100 OPUS=1.5.2 MBEDTLS=3.6.8
ROOT=${FFROOT:-$PWD/build/ffmpeg-android}
mkdir -p "$ROOT/src" "$ROOT/bin" "$DIST"
ROOT=$(cd "$ROOT" && pwd)
DIST=$(cd "$DIST" && pwd)
OUT=$ROOT/libs
rm -rf "$OUT"
fetch() { [ -f "$ROOT/src/$1" ] || curl -fsSL --retry 3 -o "$ROOT/src/$1" "$2"; }
fetch ffmpeg-$FFMPEG.tar.xz https://ffmpeg.org/releases/ffmpeg-$FFMPEG.tar.xz
fetch lame-$LAME.tar.gz https://downloads.sourceforge.net/project/lame/lame/$LAME/lame-$LAME.tar.gz
fetch opus-$OPUS.tar.gz https://downloads.xiph.org/releases/opus/opus-$OPUS.tar.gz
fetch mbedtls-$MBEDTLS.tar.bz2 https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$MBEDTLS/mbedtls-$MBEDTLS.tar.bz2
if command -v sha256sum >/dev/null; then (cd "$ROOT/src" && sha256sum -c "$HERE/sources.sha256"); else (cd "$ROOT/src" && shasum -a 256 -c "$HERE/sources.sha256"); fi
cp "$HERE/bin/pkg-config" "$ROOT/bin/pkg-config"
chmod +x "$ROOT/bin/pkg-config"
. "$HERE/config.sh"
export PATH="$TC/bin:$PATH"
for ABI in $ABIS; do
  EXTRA=""
  case $ABI in
    arm64-v8a) TRIPLE=aarch64-linux-android24; HOST=aarch64-linux-gnu; ARCH=aarch64;;
    armeabi-v7a) TRIPLE=armv7a-linux-androideabi24; HOST=arm-linux-gnueabi; ARCH=arm;;
    x86) TRIPLE=i686-linux-android24; HOST=i686-linux-gnu; ARCH=x86; EXTRA=--disable-asm;;
    x86_64) TRIPLE=x86_64-linux-android24; HOST=x86_64-linux-gnu; ARCH=x86_64;;
    *) echo "unknown abi $ABI"; exit 1;;
  esac
  W=$ROOT/work/$ABI; PREFIX=$ROOT/out/$ABI
  rm -rf "$W" "$PREFIX"; mkdir -p "$W" "$PREFIX"
  printf '#!/bin/sh\nexec %s/bin/clang --target=%s "$@"\n' "$TC" "$TRIPLE" > "$ROOT/bin/cc-$ABI"
  chmod +x "$ROOT/bin/cc-$ABI"
  export CC="$ROOT/bin/cc-$ABI" AR=$TC/bin/llvm-ar RANLIB=$TC/bin/llvm-ranlib STRIP=$TC/bin/llvm-strip
  cd "$W"
  tar xzf "$ROOT/src/lame-$LAME.tar.gz"; tar xzf "$ROOT/src/opus-$OPUS.tar.gz"; tar xjf "$ROOT/src/mbedtls-$MBEDTLS.tar.bz2"
  (cd lame-$LAME && ./configure --host=$HOST --prefix=$PREFIX --disable-shared --enable-static --disable-frontend --disable-decoder --disable-gtktest > "$W/lame.log" 2>&1 && make -j"$JOBS" >> "$W/lame.log" 2>&1 && make install >> "$W/lame.log" 2>&1) || { tail -30 "$W/lame.log"; exit 1; }
  (cd opus-$OPUS && ./configure --host=$HOST --prefix=$PREFIX --disable-shared --enable-static --disable-doc --disable-extra-programs > "$W/opus.log" 2>&1 && make -j"$JOBS" >> "$W/opus.log" 2>&1 && make install >> "$W/opus.log" 2>&1) || { tail -30 "$W/opus.log"; exit 1; }
  (cmake -S mbedtls-$MBEDTLS -B mbedtls-build -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
     -DANDROID_ABI=$ABI -DANDROID_PLATFORM=24 -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX="$PREFIX" \
     -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
     -DCMAKE_C_FLAGS="-ffunction-sections -fdata-sections" > "$W/mbedtls.log" 2>&1 \
   && cmake --build mbedtls-build -j"$JOBS" >> "$W/mbedtls.log" 2>&1 && cmake --install mbedtls-build >> "$W/mbedtls.log" 2>&1) || { tail -30 "$W/mbedtls.log"; exit 1; }
  tar xJf "$ROOT/src/ffmpeg-$FFMPEG.tar.xz"
  export FFPREFIX=$PREFIX
  configure() {
    ../ffmpeg-$FFMPEG/configure --prefix="$ROOT/ffout/$ABI" --target-os=android --arch=$ARCH       --enable-cross-compile --cc="$CC" --host-cc=${HOST_CC:-cc} --ar="$AR" --ranlib="$RANLIB" --strip="$STRIP" --nm="$TC/bin/llvm-nm"       --disable-everything --disable-doc --disable-shared --enable-static --disable-autodetect --enable-zlib       --disable-avdevice --disable-debug --enable-small --enable-pic $EXTRA       --disable-ffplay --enable-libmp3lame --enable-libopus       --pkg-config="$ROOT/bin/pkg-config"       --extra-cflags="-I$PREFIX/include -Os -ffunction-sections -fdata-sections"       --extra-ldexeflags="-pie -Wl,--export-dynamic-symbol=main"       --extra-ldflags="-L$PREFIX/lib -Wl,--gc-sections -Wl,-z,max-page-size=16384"       --enable-demuxer=$DEMUX --enable-muxer=$MUX --enable-decoder=$DEC --enable-encoder=$ENC       --enable-parser=$PARS --enable-bsf=$BSF --enable-filter=$FILT "$@" > "$W/configure-$(basename "$PWD").log" 2>&1       || { tail -40 "$W/configure-$(basename "$PWD").log"; tail -60 ffbuild/config.log 2>/dev/null; exit 1; }
  }
  # ffmpeg reads parts of videos from the site (yt-dlp's "only the clip"): network + TLS
  mkdir ffb; cd ffb
  configure --enable-ffmpeg --disable-ffprobe --enable-network --enable-version3 --enable-mbedtls --enable-protocol=$PROT
  grep -q '^CONFIG_HTTPS_PROTOCOL=yes' ffbuild/config.mak || { echo "https protocol not enabled"; exit 1; }
  make -j"$JOBS" ffmpeg > "$W/make-ffmpeg.log" 2>&1 || { tail -40 "$W/make-ffmpeg.log"; exit 1; }
  # ffprobe only reads local files: no network, so it stays small
  cd ..; mkdir ffp; cd ffp
  configure --disable-ffmpeg --enable-ffprobe --disable-network --enable-protocol=$LOCALPROT
  make -j"$JOBS" ffprobe > "$W/make-ffprobe.log" 2>&1 || { tail -40 "$W/make-ffprobe.log"; exit 1; }
  cd ..
  mkdir -p "$OUT/$ABI"
  cp ffb/ffmpeg "$OUT/$ABI/libffmpeg.so"; cp ffp/ffprobe "$OUT/$ABI/libffprobe.so"
  "$STRIP" "$OUT/$ABI/libffmpeg.so" "$OUT/$ABI/libffprobe.so"
  ls -l "$OUT/$ABI"
done
NAME=ffmpeg-android-$FFMPEG.zip
rm -f "$DIST/$NAME"
(cd "$OUT" && find . -type f | sort | TZ=UTC xargs touch -t 202001010000 && find . -type f | sort | zip -X -q "$DIST/$NAME" -@)
cat "$HERE/LICENSE.txt" > "$DIST/LICENSE.ffmpeg-android.txt"
(cd "$DIST" && { command -v sha256sum >/dev/null && sha256sum "$NAME" || shasum -a 256 "$NAME"; } | tee "$NAME.sha256")
