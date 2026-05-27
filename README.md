# Coffee Break ☕

A tiny macOS menu bar app that lets people on the same local network signal when they want to grab coffee. No login, no cloud, no internet — just Bonjour discovery on the LAN.

## What it does

- Lives in the menu bar as a small coffee cup icon (no Dock icon).
- Click it to broadcast one of: **I want coffee**, **Going for coffee now**, **Available**, **Not available**, plus an optional short note (e.g. "Leaving in 5 mins").
- Shows everyone else nearby on the same Wi-Fi running Coffee Break and what they're up to.
- Native macOS notification when someone wants coffee — with a **Join** action that flips your status to *Joining coffee* so everyone sees you're in.
- Statuses auto-expire after 15 / 30 / 60 minutes (configurable) so the network never gets stale.
- Identity is just a display name stored in `UserDefaults`. No accounts.

## Requirements

- macOS 13 Ventura or later (uses `MenuBarExtra`, `NWBrowser.Descriptor.bonjourWithTXTRecord`, `SMAppService`).
- Xcode 15+ to build.

## How to build (5 minutes)

This repo contains the Swift sources for the app. Wrap them in a tiny Xcode project:

1. **Open Xcode → File → New → Project…**
2. Choose **macOS → App**.
3. Settings:
   - Product Name: `CoffeeBreak`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
4. Save the project anywhere. Xcode will create a `CoffeeBreak/CoffeeBreak/` source folder.
5. **Delete** the default `CoffeeBreakApp.swift` and `ContentView.swift` Xcode generated.
6. **Drag the contents of this repo's `CoffeeBreak/CoffeeBreak/` folder** into the same folder in Xcode (the `Models/`, `Services/`, `State/`, `Views/` subfolders + `CoffeeBreakApp.swift`). Choose **Copy items if needed** and **Create groups**.
7. Replace the auto-generated `Info.plist` with the one provided here (or merge these keys in):
   - `LSUIElement = YES` — hides the Dock icon so it's truly menu-bar-only.
   - `NSBonjourServices = ["_coffeebreak._tcp"]` — required on macOS 14+ for Bonjour discovery to work.
   - `NSLocalNetworkUsageDescription` — the prompt the user sees the first time the app touches the LAN.
8. In the target's **Signing & Capabilities** tab, add the **App Sandbox** capability and enable:
   - **Incoming Connections (Server)** — to advertise our Bonjour service.
   - **Outgoing Connections (Client)** — to browse for peers.
9. Set the deployment target to **macOS 13.0**.
10. **Build & Run** (⌘R). A coffee cup appears in the menu bar.

> First launch will prompt for a display name, then for permission to access the local network and to send notifications. Both are required.

## How it works

### Discovery (no server, no cloud)
- Each app instance publishes a Bonjour service of type `_coffeebreak._tcp` via `NWListener`. Its full state — display name, status, timestamp, optional note, and a stable peer UUID — is encoded in the service's TXT record.
- Each instance also runs an `NWBrowser` for the same service type and re-parses every TXT record into a `Peer`.
- When you change status, we update the TXT record in place; everyone else's browser fires a callback within a second or two.

This deliberately avoids opening any actual TCP connections — the TXT record carries everything we need, so there's no transport layer to keep in sync.

### Auto-expiry
- Each peer carries the timestamp at which they set their current status.
- The menu filters out peers whose status has aged past your local expiry window.
- A timer on your own app resets you to *Available* once your expiry elapses, so you don't accidentally stay "wants coffee" forever.

### Notifications
- The first signal we see from each peer (or any newer signal) triggers a native `UNUserNotificationCenter` banner with **Join** / **Dismiss** actions.
- Tapping **Join** sets your status to *Joining coffee*, which everyone else sees right away.

## Project layout

```
CoffeeBreak/
├── CoffeeBreakApp.swift          // @main, MenuBarExtra, Preferences window
├── Info.plist
├── CoffeeBreak.entitlements
├── Models/
│   ├── CoffeeStatus.swift        // enum: available, wantCoffee, goingNow, joining, notAvailable
│   └── Peer.swift                // remote peer record
├── Services/
│   ├── NetworkService.swift      // Bonjour broadcast + browse via Network.framework
│   ├── NotificationService.swift // UNUserNotificationCenter wrapper with Join action
│   └── PreferencesStore.swift    // UserDefaults + SMAppService login-item
├── State/
│   └── AppState.swift            // ObservableObject the whole UI binds to
└── Views/
    ├── MenuContentView.swift     // The popover that opens from the menu bar
    ├── PeerRow.swift             // One row in the "People nearby" list
    ├── WelcomeView.swift         // First-launch display name prompt
    └── PreferencesView.swift     // Preferences window
```

## Privacy

Coffee Break is offline-first by design:
- No network traffic ever leaves the local subnet.
- No analytics, no telemetry, no accounts.
- The only persisted data is your display name, a randomly-generated peer UUID, and your preferences — all in `UserDefaults`.

## Roadmap (not in MVP)

- Optional "huddle" location (e.g. "kitchen", "3rd floor") in the broadcast.
- Quick reactions / wave back.
- Configurable Bonjour subdomain so different teams in the same office don't see each other.
