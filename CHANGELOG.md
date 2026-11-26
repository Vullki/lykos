# Changelog

All notable changes to Lykos are recorded here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The app version is `MARKETING_VERSION` in `project.yml`; the build number is the GitHub Actions run number. Since 2026-11-25 there are twin repos with the same history: the public [`Vullki/lykos`](https://github.com/Vullki/lykos) (unsigned builds and Releases) and a private one that signs builds for the owner's phone. Each counts its own runs, so the same commit can carry different build numbers in each. Builds 1 to 13 below ran in the private repo (its pre-public history is kept there), so their run IDs and older commit hashes aren't linked; public builds are marked "public".

## [Unreleased]

No app code changed since 0.1.1; this is the project around it.

### Added

- **Product Hunt launch scheduled** (2026-11-26) for **Sunday 2026-11-29 at 00:00 Pacific** (11:00 Bahrain), at [producthunt.com/posts/lykos](https://www.producthunt.com/posts/lykos) (public from launch day). Tagline "Open-source, unofficial iPhone app for Claude AI"; free; open source; solo maker. Links: this repo and [vullki.com/tools/lykos](https://vullki.com/tools/lykos/). Tags iOS, Open Source, Artificial Intelligence and GitHub; category AI Chatbots. The maker's first comment (why Lykos exists, what it does, what's next, and that it's unofficial with all credit for Claude to Anthropic) posts and pins at launch.
- `design/producthunt/`: the launch images at Product Hunt's 1270×760 gallery size (the four-screen showcase, the hero banner, chat and Code side by side) and a 240×240 thumbnail of the "LY" icon.

### Changed

- README (2026-11-25): the screenshots became one matched row with captions (`docs/screenshots/showcase.png`, source in `design/readme/showcase.html`), monochrome release / iOS / Swift / build / license badges and an install row (AltStore, SideStore, TrollStore, Sideloadly) were added ([`1965c3d`](https://github.com/Vullki/lykos/commit/1965c3d)), and a hero banner leads the page (`docs/hero.jpg`, [`5805b21`](https://github.com/Vullki/lykos/commit/5805b21)).

## [0.1.1] — 2026-11-25

Released 2026-11-25 at 11:37 (Bahrain): **[Lykos v0.1.1](https://github.com/Vullki/lykos/releases/tag/v0.1.1)**, with `Lykos-v0.1.1-unsigned.ipa` and `Lykos-v0.1.1.tipa` (1,254,906 bytes each) and `altstore-source.json`, which now lists 0.1.1 and keeps 0.1.0. Checked after publishing: the `latest/download` AltStore source names 0.1.1, and its IPA matches the SHA-256 in the source.

Two fixes found the morning after the first release. Build 15 (signed) was installed over build 6 on the iPhone 17 at 11:34 (Bahrain), still signed in, and both fixes were confirmed there.

### Builds

| Build | Run | Commit | What it was |
| --- | --- | --- | --- |
| 14 | 45572756752 | [`78173d2`](https://github.com/Vullki/lykos/commit/78173d2) | Launch-picture fix. Unsigned and signed green. Not installed |
| public 3 | [45572751620](https://github.com/Vullki/lykos/actions/runs/45572751620) | [`78173d2`](https://github.com/Vullki/lykos/commit/78173d2) | Same commit in the public repo. Unsigned green |
| 15 | 45576559615 | [`c4796d2`](https://github.com/Vullki/lykos/commit/c4796d2) | Code-tab mic fix. Unsigned and signed green, no warnings. Installed on the iPhone 17: both fixes confirmed |
| public 4 | [45576554171](https://github.com/Vullki/lykos/actions/runs/45576554171) | [`c4796d2`](https://github.com/Vullki/lykos/commit/c4796d2) | Same commit in the public repo. Unsigned green |
| 16 | 45577766421 | [`b133f2d`](https://github.com/Vullki/lykos/commit/b133f2d) | Version 0.1.1 on `main`. Unsigned and signed green |
| public 5 | [45577762426](https://github.com/Vullki/lykos/actions/runs/45577762426) | [`b133f2d`](https://github.com/Vullki/lykos/commit/b133f2d) | Version 0.1.1 on `main`. Unsigned green |
| public 6 | [45577780592](https://github.com/Vullki/lykos/actions/runs/45577780592) | [`b133f2d`](https://github.com/Vullki/lykos/commit/b133f2d) | Tag `v0.1.1`: built the unsigned IPA and published the Release |
| 17 | 45577785193 | [`b133f2d`](https://github.com/Vullki/lykos/commit/b133f2d) | Tag `v0.1.1` on the private twin: signed green, release job skipped as intended |

### Fixed

- **The old "Ly" flashed on launch.** Opening the app played the old "Ly" for about two seconds, then faded to the new "LY". The old one was iOS's cached picture of the launch screen (`Library/SplashBoard`), kept from before the build 6 icon change; the app itself only carried the new mark. Lykos now deletes that cache once per new build, so iOS redraws it from the current build. The first launch after installing a new build can still show whatever iOS had cached; every launch after that shows only the new "LY". The debug log notes when it happened. Confirmed on the iPhone: opens straight to the new "LY".
- **No Claude mic in the Code tab with the phone upright.** Claude's own mic ("Press and hold to record") only appeared in landscape. Safari does the same: claude.ai turns Code dictation off on a touch screen narrower than 600 points, through one `matchMedia("(max-width: 599px)")` check (the only use of that query in claude.ai's scripts, checked 2026-11-25). Lykos now answers that one check as "wide" with a small script at page start (`CodeDictation.swift`), so the Code tab shows Claude's own mic upright, with Anthropic's transcription rather than the iOS keyboard's. Every other media query and all CSS stay as they are, so the layout is still the phone layout. If claude.ai renames the query, the script stops matching and the app behaves like Safari again. Confirmed on the iPhone: the mic sits in the Code composer upright, and dictation through it works.

## [0.1.0] — 2026-11-25 — first public release

The first public release, published 2026-11-25 at 03:25 (Bahrain): **[Lykos v0.1.0](https://github.com/Vullki/lykos/releases/tag/v0.1.0)**, from the open-source repo [`Vullki/lykos`](https://github.com/Vullki/lykos). The Release holds `Lykos-v0.1.0-unsigned.ipa` and `Lykos-v0.1.0.tipa` (the same build, 1,252,619 bytes, minimum iOS 15.0) and `altstore-source.json`. Same app as builds 6 to 8, now also for iOS 15 and 16.

Checked after publishing: the AltStore source loads from `releases/latest/download/altstore-source.json`, its download link serves the IPA with a matching SHA-256, and the four screenshots and the icon load from the `v0.1.0` tag. Not yet tried on a device: adding the source in AltStore or SideStore, a TrollStore install, and running on iOS 15 or 16.

### Builds

| Build | Run | Commit | What it was |
| --- | --- | --- | --- |
| 6 | 45490570241 | `9ca6cf5` | New brushed-steel "LY" icon. Signed (Ad Hoc), installed over build 5 on the iPhone 17, still signed in. Current build on the phone |
| 7 | 45513140990 | `f770c23` | Open-source prep, built by hand on branch `chore/open-source`. Unsigned and signed (Ad Hoc) both green, about 25 s each. The bundle ID still comes out as `com.vullki.lykos` through the new `LYKOS_BUNDLE_ID` setting, and the rebuilt export step worked with the "Lykos AdHoc" profile. Not installed on the phone (no app code changed). The release job was skipped as expected: it runs only for a version tag |
| 8 | 45513382049 | `6651bc9` | Open-source prep merged to `main`. Unsigned and signed green |
| 9 | 45515682618 | `4bd6232` | Minimum iOS lowered to 15: the compiler stopped on seven iOS 16-only calls in the debug log screen. Failed, as intended for this check |
| 10 | 45515929585 | `cef33a4` | Debug log screen with iOS 15 fallbacks. Unsigned and signed green, no warnings; the IPA reports `MinimumOSVersion 15.0` and bundle ID `com.vullki.lykos`. Not installed on the phone |
| 11 | 45516237150 | `ae72121` | Release prep (`.tipa`, AltStore source, screenshots) merged to `main`. Unsigned and signed green |
| public 1 | [45517237468](https://github.com/Vullki/lykos/actions/runs/45517237468) | `5872799` | First build of the public repo, from its single clean root commit. Unsigned green; signed skipped (no secrets there, as intended) |
| 12 | 45517398592 | `5872799` | Private twin after the rename, run by hand to prove signing still works. Unsigned and signed green |
| public 2 | [45517771273](https://github.com/Vullki/lykos/actions/runs/45517771273) | `e987670` | Tag `v0.1.0`: built the unsigned IPA and published the Release (IPA, `.tipa`, AltStore source) |
| 13 | 45517774205 | `e987670` | Tag `v0.1.0` on the private twin: signed IPA green, release job skipped, so there is only one Release |

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

- **Twin repos (2026-11-25).** The development repo became the private `Vullki/lykos-private`: it keeps the four signing secrets and the full pre-public history on branch `archive/pre-public`. The public `Vullki/lykos` starts from one clean commit (`5872799`) with the same 66 files, checked for personal details first. Both share the same `main`, and one `git push` updates both. The public repo never holds secrets, because anyone can download its workflow artifacts and a signed IPA carries the owner's profile.
- The launch-screen screenshot added to the README and the AltStore source (`e987670`).
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
