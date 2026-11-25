# Lykos — Project Plan

Nov 24, 2026 · DARK (Vullki)

## Summary

The app is built in five phases. Phase 0 gathers the Apple and GitHub prerequisites, Phase 1 builds the WKWebView shell, Phase 2 sets up the cloud build and signing, Phase 3 adds the native extras, and Phase 4 adds branding and polish. Phases 1 and 2 together produce the first installable app, which is the first milestone.

**How to use this plan with Claude Code:** run one Claude Code session per phase. Paste the phase's starter prompt from the last section, and give Claude Code both this plan and the Project Idea doc as context. Each phase ends with its own checklist, so check it on the phone before starting the next phase.

Everything is written on Windows 11. No Mac is needed at any step.

## Tech stack and tooling

| Area | Choice | Why |
| --- | --- | --- |
| Language and UI | Swift + SwiftUI | Native, small, current Apple standard |
| Web engine | WKWebView (WebKit) | The only web engine allowed on iOS; supports mic, camera and file pickers |
| Project file | XcodeGen (`project.yml`) | Defines the Xcode project as a small readable file, so nothing Xcode-specific is edited by hand on Windows |
| Minimum iOS | iOS 15 (was 17 until v0.1.0) | Lets TrollStore devices (iOS 15.0 to 16.6.1, 16.7 RC, 17.0) run it too; his phone runs iOS 27.2 beta |
| Extras | Share Extension, App Intents, WidgetKit, LocalAuthentication | Apple's own frameworks for each extra |
| Data sharing between app and extensions | App Group | Lets the share extension and widget pass data to the main app |
| Source control | GitHub repo | Secrets stay in GitHub encrypted secrets, never in the code |
| Build | GitHub Actions, macOS runner, `xcodebuild` | Builds the IPA in the cloud without a Mac |
| Signing | His Apple developer certificate, in CI or with zsign | See Phase 2 for the two routes |
| Install | His usual sideloading method | No App Store; Developer Mode is already on |
| Dev environment | Windows 11 + Claude Code | Where all code is written |

## Repository structure

The app is **Lykos** (ΛΥΚΟΣ), bundle ID `com.vullki.lykos`, App Group `group.com.vullki.lykos`, repo `Vullki/lykos`.

```
Lykos/
├── project.yml                 # XcodeGen: targets, bundle IDs, capabilities, Info.plist keys
├── ExportOptions.plist         # Route A export settings (method: debugging)
├── CLAUDE.md                   # Rules for Claude Code (see last section)
├── README.md
├── .gitignore                  # ignores *.p12, *.mobileprovision, build/, *.ipa
├── App/
│   ├── LykosApp.swift          # @main, scene, deep-link handling
│   ├── Lykos.entitlements      # App Group (added in Phase 3)
│   ├── WebView/
│   │   ├── ClaudeWebView.swift     # UIViewRepresentable around WKWebView
│   │   ├── WebCoordinator.swift    # navigation, UI and media-permission delegates
│   │   ├── AllowedHosts.swift      # which hosts stay in-app vs open in Safari
│   │   └── DebugLog.swift          # collects console.log and load errors for the debug screen
│   ├── Screens/
│   │   ├── LaunchView.swift        # fades from the launch screen into the page
│   │   ├── OfflineView.swift
│   │   ├── LockView.swift          # Face ID gate
│   │   └── DebugLogView.swift      # hidden log screen, shareable as text
│   ├── Intents/                # App Intents for Siri, Shortcuts, Action Button, Control Center
│   └── Resources/
│       ├── Assets.xcassets         # AppIcon (Any/Dark/Tinted), wolf mark, colors
│       └── Settings.bundle         # Face ID on/off toggle in the iOS Settings app
├── ShareExtension/
│   ├── ShareExtension.entitlements
│   └── ShareViewController.swift
├── Widget/
│   ├── Widget.entitlements
│   └── NewChatWidget.swift
├── Shared/
│   └── AppGroup.swift          # App Group ID, shared storage helpers
├── scripts/
│   └── package-ipa.sh          # .app → Payload/ → .ipa
└── .github/workflows/
    └── build.yml               # macOS runner: XcodeGen → xcodebuild → IPA artifact
```

## Phase 0: Prerequisites

You do this part by hand in the Apple Developer portal and GitHub. Claude Code can't do it for you. Phase 1 only needs the main app ID. The extension IDs can wait until Phase 3.

**Apple Developer portal**

- [x] Decide the bundle ID once: `com.vullki.lykos` (decided 2026-11-24). It can't change after the first install without losing the login data
- [ ] Register the iPhone's device ID (UDID). The Apple Devices app on Windows or your sideloading tool can show it
- [ ] Create the main App ID (the bundle ID above) with the App Groups capability, and create the App Group (`group.` + the bundle ID)
- [ ] Export your signing certificate as a `.p12` that includes its private key, protected by a password
- [ ] Create a provisioning profile for the main App ID that includes the iPhone and the certificate
- [ ] Phase 3: also create App IDs for the share extension (`.share`) and the widget (`.widget`), each with the same App Group, plus a provisioning profile for each

**GitHub**

- [x] Create the repo (`Vullki/lykos`; private while it was being built)
- [ ] Add encrypted secrets: `CERT_P12_BASE64`, `CERT_PASSWORD`, `KEYCHAIN_PASSWORD`, `PROFILE_APP_BASE64` (and later `PROFILE_SHARE_BASE64`, `PROFILE_WIDGET_BASE64`)
- [ ] Check your plan's GitHub Actions minutes for private repos. macOS minutes count about 10× on private repos (check the current rate), so the free 2,000 minutes come to roughly 200 macOS minutes. Measured on 2026-11-24: the unsigned build takes about 27 seconds on `macos-26` (billed as 1 macOS minute), so that's on the order of 150+ builds a month, far more than this project needs. Keep builds to pushes on `main` and manual runs. Once the repo is public, standard GitHub-hosted runners, macOS included, cost no minutes

Never commit the `.p12`, its password or any `.mobileprovision` file. `.gitignore` blocks them from day one.

## Phase 1: The WKWebView shell

This phase delivers a working app that opens claude.ai full screen and keeps you signed in.

| Task | Implementation notes |
| --- | --- |
| Project setup | `project.yml` with one app target, bundle ID, iOS 17 minimum, iPhone only, portrait + landscape |
| Info.plist permissions | `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, each with a short honest reason |
| Web view | `WKWebsiteDataStore.default()` (persistent, so you stay signed in), inline media playback on, back/forward swipe gestures on |
| Mic and camera | `WKUIDelegate` media-capture permission handler that grants access only for claude.ai and denies every other origin |
| Allowed hosts | Main-frame navigation stays in-app only for `claude.ai` and its subdomains. Anything else opens in Safari (`UIApplication.open`) |
| New windows | Links with `target=_blank` go through the same host rule instead of disappearing |
| File uploads | The web page's file input opens the native picker. Verify photos, camera and Files all work |
| Downloads | `WKDownload` for files that artifacts or chats produce, then the iOS share sheet so they can be saved |
| Crash recovery | Reload automatically if WebKit's content process is killed (`webViewWebContentProcessDidTerminate`) |
| Offline | `NWPathMonitor` + failed-load handling show `OfflineView` with a Retry button |
| Pull to refresh | `UIRefreshControl` on the web view's scroll view |
| Launch screen | `UILaunchScreen` Info.plist dictionary (`UIColorName` black, `UIImageName` `LykosMark`, from `design/icon/final/lykos-mark.png`), so there's no storyboard XML to hand-write on Windows. `LaunchView` then fades into the page once it has loaded |
| No white flash | Web view and its scroll view get a black background (`isOpaque = false`), so nothing white shows between the launch screen and the page |
| User agent | Test early whether claude.ai treats the web view as an unknown browser ("get the app" banners, odd layout). If it does, set `applicationNameForUserAgent` so it reads like Mobile Safari |
| Debug log | Windows has no Safari Web Inspector or Xcode console. A script message handler forwards `console.log`, `console.error` and failed loads to `DebugLog`, shown on a hidden screen (for example a long press on the offline screen) and shareable as text. For device logs, use `idevicesyslog` from libimobiledevice on Windows |
| URL scheme | Register `lykos://` now and handle `lykos://new` → open `https://claude.ai/new`. Phase 3 uses it |

**Login tip:** sign in with "Continue with email" and **type the code** into the app. Don't tap the link in the email, because it opens in Safari and the session would land there instead of in the app.

**Connectors tip:** connect Gmail, Drive and other connectors once on claude.ai desktop. They belong to the account, so they then work in the app. Don't connect them from inside the app: their OAuth popups open in Safari and the callback would land there.

**Phase 1 checklist**

- [ ] App opens claude.ai full screen with the Lykos launch screen
- [ ] Email code login works and survives closing the app and restarting the phone
- [ ] Voice input asks for mic permission once, then works
- [ ] Photo, camera and file attachments work
- [ ] Outside links open in Safari
- [ ] Airplane mode shows the offline screen; Retry recovers
- [ ] No white flash between the launch screen and the page
- [ ] The debug log screen shows console messages and can be shared

## Phase 2: Cloud build and signing

Every push to `main` builds the app on a GitHub macOS runner and gives you an IPA to install. There are two ways to sign it. Start with Route B to get the first build onto the phone fast, then switch to Route A before Phase 3.

**Workflow steps (`.github/workflows/build.yml`)**

1. Trigger on push to `main` and on manual run (`workflow_dispatch`)
2. Choose a macOS runner and select an Xcode version whose iOS SDK supports your target
3. `brew install xcodegen`, then `xcodegen generate`
4. Set the build number from `github.run_number`, so each build installs over the previous one
5. Build and sign (route below)
6. Upload the IPA as a workflow artifact with short retention (for example 7 days)

|  | Route A: sign in CI | Route B: unsigned build + zsign |
| --- | --- | --- |
| How it works | Imports the `.p12` into a temporary keychain and installs the profiles. Runs `xcodebuild archive` with manual signing, then `-exportArchive` with an `ExportOptions.plist`. Since Xcode 15.3 the export method names are `debugging` (was `development`) and `release-testing` (was `ad-hoc`); the old names still work with a warning. Deletes the keychain at the end | Builds with `CODE_SIGNING_ALLOWED=NO` and packages `Payload/Lykos.app` into an IPA. You download it and sign it on Windows with `zsign -k cert.p12 -p <password> -m profile.mobileprovision -o signed.ipa unsigned.ipa` |
| Output | A signed IPA, ready to install | An unsigned IPA you sign locally |
| Secrets in GitHub | Certificate, password, profiles | None |
| Extensions and App Groups | Handled per target by Xcode | Each extension needs its own profile and entitlements, which is fiddly |
| Best for | Phase 3 onward | The first builds while the app is a single target |

**Install as signed:** install the signed IPA exactly as it is. If the sideloading tool re-signs it with its own identity, it can drop the App Group entitlement or change the bundle ID, which loses the login data and breaks the share extension and widget handoff. Use a tool or setting that installs without re-signing (for example `ideviceinstaller` from libimobiledevice).

**As built (session 2, 2026-11-24):** runner `macos-26`, Xcode pinned to 26.6 (`/Applications/Xcode_26.6.app`, iOS 26.5 SDK; Xcode 27 is still a preview on the runners). XcodeGen comes from Homebrew. Pushes that only touch `**/*.md` or `design/**` don't build, and a newer push cancels an older run. A small Linux job checks for the four signing secrets first, so without them the signed job shows as skipped and costs no macOS minutes. The signed job reads the team ID and profile name from the decoded profile; `ExportOptions.plist` holds no account details. First green run: 45356951604, the unsigned job took 27 s. First signed run: 45359119668 (2026-11-24), Ad Hoc profile "Lykos AdHoc" (expires 2027-04-08), export method `release-testing` picked from the profile, signed with the owner's Apple Distribution certificate.

**Phase 2 checklist**

- [x] A push to `main` produces an IPA artifact (unsigned and signed, 2026-11-24)
- [x] The IPA installs on the iPhone through your sideloading method (iPhone 17, iOS 27.2 beta, 2026-11-24)
- [x] A second build installs over the first one and keeps you signed in (build 4 over build 3, 2026-11-24)
- [x] The installed app keeps the bundle ID and entitlements it was signed with (login data carried over, so the bundle ID held)
- [x] No certificate, password or profile appears in the repo or the build logs (checked on the first signed run, 2026-11-24)

## Phase 3: Native extras

Build these one at a time, in this order, and install and test each before starting the next. They all rely on the `lykos://` URL scheme from Phase 1 and on the App Group from Phase 0.

1. **Face ID lock** (easiest)
   - `LocalAuthentication` with `.deviceOwnerAuthentication`, so the passcode works as a fallback
   - Locks on launch and after the app has been in the background for more than a set time (for example 60 seconds)
   - On/off toggle in a `Settings.bundle`, so it appears in the iOS Settings app with no extra screen in the app
   - Needs the Info.plist key `NSFaceIDUsageDescription`
   - Privacy cover: when `scenePhase` becomes `.inactive`, cover the screen with the lock view, so the screenshot iOS takes for the app switcher never shows a chat
2. **Widget**
   - WidgetKit widget in small Home Screen and circular Lock Screen sizes
   - Tapping it opens `lykos://new` → a new chat
   - Optional "straight into voice": claude.ai has no voice URL, so this needs a small script click on the page. It goes against the minimal-JS rule and is the part most likely to break when the site changes, so build it last, if at all
3. **Siri, Shortcuts, Action Button and Control Center**
   - App Intent "New chat" that opens the app on a new chat, with Siri phrases set up in an `AppShortcutsProvider`
   - The same intent can be bound to the iPhone 17 Action Button with no extra code, and a Control Center control (iOS 18 `ControlWidget`) reuses it
   - Optional second intent "Ask with text" that takes text from a Shortcut and sends it to a new chat (same delivery method as the share extension)
4. **Share extension** (hardest)
   - Accepts text, links and images from the iOS share sheet
   - Saves what it receives to the App Group; the main app picks it up when it next opens
   - Delivery into claude.ai: first test whether claude.ai supports a prefilled new-chat link (for example `claude.ai/new?q=hello`). Test it in Safari on the phone before this session starts; it takes ten seconds. If it does, use it for text. If not, or for images, the app copies the content to the clipboard and opens a new chat, ready to paste
   - Extensions can't reliably open their host app, so show a clear "Saved, open the app" confirmation

**Phase 3 checklist**

- [ ] Face ID appears on launch and after returning from the background; the toggle in iOS Settings turns it off
- [ ] The app switcher shows the lock cover, never a chat
- [ ] The widget opens a new chat from both the Home Screen and the Lock Screen
- [ ] "Hey Siri, open Lykos" opens a new chat; the intent appears in the Shortcuts app
- [ ] The Action Button and the Control Center control each open a new chat
- [ ] Text, a link and an image shared from Safari or Photos each reach a new chat

## Phase 4: Branding and polish

This phase is about how the app looks and feels, in DARK's **Brushed Silver Noir** design system (kept outside this repo). The full design rules are in the Project Idea's Design section: `#000` background, the four silver stops with horizontal brushed grain and bevel edges, `#E6E4DF` text, no color and no wolf eye.

- **App icon:** **LY in brushed steel**, DARK's design (final 2026-11-25; it replaced the first satin-silver "Ly", now in `design/icon/archive-ly-v1/`). Exported in `design/icon/final/` and wired into `AppIcon.appiconset`: `lykos-any.png` (Any, his 1024 artwork as is, opaque RGB; iOS applies the rounded mask itself, so it stays a full square), `lykos-dark.png` (Dark, the letters cut out onto transparency so iOS supplies the dark background) and `lykos-tinted.png` (Tinted, the letters in a bright grayscale on transparency, since iOS colors it by brightness). `lykos-mark.png` (cut-out letters, centred on a square) goes into the catalog as the `LykosMark` image (480 px @3x) for the launch, lock and offline screens and the widget. The source is a raster (`lykos-source.webp`, 1024 × 1024); to re-export, run `design/icon/tools/cut.py` (luminance mask of the letters) then `export.py` in a folder holding the source as `src.webp`. Icon Composer (`.icon` files) is macOS only, so it isn't used; iOS still applies its glass look to asset-catalog icons. Check it at Home Screen size (60 pt) and in Spotlight and Settings (29–40 pt), not just at 1024
- **Launch screen:** black background with the Lykos mark centered, then a short fade into claude.ai
- **Lock screen:** the mark on `#000`. On a successful Face ID unlock the mark gets a short silver highlight sweep with a light haptic, then fades into the chat. Reduce Motion turns the sweep into a plain fade
- **Offline screen:** the mark in `#464646`, one line of text in `#E6E4DF`, and a Retry pill with a thin silver outline
- **Widget:** the mark on `#000`, with the Tinted version used on the Lock Screen
- **claude.ai appearance:** set claude.ai to Dark, so the hand-off from the black launch screen into the page stays dark
- **Status bar and safe areas:** check with the Dynamic Island in portrait and in landscape, with claude.ai in both light and dark mode
- **Haptics:** a light tap on pull to refresh and when Face ID unlocks
- **Display name:** Lykos under the icon (logo lettering ΛΥΚΟΣ, exported as an image asset in the brushed-silver treatment), plus Siri phrases like "Open Lykos"
- **README:** how to build, sign and install, so the process is easy to repeat when the certificate and profiles expire and need renewing

## Testing and acceptance checklist

Run this full pass on the iPhone after every phase, plus once on the final build. Each phase also has its own checklist above.

| Area | Test | Pass when |
| --- | --- | --- |
| Install | Install over a previous build | Installs, and you're still signed in |
| Login | Close the app, restart the phone, reopen | Still signed in, no login screen |
| Chat | Send a message, switch models, open a project | Works as in Safari |
| Voice | Use voice input | Mic permission asked once, then works |
| Attachments | Attach a photo, take one with the camera, attach a PDF from Files | All three upload |
| Downloads | Download a file Claude made | Share sheet opens and the file saves |
| Links | Tap a link to an outside site | Opens in Safari |
| Connectors | Use a connector set up on desktop (for example Gmail or Drive) | Works as in Safari |
| App switcher | Swipe up to the app switcher with Face ID on | The lock cover shows, not a chat |
| Background | Leave the app for 10 minutes, come back | Page still there, or reloads cleanly |
| Offline | Turn on airplane mode, open the app | Offline screen; Retry recovers |
| Beta iOS | Cold launch 10 times on iOS 27.2 beta | No crash |
| Extras | Widget, Siri, share extension, Face ID | Each Phase 3 check passes |
| Secrets | Search the repo and build logs | No certificate, password or profile anywhere |

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| claude.ai changes its site | A feature that depends on the page (prefilled links, uploads) stops working | Keep page scripting to a minimum; the core app only loads the site, so it keeps working |
| Email login link opens in Safari | Session lands in Safari, not the app | Always type the code into the app (Phase 1 tip) |
| Certificate or profile expires | App stops launching | Note both expiry dates; renew, update the GitHub secrets, rebuild |
| Signing secrets leak | Someone could sign apps as you | Encrypted secrets only (never passed to pull requests from forks), temporary keychain deleted after each build, `.gitignore` blocks the files |
| GitHub Actions minutes run out | Builds stop until next month | Build only on pushes to `main` and manual runs; keep the unsigned Route B as a fallback |
| Runner's Xcode can't build for your iOS | Build fails or misses new APIs | Pin a known-good Xcode in the workflow; update deliberately |
| WebKit behaves differently on the beta | Odd bugs in mic, uploads or layout | Test each phase on the beta first; report real WebKit bugs to Apple |
| Share extension can't hand content over directly | One extra paste step | Clipboard fallback, with a clear message |
| Connector OAuth opens in Safari | Connecting a connector from the app fails | Connect connectors once on claude.ai desktop; they belong to the account and then work in the app |
| No Web Inspector or Xcode console on Windows | Bugs on the beta are hard to see | In-app debug log screen, plus `idevicesyslog` for device logs and crash logs from iOS Settings |
| Sideloading tool re-signs the IPA | App Group dropped or bundle ID changed; login data lost | Install the signed IPA as is, without re-signing |
| Using claude.ai inside a custom app | Terms-of-service question | Lykos is a browser shell: each person signs in on claude.ai with their own account and uses it as Anthropic serves it, with no API or automated access. No signed builds are distributed, no Anthropic logos are used, and the README credits Anthropic and states that Lykos is unofficial |

## Claude Code sessions and starter prompts

Windows can't compile iOS apps, so the GitHub Actions build is the only way to check the code. Every session ends with a push and a passing build. Run the sessions in this order:

| # | Session | Ends with |
| --- | --- | --- |
| 0 | Repo bootstrap | `CLAUDE.md`, `.gitignore`, `project.yml`, README pushed |
| 1 | WKWebView shell | Phase 1 code pushed |
| 2 | Build pipeline, Route B, then Route A | IPA installed on the phone |
| 3 | Face ID → widget → Siri → share extension, one session each | Each extra installed and tested |
| 4 | Branding and polish | Final build |

**`CLAUDE.md` rules for the repo**

```markdown
# Project rules
- Lykos: open-source, unofficial iOS app for claude.ai. Credit Anthropic in text only; never add Anthropic logos, icons or artwork.
- XcodeGen project.yml is the source of truth. Never commit *.xcodeproj.
- Never create, commit or print certificates, passwords or provisioning profiles.
- We work on Windows: verify every change through the GitHub Actions build.
- Keep JavaScript injection into claude.ai to the minimum a feature needs.
- Main-frame navigation stays in-app only for claude.ai and its subdomains.
- Small, reviewable commits. Explain any new Info.plist key or entitlement.
```

**Starter prompt, session 0**

```text
Read the attached Project Idea and Project Plan. Bootstrap the repo for Phase 0/1:
create CLAUDE.md (rules in the plan), .gitignore (block *.p12, *.mobileprovision,
*.ipa, build/, *.xcodeproj), README, and project.yml for one iOS 17+ iPhone app
target named Lykos with bundle ID com.vullki.lykos. Don't write Swift yet.
Show me project.yml and explain each setting before committing.
```

**Starter prompt, session 1**

```text
Implement Phase 1 of the Project Plan exactly as its table describes: the WKWebView
shell, persistent data store, mic/camera permission handler limited to claude.ai,
allowed-hosts rule, target=_blank handling, file uploads, WKDownload with share
sheet, content-process crash reload, offline view, pull to refresh, UILaunchScreen
launch screen (no storyboard) with a black web view background so there's no white
flash, the debug log screen, and the lykos://new URL scheme. List every Info.plist
key you add and why.
```

**Starter prompt, session 2**

```text
Create .github/workflows/build.yml per Phase 2, Route B first: macOS runner,
XcodeGen, unsigned xcodebuild with CODE_SIGNING_ALLOWED=NO, scripts/package-ipa.sh,
build number from github.run_number, IPA uploaded as an artifact (7-day retention).
Then add Route A as a separate job using the secrets named in Phase 0, with a
temporary keychain that is always deleted. Never echo secrets in logs.
```

For Phases 3 and 4, give Claude Code the matching section of this plan and ask for one extra per session, each with its own checklist.
