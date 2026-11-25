# libmpv for macOS (arm64)

Builds one self-contained `libmpv.2.dylib` for Apple Silicon and packs it as `libmpv-macos-arm64-<version>.gz`, the file
FetchJet's native desktop player downloads the first time it plays something.

- mpv 0.42.0 (`FJ_MPV_VERSION`), shared library only, `-Dgpl=false`: LGPL 2.1 or later.
- Everything else is linked in statically, so `otool -L` lists only macOS itself:
  `/System/Library/Frameworks/{CoreFoundation,CoreAudio,AudioUnit,AudioToolbox,CoreText}` and
  `/usr/lib/{libSystem,libiconv,libz,libbz2}`.
- Install name `@rpath/libmpv.2.dylib`, minimum macOS 12.0, arm64 only, ad-hoc signed, no Objective-C code (so the
  library can be unloaded again).
- Audio output: CoreAudio only. Video: the libmpv software render API (FetchJet draws the frames itself), no OpenGL,
  no VideoToolbox, no Cocoa.
- 0.42.0 result: 12.5 MB dylib, 5.5 MB `.gz`.

## Sources

| What | Version | Notes |
|---|---|---|
| mpv | 0.42.0 | `-Dauto_features=disabled -Dlibmpv=true -Dcplayer=false -Dcoreaudio=enabled -Dgl=disabled -Dprefer_static=true` |
| FFmpeg | 7.1.1 | static, `--disable-everything --disable-autodetect`, only the demuxers / decoders / parsers / filters the player needs (same lists as the Windows build), version3 (LGPL 3) |
| dav1d | 1.5.1 | AV1 decoder, static |
| libass | 0.17.5 | subtitles, CoreText font provider, no fontconfig |
| freetype | 2.13.3 | no png / zlib / bzip2 / brotli |
| fribidi | 1.0.18 | |
| harfbuzz | 15.2.0 | all optional features off |
| libplacebo | 7.387.0 | Vulkan / OpenGL / D3D11 off |
| fast_float | 8.4.0 | header only, needed by libplacebo |
| Vulkan-Headers | vulkan-sdk-1.4.363.0 | headers only: libplacebo compiles its Vulkan stubs even with Vulkan off |

Build tools: Xcode command line tools, `pkgconf` (Homebrew), and meson, ninja and jinja2 (for libplacebo's templates),
which `fetch-sources.sh` puts into a Python venv in the work folder. The downloads come to about 50 MB.

## Build

```bash
brew install pkgconf
FJ_MPV_WORK=$PWD/work libmpv/macos/build-all.sh
```

The result is in `$FJ_MPV_WORK/dist`: `libmpv.2.dylib` and `libmpv-macos-arm64-<version>.gz`; the script prints
`otool -L`, the sizes and the sha256 of the `.gz`.

| Script | Does |
|---|---|
| `env.sh` | shared settings (sourced): work folders, `MACOSX_DEPLOYMENT_TARGET=12.0`, compiler flags |
| `fetch-sources.sh` | downloads the tarballs to `$FJ_MPV_WORK/dl`, the headers, and the venv; skips what is already there |
| `build-deps.sh` | dav1d, freetype, fribidi, harfbuzz, libass, libplacebo as static libraries in `$FJ_MPV_WORK/out` |
| `build-ffmpeg.sh` | the minimal static FFmpeg |
| `build-mpv.sh` | libmpv, strip, install name, ad-hoc signature, gzip, checksum |
| `build-all.sh` | all of the above; reuses the dependencies while `$FJ_MPV_WORK/out/.deps-done` exists (`FJ_MPV_REBUILD_DEPS=1` builds them again) |

## Fixes in the recipe

- **`cfstr_from_cstr` missing (mpv 0.42.0):** mpv compiles `osdep/utils-mac.c` only when Cocoa is enabled, but the
  CoreAudio output calls `cfstr_from_cstr` from it, so the library fails at `dlopen` with
  `symbol not found in flat namespace '_cfstr_from_cstr'`. `build-mpv.sh` adds that file (plain C) to the CoreAudio
  sources with a `sed` on `meson.build`. Turning Cocoa on instead would bring Objective-C into the library, and macOS
  never unloads a library that contains Objective-C.
- **libplacebo from a GitHub tarball** has no git submodules: `fast_float.h` and the Vulkan headers are downloaded
  separately into `$FJ_MPV_WORK/out/include`.

## In FetchJet

Because this library really unloads, FetchJet's host keeps it loaded after the player closes on macOS
(`desktopNative/host/player_mpv.cpp`, `stop_engine`): CoreAudio leaves a delayed dispatch block
(`io.mpv.coreaudio_stop_during_idle`) that would otherwise run in unmapped code and crash the app about a second after
closing the player. After publishing a new version, put the sha256 of the `.gz` in `PlayerLibraryPin.MACOS_ARM64_SHA256`.
