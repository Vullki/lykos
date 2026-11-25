import SwiftUI

@main
struct LykosApp: App {
    @StateObject private var store = WebViewStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .onOpenURL { url in
                    store.handleDeepLink(url)
                }
        }
    }
}

/// The web view, with the offline and launch screens layered over it. The web view is never
/// removed: the overlays only cover it.
struct RootView: View {
    @ObservedObject var store: WebViewStore

    var body: some View {
        ZStack {
            // Behind the status bar, the home indicator and the side insets in landscape: the page's
            // own colour, so the strips around the web view read as part of the app, not bands.
            store.topBarColor
                .ignoresSafeArea()

            // The web view stays inside the safe area on every side: claude.ai pins its header
            // (sidebar button, incognito) to the top and its composer row to the bottom of the
            // page, and neither leaves room for the status bar or the home indicator in an app.
            // The keyboard is left to WebKit.
            ClaudeWebView(store: store)
                .ignoresSafeArea(.keyboard)

            if store.showOffline {
                OfflineView(
                    message: store.offlineMessage,
                    isRetrying: store.isRetrying,
                    onRetry: { store.retry() },
                    onOpenDebugLog: { store.showDebugLog = true }
                )
                .transition(.opacity)
            }

            if !store.launchFinished {
                LaunchView()
                    .transition(.opacity)
            }
        }
        .background(Noir.background.ignoresSafeArea())
        .onAppear {
            // A new build drops the launch picture iOS cached from the old one (see LaunchSnapshot).
            if let note = LaunchSnapshot.clearIfBuildChanged() {
                DebugLog.shared.add(.native, note)
            }
        }
        .animation(.easeOut(duration: 0.35), value: store.launchFinished)
        .animation(.easeInOut(duration: 0.25), value: store.showOffline)
        .sheet(isPresented: $store.showDebugLog) {
            DebugLogView(log: DebugLog.shared)
        }
    }
}
