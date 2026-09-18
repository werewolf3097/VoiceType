import SwiftUI

struct RecordingIndicatorView: View {
    let status: RecordingStatus

    var body: some View {
        HStack(spacing: 10) {
            icon
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black.opacity(0.85), in: Capsule())
        .fixedSize()
    }

    @ViewBuilder
    private var icon: some View {
        switch status {
        case .recording:
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, isActive: true)
                .foregroundStyle(.red)
        case .transcribing, .cleaning:
            ProgressView()
                .controlSize(.small)
                .tint(.white)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .idle:
            EmptyView()
        }
    }

    private var title: String {
        switch status {
        case .idle: return ""
        case .recording: return "Слушаю…"
        case .transcribing: return "Распознаю речь…"
        case .cleaning: return "Обрабатываю текст…"
        case .error(let message): return message
        }
    }
}
