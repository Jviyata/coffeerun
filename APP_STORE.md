# Submitting Coffee Run to the Mac App Store

A practical, in-order checklist for getting Coffee Run from this SwiftPM dev build to a live App Store listing.

## Phase 1 — Apple Developer enrollment ($99/year)

1. Sign up at https://developer.apple.com/programs/enroll/. Individual or organization — either works.
2. Wait for enrollment to complete (usually same day, can take 24–48h).
3. Once enrolled, sign in to **App Store Connect** (https://appstoreconnect.apple.com).

## Phase 2 — Bundle ID + App record

1. **Developer Portal → Identifiers → +** → register `com.ruta.coffeebreak` (or rename to `com.<yourorg>.coffeerun` if you want a fresh ID).
2. Enable the following capabilities on the identifier:
   - App Sandbox
   - iCloud (with **Key-Value storage**) — for the cross-Mac stats sync
3. **App Store Connect → My Apps → +** → create a new app:
   - Platform: macOS
   - Name: **Coffee Run**
   - Primary language: English
   - Bundle ID: pick the one you just registered
   - SKU: anything unique, e.g. `coffee-run-1`
   - Full Access (not Limited)

## Phase 3 — Wrap the SwiftPM code in an Xcode project

The current source tree builds via Swift Package Manager. Xcode submission requires a real `.xcodeproj`.

1. **Xcode → File → New → Project… → macOS → App** → name it `CoffeeRun` (or `CoffeeBreak` to match existing bundle id).
2. Interface: **SwiftUI**. Language: **Swift**. Use storage: **None**.
3. Delete the default `CoffeeBreakApp.swift` and `ContentView.swift`.
4. Drag the contents of `CoffeeBreak/CoffeeBreak/` (the `Models/`, `Services/`, `State/`, `Views/` folders + the root `.swift` files + `Info.plist` + `CoffeeBreak.entitlements`) into the new project — choose **Copy items if needed** and **Create groups**.
5. In **Signing & Capabilities**:
   - Team: your Developer Program team
   - Bundle Identifier: match what you registered above
   - Enable **App Sandbox**
   - Under App Sandbox, tick **Incoming Connections (Server)** and **Outgoing Connections (Client)**
   - Click **+ Capability** → add **iCloud**, then enable **Key-Value storage**
6. **General → Deployment Info**: set minimum target to **macOS 13.0**.
7. **Build Settings → Info.plist File**: point at the imported `Info.plist`.
8. **App Icon**: drag the existing `AppIcon.icns` into `Assets.xcassets`, or use the prepared `AppIcon.appiconset` folder.
9. Test with **⌘R**. The status item cup should appear.

## Phase 4 — Code signing setup

Xcode will manage signing automatically once your team is selected, but verify:

1. **Signing & Capabilities → Signing** is set to *Automatically manage signing*.
2. Provisioning profile should show `Mac App Store` after a build.
3. If Xcode complains about missing entitlements, double-check:
   - `com.apple.security.app-sandbox` = true (required for App Store)
   - `com.apple.security.network.server` = true
   - `com.apple.security.network.client` = true
   - `com.apple.developer.ubiquity-kvstore-identifier` = `$(TeamIdentifierPrefix)$(CFBundleIdentifier)`

## Phase 5 — Required Info.plist additions

Already in the repo:

- `CFBundleName` / `CFBundleDisplayName` = `Coffee Run`
- `LSUIElement` = `true` (no Dock icon, menu bar only)
- `LSMinimumSystemVersion` = `13.0`
- `LSApplicationCategoryType` = `public.app-category.social-networking`
- `NSLocalNetworkUsageDescription` = (explains Bonjour reason to the user)
- `NSBonjourServices` = `["_coffeebreak._tcp"]`
- `NSHumanReadableCopyright`

Bump for each release:

- `CFBundleShortVersionString` = e.g. `1.0` (user-visible version)
- `CFBundleVersion` = e.g. `1` (build number — must be unique per submission)

## Phase 6 — App Store Connect listing

In **App Store Connect → Your App → App Store** tab:

1. **App Information**
   - Category: Social Networking
   - Subcategory: optional
2. **Pricing and Availability**: Free or paid tier
3. **App Privacy** — answer the questionnaire honestly:
   - Data Collection: **No, we do not collect data from this app**
   - All "Data Linked to You" / "Data Used to Track You" → **none**
   - This is a privacy-friendly app — emphasise the no-cloud, no-account model
4. **macOS App** (per version):
   - **Promotional text** (170 chars)
   - **Description** (4000 chars) — see template below
   - **Keywords** (100 chars, comma-separated) — e.g. `coffee, office, social, local, network, bonjour, team, menu bar, mac`
   - **Support URL** — a webpage with contact info (GitHub repo Issues page works)
   - **Marketing URL** — optional, your product page
   - **Privacy Policy URL** — *required*. Host a simple page like https://github.com/ruta/coffeerun/blob/main/PRIVACY.md
   - **Screenshots** — at least 1, max 10:
     - macOS screenshots must be **1280×800** (or 1440×900, 2560×1600, 2880×1800) PNG/JPG
     - Take with **Cmd+Shift+4** then screenshot the menu open + Profile & Settings window
   - **App icon** — auto-pulled from your `AppIcon.appiconset` (already prepared, 1024×1024 base)

## Phase 7 — Privacy policy (required)

Host a short page at any HTTPS URL. Minimum content:

```
Coffee Run Privacy Policy

Coffee Run does not collect, transmit, or store any personal data on
external servers. All app data — your display name, coffee logs,
groups, and statistics — is stored locally on your Mac in standard
macOS preferences storage (UserDefaults). With iCloud Sync enabled
(an optional preference), your local stats are synchronized between
Macs signed into the same Apple ID via Apple's iCloud Key-Value
Store. Coffee Run does not have access to your iCloud account.

Coffee Run broadcasts your status (display name, coffee status,
timestamp, optional note) only on your local network using Apple's
Bonjour/mDNS protocol. This information is visible only to other
Coffee Run users on the same Wi-Fi or Ethernet segment. No data is
ever sent to any server.

Coffee Run does not use third-party analytics, advertising, or
tracking services.

Contact: <your email>
Last updated: <date>
```

## Phase 8 — Archive + upload

1. In Xcode: **Product → Destination → Any Mac (Apple Silicon, Intel)**.
2. **Product → Archive** (Xcode menu, may take a minute).
3. The **Organizer** window opens automatically when done.
4. Click **Distribute App** → **App Store Connect** → **Upload**.
5. Xcode validates, signs, uploads to App Store Connect.
6. After upload, the build appears in **App Store Connect → Your App → TestFlight** within ~15 minutes.

## Phase 9 — TestFlight (optional but recommended)

Test the App Store build before submitting for review:

1. App Store Connect → TestFlight → enable **Internal Testing**.
2. Add yourself and any coworkers as testers (uses their Apple IDs).
3. They receive an invite, install **TestFlight** for Mac, and can install Coffee Run from there.
4. Verify everything works in the sandboxed/signed environment — especially **local network permission**, **notifications**, and **iCloud sync**.

## Phase 10 — Submit for review

1. App Store Connect → your app → **macOS App** → select the uploaded build.
2. Answer the **Export Compliance** question:
   - Uses encryption? Generally yes (any HTTPS use does) — but Coffee Run only uses Bonjour locally, **no encryption beyond what macOS itself provides**.
   - For an app that only uses Apple-provided crypto (no custom), select **No** to "non-exempt encryption".
3. Notes for the reviewer:
   ```
   Coffee Run is a local-network-only Mac menu bar app for coordinating
   spontaneous office coffee runs. It uses Apple's Bonjour/mDNS protocol
   to discover other Coffee Run users on the same Wi-Fi network, and
   broadcasts a display name + coffee status. No internet connection is
   required or used. To test peer discovery, please run two instances on
   the same Wi-Fi network.
   ```
4. Submit → wait ~24-48h for review.

## Phase 11 — Release

When approved:

- Choose **Manual** or **Automatic** release (Automatic = goes live as soon as approved).
- Once live, your app appears in the Mac App Store and macOS Software Update handles all subsequent updates automatically — no Sparkle needed.

## Versioning future updates

For each release after v1.0:

1. Bump `CFBundleShortVersionString` (user-visible) — e.g. `1.1`
2. Bump `CFBundleVersion` (build number, must be strictly greater) — e.g. `2`
3. Make code changes
4. **Product → Archive → Distribute App → App Store Connect**
5. App Store Connect → **+ Version** → fill in **What's New in This Version**
6. Submit for review
7. Approved updates auto-install on users' Macs

## Things that might trip the reviewer

- **Local Network permission prompt copy** — currently *"Coffee Run uses your local network to find others nearby who want to grab coffee."* — reads naturally, should pass.
- **No login is unusual** — make sure the description emphasises *"no accounts, no servers"* so the reviewer doesn't expect (or look for) a login flow.
- **Menu-bar-only app** — be sure to mention this; reviewer might initially miss the app since it has no Dock icon. Note it in the review notes too.
- **Bonjour service type** — `_coffeebreak._tcp` is declared in `NSBonjourServices` — good. If you want to clean up the legacy name to match the new app name, rename to `_coffeerun._tcp` *before* submitting v1.0 (changing it post-launch breaks discovery between old and new clients).

## Done

Once approved, future iterations are just **bump version → Archive → Distribute → Submit**. Users get updates silently via the App Store. No more DMGs.
