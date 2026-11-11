# Security Policy

## Reporting a vulnerability

Use this repository's **Security → Report a vulnerability** feature when private
reporting is enabled. If it is unavailable, contact the repository maintainer
privately before publishing exploit details or sensitive captures. Test only
systems and data you own or have permission to assess.

Include the application version, macOS version, reproduction steps and expected
impact. Remove private images, recordings, tokens and personal data from examples.

## Supported version and distribution

Only the latest release of **MShot** is supported. The application has
no built-in updater: security fixes are distributed through this repository's
Releases page and must be downloaded and installed manually. Use the accompanying
`SHA256SUMS.txt` to check a download against the published release checksum.

Release automation can optionally sign and notarize the app with Apple
credentials. Without those credentials, release artifacts are ad-hoc signed and
not notarized. A signature or checksum alone does not establish that an artifact
matches reviewed source code.

## Security boundaries

- The app is sandboxed without network-client permission and uses Apple frameworks
  for local image, video, OCR, translation and speech processing.
- There are no third-party Swift package dependencies or bundled update services.
- External URL commands and the system share sheet are user-configurable features;
  their presence does not grant external callers arbitrary command execution.
- Editable history and original recordings are recovery data, not securely erased
  or application-encrypted storage. Redacting an exported image does not erase its
  original from history or backups.
- Automatic redaction is best-effort. Review sensitive images before sharing.

Report flaws in macOS frameworks to Apple, and notify this repository's maintainer
when the application needs a workaround or supported-version change.
