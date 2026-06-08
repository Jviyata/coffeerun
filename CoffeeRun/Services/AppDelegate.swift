import AppKit
import SwiftUI

/// Holds shared state and provides hooks (popover dismiss, settings window
/// opener) that need AppKit access. The actual menu bar item is rendered by
/// SwiftUI's `MenuBarExtra` scene in `CoffeeRunApp` — we tried managing
/// `NSStatusItem` ourselves but `NSStatusBar.system` returns a scene-proxy
/// (`NSSceneStatusItem`) whenever SwiftUI is linked, and that proxy only
/// renders when a `MenuBarExtra` scene drives it.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let appState = AppState()
    private var settingsWindow: NSWindow?
    private var inviteWindow: NSWindow?
    private let hotkey = GlobalHotkey()

    override init() {
        super.init()
        NSLog("[CoffeeRun] AppDelegate init")
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSLog("[CoffeeRun] willFinishLaunching")
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[CoffeeRun] didFinishLaunching, policy=\(NSApp.activationPolicy().rawValue)")
        NSApp.setActivationPolicy(.accessory)
        wireMenuBarHelpers()
        registerGlobalHotkey()
        NSLog("[CoffeeRun] menu bar helpers wired")
    }

    // MARK: - Global hotkey (⌃⌥C → start a Brwup from anywhere)

    private func registerGlobalHotkey() {
        hotkey.onTrigger = { [weak self] in
            self?.appState.startCoffeeRunFromHotkey()
        }
        hotkey.start()
    }

    // MARK: - View hooks

    private func wireMenuBarHelpers() {
        // Dismiss the MenuBarExtra popover by closing the specific
        // backing window for it. We narrow the search to avoid closing
        // anything else (e.g. our own settings window).
        appState.dismissMenuBar = {
            DispatchQueue.main.async {
                for window in NSApp.windows {
                    let className = String(describing: type(of: window))
                    // Only target the SwiftUI menu bar popover —
                    // not generic NSPopover, NSPanel, etc.
                    if className == "NSMenuBarExtraWindow"
                        || className == "MenuBarExtraWindow"
                        || className.hasPrefix("MenuBarExtra") {
                        window.close()
                    }
                }
            }
        }

        // Open Profile & Settings as a plain NSWindow (we used to use
        // SwiftUI's openWindow, but that requires the environment which
        // isn't always available from menu actions).
        appState.openSettings = { [weak self] in
            self?.openSettingsWindow()
        }

        appState.openInvite = { [weak self] in
            self?.openInviteWindow()
        }
    }

    private func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 580),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Profile & Settings"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = NSHostingController(
                rootView: PreferencesView().environmentObject(appState)
            )
            window.delegate = self  // so we can drop back to accessory on close
            settingsWindow = window
        }
        // Briefly become a regular app so the window can take focus and
        // appear above other windows. We drop back to accessory when
        // the user closes the window (see windowWillClose).
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func openInviteWindow() {
        if inviteWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 460),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Invite a coworker"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = NSHostingController(
                rootView: InviteSheet().environmentObject(appState)
            )
            window.delegate = self
            inviteWindow = window
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        inviteWindow?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - NSWindowDelegate (Settings window lifecycle)

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // When Settings closes, hide the Dock icon again.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
