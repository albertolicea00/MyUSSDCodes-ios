# CLAUDE.md

Guidance for AI assistants (Claude Code) working in this repository.

## What this repository is

The **iOS app** of My USSD Codes: browse, organize and run USSD codes. Swift 5 + SwiftUI, iOS 17+, no third-party dependencies, Xcode 16 project (`objectVersion 77`, file-system-synchronized groups — files added on disk under `MyUSSDCodes/` join the target automatically).

**This is NOT a monorepo.** The catalog data lives in [my-ussd-codes](https://github.com/albertolicea00/my-ussd-codes) and the Android app in [my-ussd-codes-apk](https://github.com/albertolicea00/my-ussd-codes-apk) — separate repositories. Never add USSD code data here beyond the bundled seed resource.

## Architecture

- `CodeStore` (`@MainActor ObservableObject`) is the single source of truth: `AppData` (codes, groups, imported collections), injected via `environmentObject`. Every mutation persists to one pretty-printed JSON file in Application Support. No database on purpose — the dataset is tiny. First run seeds from `Resources/gsm-standard.json` (verbatim copy of the catalog repo file).
- `UssdDialer` replaces `{placeholders}` with user input and opens a `tel:` URL (`#` must stay percent-encoded). iOS blocks some USSD codes at the dialer level — that's an OS restriction, don't try to bypass it.
- Views: `RootView` owns the `TabView` (3 tabs: Sections / All codes / Settings). Shared pieces (`CodeRow`, `CodeListView`, `RunCodeSheet`) live in `Views/Components.swift`.
- Models mirror the catalog schema with custom `init(from:)` supplying defaults for optional JSON fields. Invariants: `code` only contains `*#+0-9` and `{placeholders}`; every placeholder has a matching `CodeVariable`; `dangerous == true` shows a warning before dialing; user-created codes have `custom = true`.

## Commands

```bash
xcodebuild -project MyUSSDCodes.xcodeproj -scheme MyUSSDCodes \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Conventions

- All code, strings and docs in **English**.
- **Conventional Commits**, lowercase imperative subject, ≤ 72 chars (`feat: add group editor`, `fix: encode hash in tel url`).
- **Never add AI attributions, `Co-Authored-By` trailers or "Generated with" footers to commits or PRs.**
- New USSD code data goes to the catalog repository, not to this app.
