# PDFium

The desktop PDF reader of FetchJet uses PDFium. It is not built here: `package.sh` takes the prebuilt
library of [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries) (Apache 2.0 / BSD) for one
chromium build, checks each archive against `sources-<chromium>.sha256`, and gzips the one library per platform:
`pdfium-windows-x64-<chromium>.gz` (pdfium.dll), `pdfium-linux-x64-<chromium>.gz` (libpdfium.so),
`pdfium-macos-arm64-<chromium>.gz` (libpdfium.dylib), plus `LICENSE.pdfium.txt`.

Workflow `PDFium`: inputs `chromium`, `build`, `publish`. Release tag `pdfium-<chromium>-<build>`, assets never
replaced. A new chromium build needs its `sources-<chromium>.sha256` first (from the release page digests).
After publishing, pin the tag and the three sha256 in FetchJet (`PdfLibraryPin`).

The app downloads it only when the user opens a PDF in the app; it is never part of the media tools update.
