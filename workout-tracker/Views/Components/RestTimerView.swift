import SwiftUI

struct RestTimerView: View {
    let seconds: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Rest Timer")
                    .font(.headline)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Text(formatTime(seconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(seconds <= 10 ? .red : .primary)

            Text("Tap X to skip")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
