# fetchjet-tools

Tools that [FetchJet](https://github.com/the-best-is-best/FetchJet) downloads at run time, with the recipes that build them and the workflows that publish them.

FetchJet does not need this repository to build. The app downloads the finished files from this repository's releases the first time it needs them and checks each file against a sha256 pinned in the app. This repository is a submodule of FetchJet at `tools/fetchjet-tools` so the recipes can be edited next to the app.

| Folder | What it builds | Used by |
|---|---|---|
| `libmpv/windows` | `libmpv-2.dll` (Windows x64) | the native desktop media player |
| `libmpv/macos` | `libmpv.2.dylib` (macOS arm64) | the native desktop media player |
| `libmpv/linux` | `libmpv.so.2` (Linux x64) | the native desktop media player |

## Releases

This repository holds the build recipes of every tool FetchJet downloads. Each tool has its own releases, tagged `<tool>-<tool version>-<build>`. libmpv: tag `libmpv-<mpv version>-<build>` (for example `libmpv-0.42.0-1`), one asset per platform: `libmpv-<os>-<arch>-<mpv version>.gz` (a single gzip-compressed library, self-contained, LGPL build of mpv). Assets are never overwritten: a changed build gets the next build number, and every FetchJet version pins the release tag and the sha256 of its own files, so older apps keep downloading what they were built with. After publishing a new build, put the tag and the sha256s in `PlayerLibraryPin` in FetchJet (`sharedLogic/src/nativeDesktopMain/kotlin/com/michelle/raouf/fetch_jet/feature/media_extractor/PlayerLibrary.nativeDesktop.kt`).

## Licence

The libraries are built from mpv with `-Dgpl=false` (LGPL 2.1 or later) and a minimal FFmpeg (LGPL). Each recipe lists its sources and versions.
