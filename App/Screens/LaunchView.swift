import SwiftUI

/// Matches the UILaunchScreen exactly (black, LykosMark at its natural size, centred in the safe
/// area), so the hand-off is invisible. Covers the web view until the first page finishes loading,
/// then fades out.
struct LaunchView: View {
    var body: some View {
        ZStack {
            Noir.background.ignoresSafeArea()
            Image("LykosMark")
                .accessibilityHidden(true)
        }
    }
}
