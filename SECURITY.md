# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please open an issue on the [catalog repository](https://github.com/albertolicea00/my-ussd-codes/issues) or email me directly. I'll respond within 48 hours.

Do not open public issues for critical vulnerabilities — use email instead.

## Scope

- This app uses `tel:` URLs only — no call permissions, no network calls (except fetching collections from user-provided URLs).
- The app does not collect, transmit, or store any personal data.
- Collection imports are validated against a JSON Schema — malformed input is rejected, not executed.

## Supported Versions

Only the latest release receives security updates. Always update to the newest version.
