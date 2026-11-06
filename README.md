# Searchable Screenshot Library

[![Build and verify](https://github.com/netcodermike/searchable-screenshot-library/actions/workflows/verify.yml/badge.svg)](https://github.com/netcodermike/searchable-screenshot-library/actions/workflows/verify.yml)


Import screenshots into a native Mac library, recognize text locally, group by topic, search recognized content, and inspect or delete copies.

**Language:** Swift 5.9+ / SwiftUI / Vision  
**Platform:** macOS 13+ with Xcode command-line tools  
**Status:** First-release learning project. See implemented scope and limitations below; this is not a production-completeness claim.

## Features

- Multiple PNG/JPEG/TIFF import with duplicate detection by SHA-256.
- Accurate Vision OCR runs in a background task on the Mac.
- Search by filename and recognized text.
- Rule-based Code, Receipts, Travel, and General topics.
- Image/text inspection, Finder reveal, and library-copy deletion.

## Requirements and quick start

Clone the repository, enter its folder, and install the language/platform tools listed above. Commands run from the repository root. No credentials are required except for Backup Vault's explicitly generated secrets.

```sh
git clone https://github.com/netcodermike/searchable-screenshot-library.git
cd searchable-screenshot-library
swift build
swift run ScreenshotLibrary
# Or open Package.swift in Xcode and run the executable target.
```

## Verification

```sh
swift build -c release
```

Import an image containing `const example = 42`, a receipt with `subtotal`, and a travel ticket with `flight`. Verify search terms match recognized text and topics are assigned. Import the same file twice and confirm no duplicate. Restart and verify persistence. Delete a library copy and confirm the original source screenshot remains.

See [validation notes](docs/VALIDATION.md) for what was actually executed during authoring. A committed CI workflow is a future check until its run is observed successful.

## Architecture and data

`Package.swift` defines a macOS executable. `Sources/ScreenshotLibrary/App.swift` contains the Codable `Shot` model, main-actor observable `Library`, import/OCR pipeline, and split-view UI. Original bytes determine identity; imported image copies are re-encoded to PNG. Images and the atomic JSON index live under `~/Library/Application Support/NetCoderMikeScreenshotLibrary/`. The original source files are never moved/deleted. Search filters in memory. Topic rules inspect OCR keywords; ties use alphabetic topic order. Images are capped at 40 MiB of input data.

The application uses Apple's Vision `VNRecognizeTextRequest`, AppKit file pickers/images, SwiftUI, and CryptoKit; no third-party packages or remote OCR service. Text recognition is started from a user-selected file import, so full-screen recording permission is unnecessary.

## Limitations and next steps

macOS only. There is no recursive folder watcher, semantic search, embedding index, manual topic editor, annotation system, or cloud sync. OCR accuracy depends on image resolution, contrast, orientation, and supported languages. Topic classification is keyword-based. The library/index are plaintext and may contain sensitive screenshot text. JSON is loaded into memory and intended for modest personal libraries. A failed import can leave an unreferenced PNG copy. Launch only one app instance per library.

## Troubleshooting

Install Xcode command-line tools (`xcode-select --install`) if Swift or SDKs are unavailable. The app requires a macOS graphical session. Empty OCR results do not mean the image failed to import; inspect the screenshot and try a clearer crop. If the index is corrupted, preserve the library directory and restore a backup of `index.json`. Finder reveal opens the library copy. Deleting a record removes that copy, while leaving the originally imported screenshot intact.

## Development

Read the source entry point described above, make a focused change, run the verification command, and exercise the relevant manual scenario. [Contributing](CONTRIBUTING.md) explains bug reports and pull requests; [security notes](SECURITY.md) describe the trust assumptions. Runtime/generated files are ignored. No telemetry or paid API dependencies are included.

## License

[MIT](LICENSE), copyright 2026 netcodermike.
