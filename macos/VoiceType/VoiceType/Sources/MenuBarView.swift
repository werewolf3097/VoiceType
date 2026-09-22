import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            statusLine

            if case .error(let message) = appState.status {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !appState.hotkeyActive {
                permissionWarning
            }

            Divider()

            Text("Зажмите \(settings.hotkey.rawValue), говорите, отпустите.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("Настройки…") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Выйти") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 260)
        .onAppear { appState.restartHotkeyListener() }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch appState.status {
        case .idle:
            Label("Готов", systemImage: "mic")
        case .recording:
            Label("Запись…", systemImage: "mic.fill").foregroundStyle(.red)
        case .transcribing:
            Label("Распознавание…", systemImage: "waveform")
        case .cleaning:
            Label("Обработка текста…", systemImage: "wand.and.stars")
        case .error:
            Label("Ошибка", systemImage: "exclamationmark.triangle")
        }
    }

    private var permissionWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Нет доступа к чтению клавиш.")
                .font(.caption)
                .foregroundStyle(.orange)
            Button("Открыть «Мониторинг ввода»") {
                PermissionsHelper.openInputMonitoringSettings()
            }
            .font(.caption)
        }
    }
}
