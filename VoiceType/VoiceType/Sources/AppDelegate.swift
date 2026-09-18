import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Держим токен живым весь срок работы приложения: без этого macOS применяет App Nap,
    // как только VoiceType уходит в фон, и глобальный хоткей перестаёт реагировать вовремя
    // (или вообще) — именно это выглядело как «хоткей работает, только пока открыто меню».
    private var activityToken: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Глобальный хоткей должен реагировать даже когда приложение в фоне"
        )
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Настройки…", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
