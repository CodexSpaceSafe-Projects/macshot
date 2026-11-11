# Offline application boundaries

The project ships one sandboxed app, **macshot Offline**, with bundle identifier
`com.sw33tlie.macshot.offline`. Capture, image editing, OCR, local translation,
recording and media export use Apple frameworks. There are no third-party Swift
package dependencies or bundled update helpers.

## Network boundary

The app has no network-client entitlement, built-in upload integration, update
checker or update downloader. Images are opened from local files; URL inputs
must not be passed through to an HTTP image loader. Translation requires macOS 15
and already-installed Apple language packs, and reports unavailable packs instead
of using a network fallback. Captions require on-device speech recognition.

Explicit QR/project links open the browser, and the system share sheet can send
content through the service chosen by the user. These external browser/system
actions are governed by those services, not by a machine-wide network block.
Release builds run on GitHub Actions and can contact GitHub and, when enabled,
Apple's notarization service; this is separate from installed-app behavior.

## Manual distribution

The release workflow builds and signs one app, packages `MacShot-Offline.dmg`,
and publishes it with `SHA256SUMS.txt` in the current repository's GitHub Release.
Actions are pinned to commit SHAs. Packaging uses macOS tools rather than
installing a package manager utility. New versions must be installed manually.
Default artifacts are ad-hoc signed and not notarized; configured Apple
credentials enable Developer ID signing and notarization.

## Existing installations and files

Startup removes retired upload, updater and beta-channel preferences and the old
local Google token file. Settings import/export rejects retired configuration so an old backup
cannot reactivate removed integrations. Previous account authorizations and
uploaded objects must still be revoked/deleted through their respective services.

Old pointer files remain readable: obsolete typed-input records are discarded
without exposing their text to the editor. Existing recordings, screenshots,
old sidecar files and backups are not rewritten or erased by this change.
Editable screenshot history can retain unredacted source images, and recording
originals remain available for recovery. Manage those files separately for
sensitive captures; see [history recovery](history-recovery.md).

## Validation

On macOS with Xcode 26:

```sh
bash scripts/run-tests.sh
xcodebuild build -scheme macshot -configuration Release -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Check that the built app's entitlements do not contain network-client permission
and that the app bundle has no third-party update frameworks or helper services.
Exercise local image import/export, existing settings migration, installed-pack
translation and on-device captions. Confirm old unsupported image-format
settings fall back to an available format.

Static source/configuration checks on Linux cannot establish macOS runtime
behavior or release/source equivalence. Native build, XCTest and UI checks remain
required before distribution; earlier historical test logs are not evidence for
this offline-only revision.
