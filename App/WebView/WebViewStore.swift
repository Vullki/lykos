import Foundation
import Network
import SwiftUI
import WebKit

/// App-wide state around the one web view: what's loading, whether to show the launch, offline and
/// debug screens, and the network monitor. Created once by `LykosApp`.
@MainActor
final class WebViewStore: ObservableObject {
    /// False until the first page finishes loading; `LaunchView` covers the web view until then.
    @Published private(set) var launchFinished = false
    @Published private(set) var showOffline = false
    @Published private(set) var offlineMessage = ""
    @Published private(set) var isRetrying = false
    @Published var showDebugLog = false
    /// Fills the strip behind the status bar: claude.ai's theme colour, else its page background.
    @Published private(set) var topBarColor: Color = Noir.background

    private(set) var webView: WKWebView?
    private var colorObservations: [NSKeyValueObservation] = []
    private lazy var coordinator = WebCoordinator(store: self)
    private var pendingURL: URL?
    private var lastRequestedURL: URL?
    /// True once any main-frame page has committed, so there's something on screen to keep.
    private var hasCommittedPage = false
    private var isOnline = true
    private let pathMonitor = NWPathMonitor()

    init() {
        DownloadFiles.clearLeftovers()

        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let online = path.status == .satisfied
            Task { @MainActor in
                self.networkChanged(online: online)
            }
        }
        pathMonitor.start(queue: .main)

        // Never leave the launch mark up forever on a slow first load.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            self?.finishLaunch()
        }
    }

    // MARK: - Web view lifecycle

    /// Returns the app's web view, creating it (and starting the first load) on first use.
    func webViewForDisplay() -> WKWebView {
        if let webView {
            return webView
        }
        let created = ClaudeWebView.makeConfiguredWebView(coordinator: coordinator)
        webView = created
        // Follow the page's colour live, so the status bar strip matches claude.ai in light or dark.
        colorObservations = [
            created.observe(\.themeColor, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.updateTopBarColor() }
            },
            created.observe(\.underPageBackgroundColor, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.updateTopBarColor() }
            },
        ]
        let first = pendingURL ?? AllowedHosts.home
        pendingURL = nil
        load(first)
        return created
    }

    func load(_ url: URL) {
        guard let webView else {
            pendingURL = url
            return
        }
        lastRequestedURL = url
        webView.load(URLRequest(url: url))
    }

    /// `lykos://new` opens a new chat. Other lykos:// links just bring the app forward.
    func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "lykos" else { return }
        DebugLog.shared.add(.native, "Deep link: \(url.absoluteString)")
        switch url.host?.lowercased() {
        case "new"?:
            load(AllowedHosts.newChat)
        default:
            break
        }
    }

    func retry() {
        guard let webView else { return }
        isRetrying = true
        if hasCommittedPage, webView.url != nil {
            webView.reload()
        } else {
            load(lastRequestedURL ?? AllowedHosts.home)
        }
    }

    func refresh() {
        guard let webView else { return }
        if hasCommittedPage, webView.url != nil {
            webView.reload()
        } else {
            retry()
        }
    }

    func reloadAfterContentProcessCrash() {
        guard let webView else { return }
        if webView.url != nil {
            webView.reload()
        } else {
            load(lastRequestedURL ?? AllowedHosts.home)
        }
    }

    // MARK: - Events from WebCoordinator

    func mainFrameCommitted() {
        hasCommittedPage = true
        showOffline = false
        isRetrying = false
    }

    func mainFrameFinished() {
        showOffline = false
        isRetrying = false
        updateTopBarColor()
        finishLaunch()
    }

    func mainFrameFailed(_ error: Error, url: URL?) {
        isRetrying = false
        if Self.isCancellation(error) {
            return
        }
        DebugLog.shared.add(
            .native,
            "Load failed (\(url?.absoluteString ?? "no URL")): \(DebugText.describe(error))"
        )
        if Self.isNetworkError(error) {
            presentOffline("No connection right now.")
        } else if !hasCommittedPage {
            // Nothing on screen yet, so don't leave a black page behind.
            presentOffline("The page couldn't load.")
        }
    }

    // MARK: - Network

    private func networkChanged(online: Bool) {
        let wasOnline = isOnline
        isOnline = online
        if online != wasOnline {
            DebugLog.shared.add(.native, online ? "Network is back" : "Network lost")
        }
        if !online, !hasCommittedPage {
            presentOffline("No connection right now.")
        } else if online, showOffline, !isRetrying {
            retry()
        }
    }

    // MARK: - Helpers

    private func updateTopBarColor() {
        guard let webView else { return }
        if let color = webView.themeColor ?? webView.underPageBackgroundColor {
            topBarColor = Color(uiColor: color)
        }
    }

    private func presentOffline(_ message: String) {
        offlineMessage = message
        showOffline = true
        finishLaunch()
    }

    private func finishLaunch() {
        if !launchFinished {
            launchFinished = true
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain, ns.code == NSURLErrorCancelled { return true }
        // WebKit's "frame load interrupted": a navigation we cancelled or turned into a download.
        if ns.domain == "WebKitErrorDomain", ns.code == 102 { return true }
        return false
    }

    private static func isNetworkError(_ error: Error) -> Bool {
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return false }
        let offlineCodes: [URLError.Code] = [
            .notConnectedToInternet, .networkConnectionLost, .timedOut,
            .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
            .internationalRoamingOff, .dataNotAllowed, .callIsActive,
        ]
        return offlineCodes.contains(URLError.Code(rawValue: ns.code))
    }
}
