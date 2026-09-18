import Foundation

enum RecordingStatus: Equatable {
    case idle
    case recording
    case transcribing
    case cleaning
    case error(String)
}

@MainActor
final class AppState: ObservableObject {
    @Published var status: RecordingStatus = .idle {
        didSet { indicator.update(status: status) }
    }
    @Published var lastText: String = ""
    @Published var hotkeyActive: Bool = false

    let settings: SettingsStore
    let history: HistoryStore
    private let recorder = AudioRecorder()
    private let hotkeys = HotkeyManager()
    private let indicator = RecordingIndicatorController()
    private var recordingStartedAt: Date?

    init(settings: SettingsStore, history: HistoryStore) {
        self.settings = settings
        self.history = history
        hotkeys.onStart = { [weak self] in self?.beginRecording() }
        hotkeys.onStop = { [weak self] in self?.finishRecording() }
    }

    func restartHotkeyListener() {
        hotkeys.targetKeyCode = settings.hotkey.keyCode
        hotkeyActive = hotkeys.start()
    }

    private func beginRecording() {
        guard status == .idle || isError else { return }
        do {
            try recorder.start()
            recordingStartedAt = Date()
            status = .recording
        } catch {
            status = .error("Не удалось начать запись: \(error.localizedDescription)")
        }
    }

    private func finishRecording() {
        guard status == .recording else { return }
        let duration = recordingStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        recordingStartedAt = nil

        guard let fileURL = recorder.stop() else {
            status = .idle
            return
        }

        status = .transcribing
        Task {
            await transcribeAndInsert(fileURL: fileURL, durationSeconds: duration)
        }
    }

    private func transcribeAndInsert(fileURL: URL, durationSeconds: Double) async {
        defer { try? FileManager.default.removeItem(at: fileURL) }

        guard !settings.gapiToken.isEmpty else {
            status = .error("Не задан токен gapi. Откройте настройки.")
            return
        }

        do {
            var text = try await GapiClient(token: settings.gapiToken).transcribe(fileURL: fileURL)

            if settings.cleanupStyle != .off && !settings.anthropicApiKey.isEmpty {
                status = .cleaning
                text = try await ClaudeClient(apiKey: settings.anthropicApiKey)
                    .cleanup(text: text, style: settings.cleanupStyle)
            }

            lastText = text
            history.add(text: text, durationSeconds: durationSeconds)
            TextInjector.copyToClipboard(text)
            if settings.autoPaste && TextInjector.canPasteIntoFocusedField() {
                TextInjector.pasteAtCursor()
            }
            status = .idle
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private var isError: Bool {
        if case .error = status { return true }
        return false
    }
}
