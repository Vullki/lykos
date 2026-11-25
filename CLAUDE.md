# Project rules

- Lykos: open-source, unofficial iOS app for claude.ai. Credit Anthropic in text only (the README's credit block and the release notes); never add Anthropic logos, icons or artwork.
- The two docs are the source of truth: `Lykos — Project Idea.md` (what and why) and `Lykos — Project Plan.md` (phases, checklists, starter prompts). Read the matching phase before starting work.
- Bundle ID `com.vullki.lykos` and App Group `group.com.vullki.lykos` are permanent. Never change them: the app's login data is tied to the bundle ID. The ID lives once, as `LYKOS_BUNDLE_ID` in `project.yml`; forks override it with the `LYKOS_BUNDLE_ID` repo variable, so never hard-code the bundle ID anywhere else. Extensions are `com.vullki.lykos.share` and `com.vullki.lykos.widget`.
- XcodeGen project.yml is the source of truth. Never commit *.xcodeproj.
- Never create, commit or print certificates, passwords or provisioning profiles.
- We work on Windows: verify every change through the GitHub Actions build.
- Keep JavaScript injection into claude.ai to the minimum a feature needs.
- Main-frame navigation stays in-app only for claude.ai and its subdomains.
- Small, reviewable commits. Explain any new Info.plist key or entitlement.

## Design

- Design system: DARK's Brushed Silver Noir (kept outside this repo, in his `#DΛЯK_DESIGNS` folder as `designv2.md`). Black `#000` background, silver and off-white `#E6E4DF` only. No color, no crimson, no wolf eye.
- The icon is DARK's own "LY" brushed-steel design (since 2026-11-25; the first "Ly" is archived in `design/icon/archive-ly-v1/`). Sources and exports live in `design/icon/final/`. Don't redraw or "fix" it unasked.
- Asset catalog: `AppIcon` (Any / Dark / Tinted), `LykosMark` (launch, lock, offline screens, widget), `LaunchBackground` (`#000`).

## Repo and commits

- Twin repos with the same history: **`Vullki/lykos`** (public: unsigned builds and Releases, no secrets) and **`Vullki/lykos-private`** (private: holds the four signing secrets, so its CI builds the signed IPA for the owner's phone). The pre-public history is kept only in the private repo, on branch `archive/pre-public`.
- Local `origin` fetches from the public repo and has two push URLs, so one `git push` updates both. Never push a branch or tag to only one of them, and never add signing secrets to the public repo: its workflow artifacts are downloadable by anyone, and a signed IPA carries the owner's profile.
- Push with the DVRRK GitHub account. Commit identity: `DVRRK <contact@vullki.com>`. Never a personal email, and never the owner's legal name, Apple Team ID or device IDs in files (public docs credit DARK / Vullki).
- Text files are UTF-8 without BOM, LF line endings. Don't rewrite them with PowerShell `Set-Content`.

## Releases

- Lykos is open source (since 2026-11-25) as an unofficial iOS app for Claude AI, with full credit to Anthropic in the README and release notes. MIT `LICENSE` (Vullki).
- Minimum iOS is 15, so TrollStore devices (iOS 15.0 to 16.6.1, 16.7 RC, 17.0) can install it. Guard anything newer with `#available` and keep the iOS 16+ look unchanged; CI's compiler is the check.
- To release: bump `MARKETING_VERSION` in `project.yml`, add a CHANGELOG section, then push the matching tag (`v0.1.1` for `0.1.1`) to both repos. On the public repo the release job publishes the unsigned IPA, the same build as a `.tipa` (TrollStore) and `altstore-source.json` (AltStore / SideStore source at `releases/latest/download/altstore-source.json`, built by `scripts/altstore_source.py`). It fails if the tag and version don't match, and it skips on the private repo. Never attach a signed IPA to a release.
- README and AltStore screenshots live in `docs/screenshots/` (`launch`, `chat`, `sidebar`, `code`). The source links them at the release tag.
