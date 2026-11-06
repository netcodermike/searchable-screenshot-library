# Validation record

Authoring host: Windows, November 6, 2026. Requirements: Swift 5.9+ / SwiftUI / Vision; macOS 13+ with Xcode command-line tools.

The README verification command is `swift build -c release`. The companion GitHub Actions workflow describes reproducible build/test checks. Merely including that workflow does not mean it ran successfully. Host-specific verification results are recorded before publication.

Manual acceptance steps are in README.md. GUI behavior, hardware sensors, permissions, audio output, and OS isolation need verification on their target platform; compilation alone cannot establish these properties.

## Authoring result

Target toolchain/platform unavailable on the Windows authoring host. Source and build configuration were reviewed, and a target-platform GitHub Actions build/check workflow is provided. No successful native build or runtime result is claimed yet.

## Observed GitHub Actions result

Passed on November 6, 2026: [build/check run](https://github.com/netcodermike/searchable-screenshot-library/actions/runs/42196343566).

Verified source commit: `7058e790dbcf881ad1431d0ce76f922332c52261`.

Native macOS release build with Swift. OCR/GUI interaction was not exercised by CI.

This record may be committed after the linked source-validation run; the linked SHA identifies exactly what was checked. Native GUI/hardware acceptance remains manual as described in README.md.
