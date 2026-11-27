# libmpv for Windows 7 / 8 / 8.1 x64

The player library of FetchJet's Windows 7 / 8 / 8.1 edition. Same mpv, FFmpeg and MSYS2 libraries as `../windows` (it uses that folder's `env.sh`, `fetch-sources.sh`, `build-ffmpeg.sh`, `packages.txt` and `pc/`), with one difference: `win7-shim.c` is linked in.

The normal `libmpv-2.dll` does not load on Windows 7 because it imports two Windows 8 function sets:

| Import | Comes from | Shim |
|---|---|---|
| `WaitOnAddress`, `WakeByAddressAll`, `WakeByAddressSingle` (`api-ms-win-core-synch-l1-2-0`) | libdovi (Rust, linked through libplacebo): the Rust standard library's locks | one SRW lock + condition variable (Vista and later); spurious wake-ups are allowed by the API |
| `PathCchRemoveFileSpec` (`api-ms-win-core-path-l1-1-0`) | mpv's `osdep/w32_register.c` (`mpv --register`, never called through libmpv) | `PathRemoveFileSpecW` (shlwapi) |

Objects on the link line win over import libraries, so the DLL defines these functions itself and imports neither set. `build-mpv.sh` fails when the DLL still imports a known Windows 8+ function or DLL set.

Build: in an MSYS2 CLANG64 shell with `../windows/packages.txt` installed, `FJ_MPV_WORK=<work folder> ./build-all.sh`. Result: `<work>/dist/win7/libmpv-2.dll` and `libmpv-windows-x64-win7-<version>.gz`.

CI: `.github/workflows/libmpv-windows-legacy.yml` (Actions > libmpv Windows 7), same inputs as the Windows one; the release is `libmpv-<version>-win7-<build>`, never overwritten. FetchJet's Windows 7 edition pins the sha256 of the published gz.
