import AppKit
import ApplicationServices
import CoreGraphics

enum TextInjector {
    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Есть ли под курсором сфокусированное поле, в которое реально можно что-то вставить.
    /// Без разрешения Accessibility узнать это невозможно — тогда считаем, что можно
    /// (прежнее поведение: пробуем вставить, полагаясь на выбор пользователя в настройках).
    static func canPasteIntoFocusedField() -> Bool {
        guard AXIsProcessTrusted() else { return true }

        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        let status = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        guard status == .success, let element = focused else { return false }

        var settable: DarwinBoolean = false
        let settableStatus = AXUIElementIsAttributeSettable(element as! AXUIElement, kAXValueAttribute as CFString, &settable)
        return settableStatus == .success && settable.boolValue
    }

    static func pasteAtCursor() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
