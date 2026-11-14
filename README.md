# Sol Browser

An independent iPad browser forked from [Aura Browser](https://github.com/doorhinge-apps/Aura-Browser),
with an Arc/Zen-inspired interface built in **SwiftUI + WebKit**. It includes spaces,
pinned/favorite tabs, a command bar, boosts, and a dashboard. It does not provide
complete Arc or Zen feature parity.

This fork keeps the original architecture and fixes the crashes, dead-ends, and
tab-state bugs that stopped the upstream build from being usable day-to-day, and
adds a CI pipeline that produces a **sideloadable unsigned IPA** (no paid Apple
Developer account required).

> **Not affiliated with Arc or The Browser Company.** This is not an official iPad
> version of Arc and does not sync with Arc.

---

## Attribution & License

- **Original project:** Aura Browser by **DoorHinge Apps** (Reyna Myers and contributors)
  — <https://github.com/doorhinge-apps/Aura-Browser>
- **License:** Mozilla Public License 2.0 (MPL-2.0). The full license text is in
  [`LICENSE`](LICENSE). Per-file copyright notices from upstream are preserved.
- This fork is also distributed under **MPL-2.0**. The changes made in this fork are
  summarized below and recorded in the git history.
- Upstream community: [r/aurabrowser](https://www.reddit.com/r/aurabrowser/) ·
  feedback: `aura@doorhingeapps.com`

If you redistribute this fork, keep the `LICENSE` file and the upstream copyright
headers intact, as MPL-2.0 requires.

---

## What this fork changes

**Unblocked the build & first run**
- Removed the Firebase dependency and the unused `GoogleService-Info.plist` (no
  Firebase code is used anywhere in the app).
- Removed the login/API-key gates from the critical path. The browser launches
  straight into browsing; optional AI features degrade gracefully without a key.
- Stripped entitlements that a free Apple ID cannot sign (push, iCloud, WeatherKit,
  the `web-browser` entitlement, and macOS-only sandbox keys). The entitlements file
  is now empty so the IPA re-signs cleanly with SideStore/AltStore/Sideloadly.
- Added the location usage description (prevents a `CLLocationManager` crash) and
  enabled file sharing so downloads appear in the Files app.

**Fixed crashes & dead-ends**
- "Continue Anyway" on the no-Wi-Fi screen now works, and tab state is no longer lost
  when connectivity flips.
- Network monitor updates on the main thread and starts optimistic.
- Web-view cache eviction no longer evicts the *selected* tab, and honors the
  configured preload limit (default 15) instead of an unset `0`.
- `target="_blank"` links now open instead of doing nothing.
- Downloads no longer overwrite existing files (unique `name 1.ext`, `name 2.ext`…).
- The launch animation overlay no longer blocks all touches forever.
- Weather widget no longer calls `fatalError` when WeatherKit is unavailable.
- Closing a tab no longer crashes on out-of-range indices, leaves a stale page, or
  drifts the selected index — applied consistently across the vertical, paged, and
  horizontal sidebars.
- Dynamic `ForEach(0..<count)` ranges replaced with safe `.indices` iteration so
  deleting a Space or tab doesn't crash SwiftUI.
- Space indices are clamped and re-selected after deletion; new Spaces get a unique
  index instead of colliding.

**Arc-fidelity & quality-of-life**
- URL/search formatting fixed: proper query percent-encoding, `aura://` internal URLs
  preserved, scheme-less hosts and search terms routed correctly.
- Command-bar suggestions no longer lag one keystroke behind (stale responses are
  discarded) and arrow keys no longer crash on an empty list.
- Browsing history is now actually recorded during navigation (deduped, gated by the
  history setting, on by default).
- Space gradient `endHex` bug fixed (was reading `startHex`).

**Build & delivery**
- Added [`.github/workflows/build-ipa.yml`](.github/workflows/build-ipa.yml): a macOS
  CI job that resolves Swift packages, compile-checks for the iOS Simulator, builds an
  unsigned device app, and uploads `Sol-Browser-unsigned.ipa` as an artifact.

---

## Requirements

- **To build:** a Mac with **Xcode 16 or newer** (iOS 18 SDK), **or** a GitHub account
  to run the included CI workflow (no Mac needed).
- **To run:** an iPad on **iPadOS 17 or later**.
- **To sideload:** a free Apple ID and one of SideStore, AltStore, or Sideloadly.

---

## Build from source

### Option A — Xcode on a Mac

1. Clone this fork and open `Aura.xcodeproj` in Xcode.
2. Let Xcode resolve the Swift package dependencies (File ▸ Packages ▸ Resolve Package
   Versions). The pinned versions are in
   `Aura.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
3. Select the **Aura** scheme and an iPad simulator (or your connected iPad).
4. **For a simulator:** just Build & Run (⌘R). No signing needed.
5. **For a real device with a free Apple ID:** in Signing & Capabilities, choose your
   Personal Team, change the Bundle Identifier to something unique (e.g.
   `com.yourname.aura`), then Build & Run. Xcode will sign and install it. The app
   expires after 7 days and must be re-run from Xcode to refresh.

### Option B — GitHub Actions (no Mac required)

The workflow in `.github/workflows/build-ipa.yml` runs on a GitHub-hosted macOS
runner and produces an unsigned IPA.

1. Push this fork to your own GitHub repository (see *Publishing your fork* below).
2. Go to the **Actions** tab. The **Build iPad IPA** workflow runs automatically on
   pushes to `main` and on pull requests. You can also run it manually:
   **Actions ▸ Build iPad IPA ▸ Run workflow**.
3. Wait for the run to finish (the first run resolves and compiles all packages, so it
   can take 10–25 minutes).
4. Open the completed run and download the **`Sol-Browser-unsigned-ipa`** artifact. It
   contains `Sol-Browser-unsigned.ipa`.

The IPA is **unsigned** — you re-sign it with your own Apple ID using a sideloading
tool below. The simulator compile step is the build gate: if the Swift code doesn't
compile, the run fails before producing an artifact.

#### Publishing your fork

This workspace's git remote points at upstream (`upstream`). To get your own copy on
GitHub:

1. Create a new empty repository on GitHub (e.g. `aura-ipad-fork`). Do **not**
   initialize it with a README.
2. In this project folder, add your remote and push:
   ```bash
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
3. The Actions workflow will trigger on the push.

---

## Install on iPad (sideloading)

An unsigned IPA must be re-signed with your Apple ID before iPadOS will run it. A
**free Apple ID** works, with these limits:

- Each sideloaded app **expires after 7 days** and must be refreshed (re-signed).
- A free account can have at most **3 sideloaded apps** installed at once.
- No push notifications / iCloud sync (this fork removed those entitlements anyway).

A paid Apple Developer account ($99/yr) removes the 7-day expiry (apps last 1 year)
and the 3-app limit.

Pick **one** of the tools below.

### AltStore (Mac or Windows PC)

1. Install **AltServer** on your computer: <https://altstore.io> (follow the setup
   guide for your OS; on Windows it requires iCloud + iTunes from Apple's website,
   not the Microsoft Store versions).
2. Connect your iPad by USB (or enable Wi-Fi sync in AltServer).
3. Click the AltServer icon ▸ **Install AltStore** ▸ select your iPad. Enter your
   Apple ID when prompted (it's sent only to Apple's signing servers).
4. On the iPad: **Settings ▸ General ▸ VPN & Device Management** ▸ trust your Apple ID
   developer profile.
5. Open **AltStore** ▸ **My Apps** ▸ tap **+** ▸ select `Sol-Browser-unsigned.ipa`. AltStore
   signs and installs it.
6. Keep AltServer running on your computer (or on the same Wi-Fi) so AltStore can
   auto-refresh the app before the 7-day expiry.

### Sideloadly (Mac or Windows PC — simplest one-off install)

1. Download **Sideloadly**: <https://sideloadly.io> and install it.
2. Connect your iPad by USB and trust the computer.
3. Drag `Sol-Browser-unsigned.ipa` into Sideloadly, enter your Apple ID, and click **Start**.
4. When done, on the iPad: **Settings ▸ General ▸ VPN & Device Management** ▸ trust
   the developer profile, then launch Aura.
5. Re-run Sideloadly every 7 days to refresh (free accounts).

### SideStore (refresh on-device, no computer after setup)

1. Follow the SideStore setup guide: <https://sidestore.io> — it uses a one-time
   computer pairing (via AltServer/iload) to install SideStore + a WireGuard-based
   local VPN.
2. Once set up, open **SideStore** ▸ **+** ▸ select `Sol-Browser-unsigned.ipa` to install.
3. SideStore can refresh apps **on-device over Wi-Fi** without your computer, which
   makes the 7-day limit much easier to live with.

---

## Optional AI features

"Browse for Me" and AI boosts call the OpenAI API. They are **optional**: without an
API key the browser works normally and those features show a friendly "enter an API
key" prompt instead of failing. Add your key in Settings if you want them.

---

## Testing status (please read)

This fork was developed on **Windows**, where Swift/iOS code cannot be compiled or
run locally. Correctness is enforced two ways:

1. A careful static review of every modified file for compile-safety and logic.
2. The **GitHub Actions macOS build**, which is the real compile gate — it builds for
   the iOS Simulator and for a real device on every push.

**The fork author has not run this on a physical iPad.** If you sideload it and hit a
bug, please open an issue with your iPad model, iPadOS version, and what you were
doing. On-device reports are the fastest way to harden this further.

---

## Upstream screenshots

### Aura on iPadOS
![iPad](https://github.com/user-attachments/assets/c2b137d1-e9e5-4f80-841c-5d794142f61c)

### Aura on iOS
![iOS](https://github.com/user-attachments/assets/ed15f742-ed57-4c20-a1bf-59d913bca5ac)

### Aura on visionOS
![visionOS](https://github.com/user-attachments/assets/8027e5bf-0e1e-452d-9394-7bc8cec3c271)

---

*Original Aura README notes: upstream is being rewritten as
[Aura 2.0](https://github.com/doorhinge-apps/Aura2.0) (requires iOS 26). This fork is
based on the classic SwiftUI/WebKit Aura that supports iPadOS 17+.*