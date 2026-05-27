import SwiftUI

@main
struct CoffeeBreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(delegate.appState)
        } label: {
            // The label MUST render as a hit-testable single image-or-text
            // for MenuBarExtra to register clicks. Custom SwiftUI views
            // with HStack + multiple Images silently lose the click area.
            // We pre-compose the icon into a single SF Symbol name and let
            // SwiftUI render it as a plain Image, with the count number
            // appended as Text when needed.
            HStack(spacing: 2) {
                Image(systemName: delegate.appState.statusSymbolName)
                if delegate.appState.isCaffeinated {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                }
                if delegate.appState.menuBarBadgeCount > 1 {
                    Text("\(delegate.appState.menuBarBadgeCount)")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
