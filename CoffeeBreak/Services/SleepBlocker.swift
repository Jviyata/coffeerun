import Foundation
import IOKit.pwr_mgt

/// Wraps `IOPMAssertion` to keep the display and Mac awake while active.
/// Same mechanism the `caffeinate` command-line tool uses.
@MainActor
final class SleepBlocker {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive: Bool = false

    /// Acquire a no-display-sleep assertion. Idempotent.
    func enable(reason: String = "Coffee Run — Caffeinated mode") {
        guard !isActive else { return }
        var newID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newID
        )
        if result == kIOReturnSuccess {
            self.assertionID = newID
            self.isActive = true
        }
    }

    /// Release the assertion. Idempotent.
    func disable() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }

    deinit {
        if isActive {
            IOPMAssertionRelease(assertionID)
        }
    }
}
