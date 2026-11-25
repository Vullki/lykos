# Changelog

All notable changes to Lykos are recorded here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The app version is `MARKETING_VERSION` in `project.yml`; the build number is the GitHub Actions run number. Builds 1 to 10 ran in the private development repo, so their run IDs and commit hashes refer to that history and aren't linked.

## [0.1.0] — 2026-11-25 — first public release

The first public release: the open-source repo, a GitHub Release with an unsigned IPA, a TrollStore `.tipa` and an AltStore / SideStore source. Same app as builds 6 to 8, now also for iOS 15 and 16.

### Builds

| Build | Run | Commit | What it was |
| --- | --- | --- | --- |
| 6 | 45490570241 | `9ca6cf5` | New brushed-steel "LY" icon. Signed (Ad Hoc), installed over build 5 on the iPhone 17, still signed in. Current build on the phone |
| 7 | 45513140990 | `f770c23` | Open-source prep, built by hand on branch `chore/open-source`. Unsigned and signed (Ad Hoc) both green, about 25 s each. The bundle ID still comes out as `com.vullki.lykos` through the new `LYKOS_BUNDLE_ID` setting, and the rebuilt export step worked with the "Lykos AdHoc" profile. Not installed on the phone (no app code changed). The release job was skipped as expected: it runs only for a version tag |
| 8 | 45513382049 | `6651bc9` | Open-source prep merged to `main`. Unsigned and signed green |
| 9 | 45515682618 | `4bd6232` | Minimum iOS lowered to 15: the compiler stopped on seven iOS 16-only calls in the debug log screen. Failed, as intended for this check |
| 10 | 45515929585 | `cef33a4` | Debug log screen with iOS 15 fallbacks. Unsigned and signed green, no warnings; the IPA reports `MinimumOSVersion 15.0` and bundle ID `com.vullki.lykos`. Not installed on the phone |

### Added — open source

- Lykos is prepared as an open-source, **unofficial iOS app for Claude AI**. The README credits Anthropic for Claude, states that Lykos is independent and not affiliated with or endorsed by Anthropic, and uses no Anthropic logos or artwork.
- MIT `LICENSE` (© 2026 Vullki).
- Public README: why it exists, what it does and doesn't do, install routes (a free Apple ID with Sideloadly, AltStore or SideStore; your own developer account built in a fork; or zsign), sign-in and connector tips, and a privacy note (no analytics, no third-party SDKs).
- Forks can build under their own bundle ID: `project.yml` sets it once as `LYKOS_BUNDLE_ID` (default `com.vullki.lykos`, unchanged for the original app), and CI reads the `LYKOS_BUNDLE_ID` repo variable when it's set. The signed job's profile check and export options follow it.
- Version tags (`v0.1.0` and later) publish a GitHub Release with three files: the unsigned IPA, the same build as a `.tipa` that opens straight in TrollStore, and `altstore-source.json` for AltStore and SideStore (one-tap install and update alerts at `releases/latest/download/altstore-source.json`). The release notes carry the credit line and a SHA-256. The job stops if the tag doesn't match `MARKETING_VERSION`, and it runs only on the public repo.
- `scripts/altstore_source.py` builds the AltStore source from the IPA's own Info.plist (bundle ID, version, build, minimum iOS, privacy strings) and carries earlier versions over from the previous release.
- **Minimum iOS lowered from 17 to 15**, so TrollStore devices (iOS 15.0 to 16.6.1, 16.7 RC and 17.0) can install Lykos. Only the hidden debug log screen used newer APIs: iOS 16+ keeps its look, and iOS 15 gets a NavigationView, the system share sheet and the system dark bar. `isInspectable` (iOS 16.4) sits behind `#available`. Builds and compiles for iOS 15; not yet run on an iOS 15 or 16 device.
- README: screenshots, a file-by-file and iOS-by-iOS install guide (AltStore / SideStore source, TrollStore, Sideloadly, your own developer account).

### Changed

- Project Idea, Project Plan and `CLAUDE.md` reworded for a public repo: no more "personal use only, never distributed", no owner's legal name or Apple Team ID, and the design system is referenced without a local path.
- **New app icon (2026-11-25): "LY" in brushed steel**, DARK's design, chosen over three vector candidates he also made. A bold italic L and Y in real brushed-steel grain, the L's top sweeping up into the Y's left arm, on a dark grained background. It replaces the satin-silver "Ly" (kept in `design/icon/archive-ly-v1/`). Any = his 1024 artwork as is (a full square; iOS applies the rounded mask); Dark and Tinted = the letters cut out onto transparency; `LykosMark` (launch and offline screens) = the same cut-out letters. Source (`design/icon/final/lykos-source.webp`) and the cut-out scripts (`design/icon/tools/`) are in the repo.
- Checked on the phone (2026-11-25): in dark mode iOS shows the Dark variant on its own dark glass tile, with clean edges, and the letters read clearly at home-screen size. Kept at its current size inside the tile (a ~10% larger mark was offered and declined).
- The signed IPA grew from about 478 KB to about 1.2 MB, because the brushed-grain PNGs compress less than the old flat gradients.

## Development builds — 2026-11-24

The first day: from two planning docs to a signed app on the iPhone 17 (iOS 27.2 beta), built without a Mac. Phases 0, 1 and 2 of the plan are done.

### Builds

| Build | Run | Commit | What it was |
| --- | --- | --- | --- |
| 1 | 45356951604 | `5f49e7e` | First cloud build. Phase 1 Swift compiled on the first try, with no fixes. Unsigned |
| 2 | 45357617117 | `f00471a` | Signing job fix (export method from the profile). Unsigned only, secrets not loaded yet |
| 3 | 45359119668 | `f00471a` | First signed IPA. Installed on the iPhone 17, signed in with the email code |
| 4 | 45361172250 | `a03e2e0` | Header moved out from under the status bar. Installed over build 3, still signed in |
| 5 | 45361922650 | `7c0576f` | Composer row moved above the home indicator |

### Fixed (from testing on the phone)

- claude.ai's composer row (Project, model picker) sat in the home-indicator area. The web view now respects every safe area, and a strip in the page's own colour fills the space behind the home bar (`7c0576f`, build 5).
- claude.ai's header (sidebar button, incognito) sat under the status bar and couldn't be tapped. The web view now starts below the status bar and clear of the Dynamic Island, and the strip behind the status bar takes the page's theme colour live (`a03e2e0`, build 4).
- Long-pressing a link no longer pops a Safari-style preview (`a03e2e0`, build 4).
- The signed build would have failed to export with an Ad Hoc profile because the export method was fixed at `debugging`. The method now follows the profile type (`debugging`, `release-testing` or `enterprise`), and the job stops with a clear error when a profile isn't for `com.vullki.lykos` (`f00471a`).

### Added — Phase 2: cloud build and signing

- `.github/workflows/build.yml` on `macos-26` with Xcode 26.6 (iOS 26.5 SDK), XcodeGen from Homebrew. Runs on pushes to `main` and by hand; pushes that only touch Markdown or `design/` don't build, and a newer push cancels an older run (`5f49e7e`).
- Route B: unsigned build packaged into `Lykos-unsigned.ipa`, kept as an artifact for 7 days (`scripts/package-ipa.sh`).
- Route A: signed build from a temporary keychain that is always deleted, with team ID, profile name and export method read from the profile at build time. A small Linux job checks for the four secrets first, so without them the signed job is skipped and costs no macOS minutes.
- A shared Lykos scheme in `project.yml` for CI builds and archives (`1e6d8fc`).
- Signing set up: App ID `com.vullki.lykos` and Ad Hoc profile "Lykos AdHoc" (3 devices, expires 2027-04-08) created in the Apple Developer portal; secrets `CERT_P12_BASE64`, `CERT_PASSWORD`, `KEYCHAIN_PASSWORD` and `PROFILE_APP_BASE64` loaded without printing them. The first signed log was checked: no password or certificate data in it.
- Measured cost: a build takes about 27 seconds, billed as about 1 macOS minute.

### Added — Phase 1: the WKWebView shell

- SwiftUI app with one full-screen WKWebView on claude.ai, created once and never torn down (`9bdc255`, `a286413`).
- Persistent login through the default website data store; inline media and swipe back and forward.
- Host rules (`AllowedHosts.swift`): main-frame navigation stays in the app only for `claude.ai` and its subdomains; other links open in Safari or their own app; subframes (artifacts, Cloudflare checks) are never blocked; `target=_blank` follows the same rule (`5faf5cb`).
- Microphone and camera granted only to https claude.ai and denied (and logged) for everything else.
- Downloads through `WKDownload`, then the iOS share sheet; temporary copies are removed afterwards.
- Reload after a web content process crash; an offline screen with Retry that only covers the page, plus an automatic retry when the network comes back; pull to refresh.
- Launch view matching the iOS launch screen (the Ly mark on black), fading out on the first page load, with a 12-second fallback.
- Hidden debug log (three-finger long press on the page, or a long press on the offline screen): claude.ai console messages, uncaught errors and native load failures, shareable as text and also sent to the device log. Its small console bridge is the only script injected into claude.ai.
- `lykos://new` opens a new chat; a one-line user-agent switch, off by default.
- Info.plist keys in `project.yml`: microphone, camera, photo library, photo library add (needed for "Save Image" from the share sheet) and the `lykos` URL scheme (`967118a`).
- Native screens in Brushed Silver Noir colours (`Noir.swift`).

### Added — Phase 0: repository bootstrap

- Private repo `Vullki/lykos`; commits as `DVRRK <contact@vullki.com>` (`d46e650`).
- `project.yml` (XcodeGen): one iPhone-only app target, iOS 17 minimum, Swift 5 language mode, bundle ID `com.vullki.lykos`, Info.plist generated from the spec, `UILaunchScreen` instead of a storyboard.
- Asset catalog: `AppIcon` (Any, Dark, Tinted), `LykosMark` (480 px @3x, 160 pt on screen) and `LaunchBackground` (`#000`).
- `CLAUDE.md` repo rules, `README.md`, `.gitignore` (signing files, build output, the generated `.xcodeproj` and `Info.plist`) and `.gitattributes` (LF line endings for the macOS runner).

### Design

- Design system: DARK's Brushed Silver Noir (black, silver and off-white, no colour, no crimson wolf eye).
- Icon: **"Ly"**, designed by DARK — a heavy L with the y's tail sweeping around it, in satin silver on a dark background with two faint rings. Exports in `design/icon/final/`. Earlier concepts are kept for reference: Λ Monolith (`design/icon/archive-lambda/`), Wolf Bubble, Faceted Wolf and Ly Wrap (`design/icon/`).

### Planning

- Project Idea and Project Plan reviewed and updated before any code: connectors are set up on desktop, an in-app debug log replaces the missing Web Inspector on Windows, the IPA is installed without re-signing, the app switcher gets a privacy cover, `UILaunchScreen` replaces a storyboard, Action Button and Control Center joined the extras, and the studio name is Vullki.
- Decisions: bundle ID `com.vullki.lykos` (permanent), App Group `group.com.vullki.lykos`, repo `Vullki/lykos` (private).

### Still to check on the phone

Phase 1 checklist: voice input, photo, camera and file attachments, an outside link opening in Safari, airplane mode and Retry, and staying signed in after restarting the phone. Pull to refresh and downloads made inside a chat also need a real test.
