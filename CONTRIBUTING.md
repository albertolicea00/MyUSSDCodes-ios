# Contributing to My USSD Codes — iOS

Thanks for your interest! Contributions of all sizes are welcome.

## Where things go

- **App bugs and features** → this repository.
- **New USSD codes / collections** → the [catalog repository](https://github.com/albertolicea00/my-ussd-codes). The app only bundles a seed copy of the GSM standard collection.
- **Android work** → [my-ussd-codes-apk](https://github.com/albertolicea00/my-ussd-codes-apk).

## Getting started

1. Fork and clone the repository.
2. Open `MyUSSDCodes.xcodeproj` in Xcode 16 or newer and run on a simulator.
3. Create a branch: `feat/group-reordering`, `fix/tel-url-encoding`.

## Guidelines

- Swift + SwiftUI, iOS 17+, no third-party dependencies.
- All code, strings and docs in **English**.
- State changes go through `CodeStore` so persistence stays consistent.
- Dialing stays on `tel:` URLs — the user must always confirm the call themselves. iOS blocking certain USSD codes is an OS restriction; don't try to bypass it.
- The Xcode project uses file-system-synchronized groups: put new files in the right folder under `MyUSSDCodes/` and they join the target automatically.
- Keep PRs focused: one logical change per PR. Screenshots for UI changes.

## Commit style

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), lowercase imperative subject, ≤ 72 chars:

```
feat: add group reordering
fix: encode hash in tel url
docs: document import format
refactor: extract run code sheet
chore: bump deployment target
```

## Code of Conduct

By participating you agree to our [Code of Conduct](CODE_OF_CONDUCT.md).
