import SwiftUI
import UIKit
import WebKit

enum WebViewSettings {
    /// User-agent switch. `nil` keeps WebKit's own user agent. If claude.ai ever treats the web view
    /// as an unknown browser ("get the app" banners, odd layout), set this to something like
    /// "Version/26.0 Mobile/15E148 Safari/604.1" so it reads as Mobile Safari.
    static let applicationNameForUserAgent: String? = nil
}

/// The full-screen claude.ai web view. The `WKWebView` itself is created once and owned by
/// `WebViewStore`, so SwiftUI updates never tear down a loaded page.
struct ClaudeWebView: UIViewRepresentable {
    let store: WebViewStore

    func makeUIView(context: Context) -> WKWebView {
        store.webViewForDisplay()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    /// Builds the one web view the app uses.
    @MainActor
    static func makeConfiguredWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Persistent store: cookies and local storage survive app restarts, so the login sticks.
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        if let applicationName = WebViewSettings.applicationNameForUserAgent {
            configuration.applicationNameForUserAgent = applicationName
        }

        let contentController = WKUserContentController()
        contentController.addUserScript(WKUserScript(
            source: ConsoleMessageHandler.source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        contentController.add(ConsoleMessageHandler(), name: ConsoleMessageHandler.name)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.allowsBackForwardNavigationGestures = true
        // No Safari-style preview popup on a long-pressed link: one of the biggest "this is a website" tells.
        webView.allowsLinkPreview = false
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // Black behind the page, so nothing white shows before claude.ai paints.
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(white: 0xC2 / 255.0, alpha: 1)
        refreshControl.addTarget(coordinator, action: #selector(WebCoordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        // Three-finger long press opens the debug log. It never blocks the page's own touches.
        let debugPress = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(WebCoordinator.handleDebugGesture(_:))
        )
        debugPress.numberOfTouchesRequired = 3
        debugPress.minimumPressDuration = 0.8
        debugPress.cancelsTouchesInView = false
        debugPress.delegate = coordinator
        webView.addGestureRecognizer(debugPress)

        return webView
    }
}
