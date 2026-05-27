import AppKit

/// Registers a global ⌃⌥C hotkey that lets the user start a coffee run
/// from anywhere on macOS without opening the menu.
///
/// Two monitors are needed because `addGlobalMonitorForEvents` only fires
/// when *another* app has focus. `addLocalMonitor` covers the case where
/// our own settings window is active.
///
/// No Accessibility permission is required for this — these monitors
/// observe key events without injecting or consuming system-wide input.
@MainActor
final class GlobalHotkey {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// Fires on the main actor every time ⌃⌥C is pressed.
    var onTrigger: (() -> Void)?

    /// Modifier mask we expect — control + option only. We compare the
    /// device-independent flags so caps-lock and other transient state
    /// don't get in the way.
    private let expectedFlags: NSEvent.ModifierFlags = [.control, .option]

    func start() {
        // Already running — nothing to do.
        guard globalMonitor == nil && localMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            if self.matchesHotkey(event) {
                Task { @MainActor [weak self] in
                    self?.onTrigger?()
                }
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.matchesHotkey(event) {
                Task { @MainActor [weak self] in
                    self?.onTrigger?()
                }
                return nil   // consume the event so it doesn't beep
            }
            return event
        }
    }

    func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
        globalMonitor = nil
        localMonitor = nil
    }

    deinit {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
    }

    private func matchesHotkey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == expectedFlags else { return false }
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return false }
        return chars == "c"
    }
}
