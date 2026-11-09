# Privacy Policy

**Last updated:** November 9, 2026

Screenshots, recordings, OCR and annotations are processed on your Mac. This build has no image hosting, Google Drive, S3 upload, Google translation, AI Search, or keystroke recording integration. Both build variants have these restrictions. There is no analytics or telemetry collection service.

## Local processing and storage

- OCR uses Apple Vision. Translation uses Apple's on-device Translation framework on macOS 15 or later, requires installed language packs, and never falls back to a web translation service. Install missing packs separately in System Settings.
- Screenshots and exports are stored in the selected folder. Editable screenshot history can retain the original, unredacted image and annotations under Application Support. Disable history before sensitive captures and clear existing history separately.
- Original recordings, pointer/click data, optional camera tracks and project edits remain under Application Support for recovery. Closing the editor or deleting an exported copy does not delete these originals. No keyboard events are captured; obsolete input records in older pointer files are discarded while loading.
- Preferences are stored in UserDefaults. Startup removes settings and local Google token files left by the retired integrations. This does not revoke existing Google account authorizations or delete previously uploaded remote files; manage those with the relevant service.

## Network access and sharing

Sparkle checks the configured GitHub appcast for updates; normal and Offline variants retain separate feeds. Requests expose normal network metadata such as the client IP. Update packages are signature-checked, and automatic downloading is disabled. Automatic checks can be disabled in Settings. The Offline name does not mean all networking is blocked.

Opening a QR HTTP(S) link or the project website uses your browser. The macOS share sheet exports content only when you invoke it and select a recipient. These system-directed actions are distinct from the removed built-in upload integrations.

## Permissions

Screen Recording enables screenshots and video capture. Optional microphone and camera capture require their respective system permissions. Input Monitoring is used only for the optional mouse-click overlay, not keyboard recording. Permissions can be revoked in System Settings.
