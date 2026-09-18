import Foundation
import CoreGraphics

enum PushToTalkKey: String, CaseIterable, Identifiable {
    case rightOption = "Right Option"
    case rightCommand = "Right Command"
    case rightControl = "Right Control"
    case rightShift = "Right Shift"

    var id: String { rawValue }

    var keyCode: CGKeyCode {
        switch self {
        case .rightOption: return 61
        case .rightCommand: return 54
        case .rightControl: return 62
        case .rightShift: return 60
        }
    }
}

enum CleanupStyle: String, CaseIterable, Identifiable {
    case off = "Без обработки"
    case grammar = "Только грамматика"
    case notes = "Заметка"
    case message = "Сообщение/письмо"

    var id: String { rawValue }

    var systemPrompt: String? {
        switch self {
        case .off:
            return nil
        case .grammar:
            return "Ты редактор. Тебе дают сырую расшифровку голосовой речи. Исправь грамматику, пунктуацию и явные оговорки/повторы (слова-паразиты вроде «э-э», «типа», «ну»). Не меняй смысл, не добавляй ничего от себя, не переводи на другой язык. Верни только исправленный текст, без пояснений и кавычек."
        case .notes:
            return "Ты редактор. Тебе дают сырую расшифровку голосовой заметки. Приведи её в читаемый вид: убери слова-паразиты и оговорки, разбей на абзацы или пункты, если это уместно. Сохрани язык и смысл оригинала. Верни только готовый текст, без пояснений и кавычек."
        case .message:
            return "Ты редактор. Тебе дают сырую расшифровку голосового сообщения, которое человек хочет отправить как текстовое письмо или чат-сообщение. Приведи его к связному, вежливому тексту сообщения на том же языке, убери слова-паразиты. Не добавляй приветствия и подпись, если их не было. Верни только готовый текст, без пояснений и кавычек."
        }
    }
}

final class SettingsStore: ObservableObject {
    @Published var hotkey: PushToTalkKey {
        didSet { UserDefaults.standard.set(hotkey.rawValue, forKey: "hotkey") }
    }
    @Published var autoPaste: Bool {
        didSet { UserDefaults.standard.set(autoPaste, forKey: "autoPaste") }
    }
    @Published var cleanupStyle: CleanupStyle {
        didSet { UserDefaults.standard.set(cleanupStyle.rawValue, forKey: "cleanupStyle") }
    }
    @Published var showDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon")
            DockIconController.apply(visible: showDockIcon)
        }
    }

    @Published var gapiToken: String {
        didSet { KeychainStore.set(gapiToken, forKey: "gapiToken") }
    }
    @Published var anthropicApiKey: String {
        didSet { KeychainStore.set(anthropicApiKey, forKey: "anthropicApiKey") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.hotkey = PushToTalkKey(rawValue: defaults.string(forKey: "hotkey") ?? "") ?? .rightOption
        self.autoPaste = defaults.object(forKey: "autoPaste") as? Bool ?? true
        self.cleanupStyle = CleanupStyle(rawValue: defaults.string(forKey: "cleanupStyle") ?? "") ?? .grammar
        self.showDockIcon = defaults.object(forKey: "showDockIcon") as? Bool ?? true
        self.gapiToken = KeychainStore.get("gapiToken") ?? ""
        self.anthropicApiKey = KeychainStore.get("anthropicApiKey") ?? ""
        DockIconController.apply(visible: self.showDockIcon)
    }
}
