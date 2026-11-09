# Privacy and update hardening

Both normal and Offline builds now exclude built-in image hosting, Google Drive
and S3 uploads, web translation, OCR web search and keyboard recording.

Local OCR, Apple on-device translation, pointer/click recording, microphone,
camera, captions, file exports and the system share sheet remain available.
Translation requires macOS 15 and already-installed Apple language packs; it
fails visibly instead of falling back to a network provider. Updates still use
Sparkle and the existing separate normal/Offline appcasts.

## Update supply chain

- The project and resolved package file pin Sparkle 2.9.6, commit
  `ac2def288cbff5cfc7df3ffef6abdf45b72bcb0a`.
- This release includes the delta traversal fix for CVE-2026-47121 and the
  AppInstaller validation change for CVE-2026-47122: the installer requires a
  validated connection until it has both completed stage 1 and received the
  appcast data. Its source is available at the pinned upstream commit.
- SwiftPM's 2.9.6 binary archive SHA-256 is
  `8d5fb41d960b43f4a68aa14126bf62b098544ec8d191cdcc73eb14e63a8e7606`.
- Release signing also uses 2.9.6. `scripts/prepare-sparkle-tools.py` verifies the
  release archive against a checked-in digest before extracting any tool. The
  digest is from the official release asset metadata:
  `52bf9e88cdd972fc0c81501377a880e90d47031bd8ca5462488f843e2609e192`.
- The signing step uses a private temporary key file, cleans up on exit and
  stops on verification failure. CI actions are pinned to full commit SHAs;
  builds/tests use versions from the resolved package file. The lock uses the
  SwiftPM v2 format, which has no stale v3 origin hash after the explicit pin
  change and is readable by the selected Xcode toolchain.

Source and release metadata:

- https://github.com/sparkle-project/Sparkle/tree/ac2def288cbff5cfc7df3ffef6abdf45b72bcb0a
- https://github.com/sparkle-project/Sparkle/releases/tag/2.9.6

## Existing installations and files

Startup removes preferences for retired features and the old local Google token
file. Settings import/export rejects those preferences, preventing an old backup
from restoring them. Remote Google authorization and previously uploaded objects
must be revoked/deleted through their respective services.

Old pointer files still load: obsolete binary input records are skipped without
creating key events or exposing their text to the editor. Existing recordings
and screenshots are not deleted or rewritten. Previously captured keys that are
already burned into video pixels, old sidecar files or backups are not erased by
this code change. Editable screenshot history can still retain unredacted source
images; manage history separately for sensitive captures.

## Validation

Portable release verification tests (Python 3.12+):

```sh
python3 scripts/test-prepare-sparkle-tools.py
```

On macOS with Xcode 26, verify both build identities:

```sh
bash scripts/run-tests.sh
bash scripts/run-tests.sh --offline
xcodebuild build -scheme macshot -configuration Release -destination 'platform=macOS' -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO
xcodebuild build -scheme macshot -configuration Release -destination 'platform=macOS' -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) OFFLINE'
```

Native regression tests cover retired preference rejection, credential cleanup,
preservation of unrelated local files and skipping legacy input records while
retaining subsequent pointer events. Run the existing media tests for local
export/caption behavior as part of the full suite.

The editing environment is Linux: the Python verification tests and archive
hash checks were run, but Xcode compilation, XCTest and macOS UI checks were not
available. The test entry point exits 127 because `xcodebuild` is missing. These
native checks remain required before shipping.
