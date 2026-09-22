import AppKit

enum DockIconController {
    static func apply(visible: Bool) {
        // NSApp (the implicitly-unwrapped global) is still nil this early in the
        // SwiftUI App lifecycle — SettingsStore.init() runs before App.main() has
        // finished standing up NSApplication. NSApplication.shared lazily creates
        // it instead of crashing, and the async hop lets launch finish first.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(visible ? .regular : .accessory)
        }
    }
}
