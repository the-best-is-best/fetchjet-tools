# libmpv for Linux x86_64

One self-contained `libmpv.so.2` for the FetchJet native desktop player, published as `libmpv-linux-x64-<version>.gz`
in the release `libmpv-<version>`. The app downloads it on first use into `<app home>/tools/libmpv.so.2`.

## What is inside

| Part | Version | How |
|---|---|---|
| mpv | 0.42.0 | `-Dgpl=false` (LGPL), libmpv only, software render API, no OpenGL / Vulkan / X11 / Wayland |
| FFmpeg | 7.1.1 | static, `--disable-everything` plus the same demuxer / decoder / parser / bsf / filter lists as Windows and macOS |
| dav1d | 1.5.1 | static |
| libass | 0.17.5 | static, fontconfig font provider |
| fontconfig | 2.16.0 | static, reads the system's `/etc/fonts/fonts.conf` and caches |
| freetype, fribidi, harfbuzz | 2.13.3, 1.0.18, 15.2.0 | static |
| expat, zlib | 2.7.1, 1.3.1 | static |
| libplacebo | 7.387.0 | static, no Vulkan / OpenGL |

Audio output: PulseAudio (works on PipeWire through `pipewire-pulse`) and ALSA. `libpulse.so.0` and `libasound.so.2` are
linked as normal shared libraries (every desktop distro has both); if one is missing `dlopen` fails and the app opens
files with the system player.
Everything else is linked in. Only the `mpv_*` functions are exported (`libmpv.map`, `--exclude-libs,ALL`), so the
static FFmpeg and fontconfig do not clash with system copies loaded in the same process.

## Build

Needs gcc / g++, make, cmake, nasm, gperf, pkg-config, meson >= 1.3, ninja, python3 with jinja2, and the
`libpulse-dev` / `libasound2-dev` headers. On Ubuntu:

```
sudo apt-get install build-essential cmake nasm gperf pkg-config meson ninja-build python3-jinja2 libpulse-dev libasound2-dev
FJ_MPV_WORK=~/fj-libmpv-linux bash libmpv/linux/build-all.sh
```

An older distro's meson is too old: put meson, ninja and jinja2 into a venv at `$FJ_MPV_WORK/venv` (`env.sh` uses it).
Use a work folder on a Linux file system (under WSL not on `/mnt/c` or `/mnt/e`, it is many times slower).

| Script | Does |
|---|---|
| `fetch-sources.sh` | downloads the sources (about 50 MB) into `dl/`, each checked against its sha256 |
| `build-deps.sh` | static zlib, expat, freetype, fribidi, harfbuzz, fontconfig, libass, dav1d, libplacebo into `out/` |
| `build-ffmpeg.sh` | static FFmpeg into `out/` |
| `build-mpv.sh` | `dist/libmpv.so.2` and `dist/libmpv-linux-x64-<version>.gz` (`gzip -9n`), then `check.sh` |
| `check.sh` | needed shared libraries, the 15 functions the app calls, no other exports, newest glibc version |
| `build-all.sh` | all of the above; skips the deps / FFmpeg steps when `out/` was built by the same scripts |

The glibc the result needs is the glibc of the build machine. The release is built by
`.github/workflows/libmpv-linux.yml` on `ubuntu-22.04` (glibc 2.35), so it runs on Ubuntu 22.04, Debian 12,
Fedora 36, RHEL 9 and newer. A build on a newer distro only runs on that glibc or newer.

A new mpv version: add its sha256 to the `case` in `fetch-sources.sh`.
