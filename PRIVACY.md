# Privacy Policy

**Last updated:** November 11, 2026

macshot Offline processes screenshots, recordings, OCR and annotations on your
Mac. The project ships one application, has no third-party package dependencies,
and does not include an updater, analytics service, built-in cloud upload,
web translation/search, or keyboard-content recording integration.

## Local processing and storage

- OCR uses Apple Vision. Translation uses Apple's on-device Translation framework
  on macOS 15 or later, requires already-installed language packs, and never falls
  back to a web translation service. Install missing packs separately in System Settings.
- Captions require on-device speech recognition; unsupported configurations fail
  instead of sending audio to a recognition server.
- Screenshots and exports are stored in the selected folder. Editable screenshot
  history can retain the original, unredacted image and annotations under
  Application Support. Disable history before sensitive captures and clear
  existing history separately.
- Original recordings, pointer/click data, optional camera tracks and project
  edits remain under Application Support for recovery. Closing the editor or
  deleting an exported copy does not delete these originals. Obsolete typed-input
  records in older pointer files are discarded while loading; existing files and
  backups are not rewritten by that discard.
- Preferences are stored in UserDefaults. Startup removes retired upload and
  updater preferences, beta-channel settings and local Google token files.
  Settings import/export rejects retired configuration. This does not revoke previous
  account authorizations or delete previously uploaded remote files; manage those
  with the relevant service.

## Network access and sharing

The sandboxed app has no network-client entitlement and performs no update
checks, update downloads or built-in cloud requests. Image imports use local
files and system image support. New application versions are downloaded and
installed manually outside the app.

Opening a QR HTTP(S) link or the project website launches your browser. The macOS
share sheet exports content only when you invoke it and select a service or
recipient. Those browser and system services have their own network behavior and
privacy policies. The app does not block networking by other processes or by macOS.

## Permissions

Screen Recording enables screenshots and video capture. Optional microphone and
camera capture require their respective system permissions. Input Monitoring or
Accessibility can be used for mouse effects and scroll-capture controls; keyboard
event handling is limited to shortcuts and capture controls rather than recording
typed content. Permissions can be revoked in System Settings.
