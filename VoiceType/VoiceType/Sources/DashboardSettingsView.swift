import SwiftUI

struct DashboardSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Ключи API") {
                SecureField("Токен gapi", text: $settings.gapiToken)
                Text("Создаётся в кабинете console.gapi.uz на вкладке «API-токены».")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("Anthropic API key (необязательно)", text: $settings.anthropicApiKey)
                Text("Нужен только для очистки текста стилем ниже. Получить: console.anthropic.com.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Приложение") {
                Toggle("Показывать значок в Dock", isOn: $settings.showDockIcon)
                Text("Меню в строке статуса доступно в любом случае — это только про значок в Dock.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Голос") {
                Picker("Клавиша (push-to-talk)", selection: $settings.hotkey) {
                    ForEach(PushToTalkKey.allCases) { key in
                        Text(key.rawValue).tag(key)
                    }
                }
                .onChange(of: settings.hotkey) { _, _ in
                    appState.restartHotkeyListener()
                }

                Toggle("Автовставка в активное поле (Cmd+V)", isOn: $settings.autoPaste)

                Picker("Обработка текста", selection: $settings.cleanupStyle) {
                    ForEach(CleanupStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }

            Section("Разрешения") {
                HStack {
                    Text(appState.hotkeyActive ? "Мониторинг ввода: разрешён" : "Мониторинг ввода: нужно разрешить")
                    Spacer()
                    Button("Открыть настройки") {
                        PermissionsHelper.openInputMonitoringSettings()
                    }
                }
                HStack {
                    Text("Микрофон")
                    Spacer()
                    Button("Открыть настройки") {
                        PermissionsHelper.openMicrophoneSettings()
                    }
                }
                if settings.autoPaste {
                    HStack {
                        Text("Для автовставки может понадобиться Accessibility")
                        Spacer()
                        Button("Открыть настройки") {
                            PermissionsHelper.openAccessibilitySettings()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            PermissionsHelper.requestMicrophone { _ in }
            appState.restartHotkeyListener()
        }
    }
}
