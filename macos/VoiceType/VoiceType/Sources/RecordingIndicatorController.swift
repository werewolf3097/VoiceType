import AppKit
import SwiftUI

/// Плавающая капсула поверх всех окон и Spaces — визуальное подтверждение того,
/// что происходит прямо сейчас (запись/распознавание/обработка/ошибка), без
/// необходимости открывать меню в строке статуса.
@MainActor
final class RecordingIndicatorController {
    private var panel: NSPanel?
    private var hideWorkItem: DispatchWorkItem?

    func update(status: RecordingStatus) {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        switch status {
        case .idle:
            hide()
        case .recording, .transcribing, .cleaning:
            show(status: status)
        case .error:
            show(status: status)
            let workItem = DispatchWorkItem { [weak self] in self?.hide() }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }

    private func show(status: RecordingStatus) {
        let panel = panel ?? makePanel()
        self.panel = panel
        if let hosting = panel.contentView as? NSHostingView<RecordingIndicatorView> {
            hosting.rootView = RecordingIndicatorView(status: status)
            hosting.layoutSubtreeIfNeeded()
        }
        position(panel)
        panel.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let hosting = NSHostingView(rootView: RecordingIndicatorView(status: .recording))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.contentView = hosting
        return panel
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        panel.setContentSize(panel.contentView?.fittingSize ?? NSSize(width: 200, height: 44))
        let screenFrame = screen.visibleFrame
        let size = panel.frame.size
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.maxY - size.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
