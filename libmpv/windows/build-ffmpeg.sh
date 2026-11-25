#!/bin/bash
# Minimal static LGPL FFmpeg into $FJ_MPV_WORK/out/ffmpeg. Skipped when the same configuration is already installed.
set -euo pipefail
. "$(dirname "$0")/env.sh"

demuxers="mov,matroska,ogg,mp3,flac,wav,aac,mpegts,mpegps,ac3,eac3,aiff,ape,asf,avi,flv,wv,tta,caf,dts,w64,amr,pcm_s16le,pcm_s16be,pcm_f32le,pcm_u8,mpegvideo,h264,hevc,ivf,obu,srt,ass,webvtt"
decoders="h264,hevc,vp9,vp8,mpeg4,mpeg2video,mpeg1video,libdav1d,aac,aac_latm,mp3,mp3float,mp2,mp2float,opus,vorbis,flac,alac,ac3,eac3,ape,wavpack,tta,dca,truehd,wmav1,wmav2,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_s32le,pcm_s32be,pcm_f32le,pcm_f32be,pcm_f64le,pcm_u8,pcm_alaw,pcm_mulaw,mjpeg,png,gif,bmp,webp,subrip,srt,ass,ssa,movtext,webvtt,text,dvdsub,pgssub,dvbsub"
parsers="aac,aac_latm,mpegaudio,opus,vorbis,flac,ac3,mjpeg,png,webp,h264,hevc,vp9,av1,vp8,mpeg4video,mpegvideo,dca,gif,bmp"
bsfs="aac_adtstoasc,null,extract_extradata,h264_mp4toannexb,hevc_mp4toannexb,vp9_superframe,vp9_superframe_split,av1_frame_merge,av1_frame_split,av1_metadata,h264_metadata,hevc_metadata,mpeg4_unpack_bframes,noise,remove_extradata,dca_core"
filters="aresample,anull,null,aformat,format,scale,atempo,volume,pan,hflip,vflip,transpose,rotate,setpts,asetpts,fps,aresample,anullsrc,loudnorm,dynaudnorm,equalizer,bass,treble,lowpass,highpass,afade,amix,astats,asetrate,aeval"

prefix="$FJ_MPV_OUT/ffmpeg"
args=(
    --prefix="$prefix"
    --cc=clang --cxx=clang++ --ar=llvm-ar --ranlib=llvm-ranlib --nm=llvm-nm --strip=llvm-strip
    --arch=x86_64 --target-os=mingw32 --pkg-config=pkg-config --pkg-config-flags=--static
    --disable-everything --disable-autodetect --disable-doc --disable-programs --disable-shared --enable-static
    --disable-avdevice --disable-network --disable-debug --disable-postproc --enable-version3
    --enable-libdav1d --enable-zlib --enable-w32threads
    --extra-cflags="-O3 -ffunction-sections -fdata-sections"
    --enable-protocol=file,pipe
    --enable-demuxer="$demuxers" --enable-decoder="$decoders" --enable-parser="$parsers"
    --enable-bsf="$bsfs" --enable-filter="$filters"
)

stamp="$prefix/.fj-config"
want="ffmpeg-$FJ_FFMPEG_VERSION ${args[*]}"
if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$want" ]; then
    echo "FFmpeg already built with this configuration"
    exit 0
fi

fj_unpack "ffmpeg-$FJ_FFMPEG_VERSION" "ffmpeg-$FJ_FFMPEG_VERSION.tar.xz"
rm -rf "$FJ_MPV_BUILD/ffmpeg" "$prefix"
mkdir -p "$FJ_MPV_BUILD/ffmpeg"
cd "$FJ_MPV_BUILD/ffmpeg"
"$FJ_MPV_SRC/ffmpeg-$FJ_FFMPEG_VERSION/configure" "${args[@]}"
make -j"$FJ_JOBS"
make install
echo "$want" > "$stamp"
