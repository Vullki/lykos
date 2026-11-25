# Lykos — Project Idea

Nov 24, 2026 · DARK (Vullki)

## Overview

A personal native iPhone app that wraps claude.ai in its own brushed-silver shell, built in the cloud and sideloaded with the owner's Apple developer certificate. It gives the full claude.ai experience (account, plan, projects, memory, artifacts, connectors) without depending on the App Store or the official app's release cycle. On top of that it adds native iOS features the website alone can't offer: a share extension, Siri and Shortcuts, a widget and a Face ID lock.

Name: **Lykos (ΛΥΚΟΣ), Greek for wolf**. It started as a personal app for one iPhone. It's now open source as an unofficial iOS app for Claude AI: anyone can build it and sign their own copy with their own Apple ID. All credit for Claude goes to Anthropic; Lykos isn't affiliated with or endorsed by Anthropic.

## Why build it

The official Claude iOS app (1.261119.19) crashed about 0.4 seconds after every launch on an iPhone 17 running iOS 27.2 beta (build 24B5089g). The crash log showed a null pointer call in the app's bundled Datadog monitoring code during startup. It was a bug inside the app, likely triggered by the beta iOS.

After the app was deleted, it couldn't be reinstalled because the App Store blocks all downloads while the Apple Account has an unpaid balance. That combination exposed three dependencies worth removing:

- **The official app's release cycle:** a broken build stays broken until Anthropic ships a fix.
- **The App Store:** any account or billing issue blocks reinstalling.
- **Startup code he doesn't control:** analytics and monitoring libraries run before the first screen appears.

A personal wrapper loads claude.ai directly, carries none of that startup code, and installs without the App Store.

## Vision and goals

The goal is a Claude app on his own terms: always installable, styled in his own Brushed Silver Noir look, and better at being part of iOS than the website.

1. **Always available:** rebuild and reinstall at any time from his own repo, with no App Store involved.
2. **Feels native:** full screen, no browser chrome, one-time login, haptics and swipe-back, so it doesn't feel like a website.
3. **Native extras:** send content from any app into Claude, start a chat from Siri, a widget or a Shortcut, and lock the app with Face ID.
4. **His identity:** its own Lykos icon and mark, and a black launch screen, all in his Brushed Silver Noir design system (black, brushed silver and off-white, no color).
5. **No Mac needed:** the whole project is written on Windows, built on GitHub Actions macOS runners and signed with his certificate.

## Core experience

The base of the app is a SwiftUI shell with a single full-screen WKWebView that loads claude.ai.

| Feature | What it does |
| --- | --- |
| Full-screen web view | Loads claude.ai edge to edge, with no address bar or browser controls |
| Persistent login | Stores the session in the app's own website data store, so you sign in once and stay signed in |
| Email login | Uses claude.ai's "Continue with email" code login. Already tested: it opens his existing Google-created account |
| Microphone and camera | Voice input and photo capture work inside the web view after iOS asks for permission |
| File and photo uploads | The web page's attach button opens the native iOS file and photo pickers |
| External links | Any link that leaves claude.ai opens in Safari, so the app only ever shows claude.ai |
| Launch screen | Black background with the Lykos mark, shown while the page loads |
| Feel | Haptics, swipe back and forward, pull to refresh, safe-area aware layout |
| Offline screen | A clean branded screen with a retry button when there's no connection, instead of a browser error page |
| Connectors | Connectors belong to the account, so they're connected once on claude.ai desktop and then work in the app. Their OAuth popups (Gmail, Drive and others) would open in Safari, and Google blocks embedded web views, so they aren't connected from inside the app |

## Native extras

These are what make the app more than a website in a frame. They're ordered from most to least useful, and each one ships on its own.

| Extra | What it does | Difficulty |
| --- | --- | --- |
| Share extension | Select text, a link or an image in any app → Share → the app opens a new chat with that content ready to paste or attach | Medium: claude.ai's page can't be filled in directly, so content goes through the clipboard or a prefilled new-chat link |
| Siri and Shortcuts | "Open Lykos" App Intent opens a new chat, and can be used as a step in his iOS Shortcuts | Low to medium |
| Home and Lock Screen widget | One tap to a new chat. Optional: one tap straight into voice, which needs a small script click because claude.ai has no voice URL, so it's the part most likely to break when the site changes | Low (voice: medium) |
| Action Button and Control Center | The "New chat" App Intent can be bound to the iPhone 17 Action Button with no extra code, and a Control Center control (iOS 18 `ControlWidget`) reuses it | Low |
| Face ID lock | Asks for Face ID when the app opens or returns from the background, and covers the screen when the app leaves the foreground so chats don't show in the app switcher | Low |
| Custom URL scheme | Links like `lykos://new` open a new chat from Shortcuts, widgets or other apps | Low, and the other extras use it |

## Principles and constraints

- **Each person's own copy:** the source and an unsigned IPA are public, but nobody distributes a signed app. Each person signs their own copy and signs in to their own claude.ai account.
- **Unofficial, with credit:** the README credits Anthropic for Claude and says Lykos is independent and unofficial. No Anthropic logos, icons or artwork; the app's name, icon and launch screen are Lykos / Vullki.
- **Web wrapper first:** everything comes from claude.ai itself, so no API key and no per-message cost. A native API client is a possible later idea, not part of this project.
- **Login by email code:** the web view doesn't attempt Google sign-in, because Google blocks it in embedded web views and the email code login already works.
- **No Mac:** code is written on Windows 11 in Claude Code, the Xcode project is generated from `project.yml` by XcodeGen, and builds run on GitHub Actions macOS runners.
- **Secrets never in the repo:** the signing certificate (.p12), its password and the provisioning profiles live only in GitHub encrypted secrets or on his own machine.
- **Change the page as little as possible:** the app doesn't inject scripts into claude.ai unless a feature truly needs it, so changes to Anthropic's site are less likely to break it.

## Design

Lykos uses DARK's **Brushed Silver Noir** design system (system version 1.1.0, kept outside this repo). claude.ai fills almost the whole screen, so the system applies to what Lykos draws itself: the icon, the launch, lock and offline screens, and the widget.

- **Background:** always `#000`. Surfaces step up only to `#0D0D0D`.
- **Metal:** the four locked silver stops `#DCDCDC` → `#C2C2C2` → `#808080` → `#464646` as a vertical gradient, with fine horizontal brushed grain and bright bevel edges, as in the #DARK_MUSIC artwork.
- **Text:** body in `#E6E4DF`; labels in flat `#C2C2C2`, uppercase, tracking about 0.3em. Small text uses the system font (SF Pro). The ΛΥΚΟΣ wordmark ships as an image asset, not a bundled font.
- **No color:** silver, off-white and black only. No crimson wolf eye anywhere, including the icon.
- **Icon:** **LY in brushed steel**, designed by DARK and made final on 2026-11-25. A bold italic L and Y in real brushed-steel grain with lit bevels; the L's top sweeps up and becomes the Y's left arm in one motion, like a wing or a wolf's ear, with no literal wolf. It sits on a dark grained background with a soft shadow. The heavy shapes keep it readable at Settings size. The same letters, cut out, appear on the launch and offline screens (and later the lock screen and widget). Final files are in `design/icon/final/` (source: `lykos-source.webp`). Earlier icons are kept for reference: the first satin-silver "Ly" (2026-11-24) in `design/icon/archive-ly-v1/`, the Λ Monolith set in `design/icon/archive-lambda/`, plus Wolf Bubble, Faceted Wolf and Ly Wrap in `design/icon/`.
- **Motion:** every Lykos screen fades in rather than appearing, and Reduce Motion is respected.

## Out of scope

- Publishing to the App Store or TestFlight, or distributing a signed build (the source and an unsigned IPA are public; each person signs their own)
- A native chat interface built on the Anthropic API
- Rebuilding claude.ai features natively (chat list, projects, artifacts)
- Google sign-in inside the app
- Android, iPad-specific layouts and macOS
- Any use of an official Claude IPA or a modified copy of it

## Success criteria

The project is done when all of these are true on his iPhone:

- [ ] The app installs by sideloading, with no App Store involved
- [ ] It opens claude.ai full screen in under 3 seconds on a normal connection, with the Lykos launch screen
- [ ] He signs in once by email code and is still signed in after closing the app and restarting the phone
- [ ] Voice input, photo uploads and file attachments work as they do in Safari
- [ ] Links outside claude.ai open in Safari
- [ ] It runs on iOS 27.2 beta without the startup crash the official app had
- [ ] A push to GitHub produces a new installable IPA with no Mac involved
- [ ] Share extension, Siri/Shortcuts, widget, Action Button and Face ID lock each work
- [ ] Connectors set up on desktop work inside the app

## Name and identifiers

| Item | Choice |
| --- | --- |
| App name | **Lykos**, from Greek λύκος (wolf). Logo lettering: ΛΥΚΟΣ. Shown under the icon and used in Siri phrases |
| Bundle ID | `com.vullki.lykos` (decided 2026-11-24). Never change it after the first install, since the app's login data is tied to it. Extensions: `com.vullki.lykos.share` and `com.vullki.lykos.widget` |
| App Group | `group.com.vullki.lykos`, shared by the app, share extension and widget |
| Repository | `Vullki/lykos` on GitHub |
| URL scheme | `lykos://`, with `lykos://new` opening a new chat |
| App icon | **LY in brushed steel** (DARK's design): bold italic L and Y, the L's top sweeping into the Y, on a dark grained background. 1024 × 1024 PNGs in `design/icon/final/`: `lykos-any.png` (opaque, his artwork as is), `lykos-dark.png` and `lykos-tinted.png` (letters cut out on transparency), plus `lykos-mark.png` for the screens and widget. The raster source `lykos-source.webp` sits beside them. Icon Composer (`.icon`) is macOS only, so it isn't used; iOS still applies its glass look to asset-catalog icons |
| Siri phrases | "Open Lykos" and "New chat in Lykos". Test early, since Siri may hear "Lycos" |
| Signing route | Signed in GitHub Actions from encrypted secrets (Route A), with the unsigned IPA (Route B) for anyone signing their own copy. See the Project Plan |
