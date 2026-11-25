# libmpv for Windows x64

Builds the `libmpv-2.dll` that FetchJet's native desktop player loads at run time: one self-contained DLL that needs only DLLs that come with Windows (KERNEL32, USER32, GDI32, ole32, SHELL32, ADVAPI32, ntdll, AVRT, bcrypt, SHLWAPI, RPCRT4, DWrite and the `api-ms-win-*` UCRT sets).

| Part | Version | How it gets in |
|---|---|---|
| mpv | 0.42.0 | source tarball from github.com/mpv-player/mpv, built as `libmpv` only |
| FFmpeg | 7.1.1 | source tarball from ffmpeg.org, minimal static build (`build-ffmpeg.sh`) |
| dav1d, libass, libplacebo and their dependencies (freetype, harfbuzz, fribidi, fontconfig, ...) | whatever MSYS2 CLANG64 ships when the build runs | static libraries from the packages in `packages.txt`, linked in |

The two files in `pc/` replace the MSYS2 `libass.pc` and `libplacebo.pc` so that meson links both, and everything they need, statically.

## Licence

mpv is built with `-Dgpl=false`, so it is LGPL 2.1 or later. FFmpeg is built without any GPL or non-free part (`--enable-version3` makes it LGPL 3). dav1d, libass, libplacebo, freetype (FTL), harfbuzz, fribidi and the rest are under licences that allow static linking into an LGPL library. The released file is the LGPL library; anyone can rebuild it from this folder.

## What it plays

Video is decoded in software and handed to the app through mpv's software render API (`vo=libmpv`, no OpenGL, no Direct3D). Audio goes out through WASAPI.

- Containers: MP4 / MOV / M4A, Matroska / WebM, Ogg, MP3, FLAC, WAV, AAC (ADTS), MPEG-TS, MPEG-PS, AC-3, E-AC-3, AIFF, APE, ASF / WMA, AVI, FLV, WavPack, TTA, CAF, DTS, W64, AMR, raw PCM, MPEG video, raw H.264 / HEVC, IVF, OBU.
- Video: H.264, HEVC, VP8, VP9, AV1 (dav1d), MPEG-4 Part 2, MPEG-1 / MPEG-2, and MJPEG / PNG / GIF / BMP / WebP (cover art).
- Audio: AAC (and LATM), MP3, MP2, Opus, Vorbis, FLAC, ALAC, AC-3, E-AC-3, APE, WavPack, TTA, DTS, TrueHD, WMA v1 / v2, PCM (8 to 64 bit, A-law, mu-law).
- Filters used by mpv for speed, volume and format changes: aresample, atempo, scale, format, volume, and a few more (see `build-ffmpeg.sh`).
- Subtitles: FFmpeg demuxers srt, ass, webvtt and decoders subrip, srt, ass, ssa, movtext, webvtt, text, dvdsub, pgssub, dvbsub (side files and tracks inside the video); libass draws them.
- Only local files and pipes: FFmpeg's network protocols are left out (FetchJet plays files it has downloaded).

## Build on your PC

1. Install [MSYS2](https://www.msys2.org) and open the **MSYS2 CLANG64** shell.
2. `pacman -S --needed $(cat packages.txt)`
3. `FJ_MPV_WORK=<work folder> ./build-all.sh` (the work folder defaults to `./work`).

The result is `<work folder>/dist/libmpv-2.dll` and `<work folder>/dist/libmpv-windows-x64-0.42.0.gz` (`gzip -9n`); the script prints the gz's sha256. A full build takes about 4 minutes on a 16-thread PC (FFmpeg about 3.5, libmpv about half a minute). `FJ_JOBS` sets the number of parallel jobs (default: all cores).

Steps, each can run on its own:

- `fetch-sources.sh`: puts the tarballs in `<work>/dl` and checks their sha256. Set `FJ_MPV_SOURCE_CACHE` to `:`-separated folders that may already hold them (any file name, matched by sha256) to skip the download.
- `build-ffmpeg.sh`: FFmpeg into `<work>/out/ffmpeg`; does nothing when it is already installed with the same configuration.
- `build-mpv.sh`: libmpv, strip, gzip, and a check that the DLL needs no DLL outside Windows.

`FJ_MPV_VERSION` picks the mpv version (default 0.42.0); a new version needs its tarball sha256 in `fetch-sources.sh`.

## Build in CI

`.github/workflows/libmpv-windows.yml`, run by hand (Actions > libmpv Windows > Run workflow) with:

- `version`: mpv version (default 0.42.0).
- `publish`: when on, creates the release `libmpv-<version>` if it does not exist (not marked as latest) and uploads the gz, replacing a file with the same name.

The job summary shows the gz's size and sha256, and the gz is also kept as a run artifact. The MSYS2 libraries are rolling, so two builds a few weeks apart differ by a few bytes: put the sha256 of the file that was actually published into FetchJet's `PlayerLibraryPin`.
