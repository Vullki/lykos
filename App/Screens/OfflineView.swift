import SwiftUI

/// Shown over the web view when there's no connection or the page can't load. The web view stays
/// underneath, so Retry picks up where it left off. A long press anywhere opens the debug log.
struct OfflineView: View {
    let message: String
    let isRetrying: Bool
    let onRetry: () -> Void
    let onOpenDebugLog: () -> Void

    var body: some View {
        ZStack {
            Noir.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Image("LykosMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .foregroundStyle(Noir.deep)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("OFFLINE")
                        .font(.system(size: 11, weight: .medium))
                        .kerning(Noir.labelTracking(11))
                        .foregroundStyle(Noir.label)
                    Text(message)
                        .font(.system(size: 17))
                        .foregroundStyle(Noir.text)
                        .multilineTextAlignment(.center)
                }

                Button(action: onRetry) {
                    ZStack {
                        Text("Retry")
                            .opacity(isRetrying ? 0 : 1)
                        if isRetrying {
                            ProgressView()
                                .tint(Noir.text)
                        }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Noir.text)
                    .frame(minWidth: 128, minHeight: 44)
                    .overlay(Capsule().strokeBorder(Noir.label, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isRetrying)
                .accessibilityLabel(isRetrying ? "Retrying" : "Retry")
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.0) {
            onOpenDebugLog()
        }
    }
}
