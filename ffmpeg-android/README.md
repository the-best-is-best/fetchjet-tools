# ffmpeg-android

`ffmpeg` and `ffprobe` for FetchJet's Android app, built from source with the Android NDK for
`arm64-v8a`, `armeabi-v7a`, `x86_64` and `x86`. They are named `libffmpeg.so` / `libffprobe.so` so the
APK installer unpacks them next to the app's native libraries (Android 10 and later only runs programs
that came with the APK, so the app cannot download them at run time: FetchJet's build puts them in the APK).

Only the parts FetchJet uses are built (`config.sh`), plus the network protocols (`http`, `https`, `tls`
through Mbed TLS, `hls`) so yt-dlp's "only the clip" download can read a part of a video from the site.

```
ANDROID_NDK_ROOT=<ndk 28.2.13676358> ffmpeg-android/build.sh dist
```

Every source archive is checked against `sources.sha256` before it is unpacked. The result is
`dist/ffmpeg-android-<ffmpeg version>.zip` (one folder per ABI) and its `.sha256`.

Release tag `ffmpeg-android-<ffmpeg version>-<build>` (workflow `ffmpeg-android.yml`). After publishing,
put the tag and the sha256 in FetchJet's `tools-pins/ffmpeg-android.txt`.
