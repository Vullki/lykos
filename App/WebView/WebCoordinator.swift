import UIKit
import WebKit

/// The web view's navigation, UI, download and gesture delegate.
/// Owned by `WebViewStore`, so it lives as long as the web view does.
@MainActor
final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, UIGestureRecognizerDelegate {
    weak var store: WebViewStore?

    /// Where each running download is being written.
    private var downloadDestinations: [WKDownload: URL] = [:]

    init(store: WebViewStore) {
        self.store = store
        super.init()
    }

    // MARK: - Navigation policy

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // <a download>, blob: links and similar, in any frame.
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }
        // New-window requests (target=_blank, window.open) are routed in createWebViewWith.
        guard let targetFrame = navigationAction.targetFrame else {
            decisionHandler(.allow)
            return
        }
        // Subframes (artifacts, Cloudflare challenges, embeds) are never blocked.
        guard targetFrame.isMainFrame else {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        switch AllowedHosts.mainFrameRoute(for: url) {
        case .inApp:
            decisionHandler(.allow)
        case .external:
            decisionHandler(.cancel)
            openExternally(url)
        case .blocked:
            decisionHandler(.cancel)
            DebugLog.shared.add(.native, "Blocked navigation without a scheme: \(url.absoluteString)")
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        let http = navigationResponse.response as? HTTPURLResponse
        if navigationResponse.isForMainFrame, let http, http.statusCode >= 400 {
            let url = http.url?.absoluteString ?? "?"
            DebugLog.shared.add(.native, "HTTP \(http.statusCode) for \(url)")
        }
        // Files the web view can't show, or that the server marks as attachments, become downloads.
        let disposition = http?.value(forHTTPHeaderField: "Content-Disposition")?.lowercased() ?? ""
        if !navigationResponse.canShowMIMEType || disposition.hasPrefix("attachment") {
            decisionHandler(.download)
            return
        }
        decisionHandler(.allow)
    }

    // MARK: - Navigation progress (main frame only)

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
        store?.mainFrameCommitted()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
        store?.mainFrameFinished()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        store?.mainFrameFailed(error, url: webView.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        store?.mainFrameFailed(error, url: webView.url)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DebugLog.shared.add(.native, "Web content process terminated, reloading")
        store?.reloadAfterContentProcessCrash()
    }

    // MARK: - Downloads

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        do {
            let folder = DownloadFiles.root.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appendingPathComponent(
                DownloadFiles.safeName(suggestedFilename),
                isDirectory: false
            )
            downloadDestinations[download] = destination
            DebugLog.shared.add(.native, "Download started: \(destination.lastPathComponent)")
            completionHandler(destination)
        } catch {
            DebugLog.shared.add(.native, "Download folder error: \(error.localizedDescription)")
            completionHandler(nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let fileURL = downloadDestinations.removeValue(forKey: download) else { return }
        DebugLog.shared.add(.native, "Download finished: \(fileURL.lastPathComponent)")
        presentShareSheet(for: fileURL)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let name = downloadDestinations.removeValue(forKey: download)?.lastPathComponent ?? "file"
        DebugLog.shared.add(.native, "Download failed (\(name)): \(DebugText.describe(error))")
    }

    // MARK: - New windows (target=_blank, window.open)

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url,
              !url.absoluteString.isEmpty,
              url.absoluteString != "about:blank" else {
            DebugLog.shared.add(.native, "Ignored a new-window request without a URL")
            return nil
        }
        let scheme = url.scheme?.lowercased()
        if navigationAction.shouldPerformDownload || scheme == "blob" || scheme == "data" {
            DebugLog.shared.add(.native, "New-window request turned into a download")
            webView.startDownload(using: navigationAction.request) { [weak self] download in
                download.delegate = self
            }
            return nil
        }
        // Same host rule as main-frame navigation: claude.ai loads in place, the rest leaves the app.
        switch AllowedHosts.mainFrameRoute(for: url) {
        case .inApp:
            webView.load(navigationAction.request)
        case .external:
            openExternally(url)
        case .blocked:
            DebugLog.shared.add(.native, "Blocked new window without a scheme: \(url.absoluteString)")
        }
        return nil
    }

    // MARK: - Microphone and camera

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        let isClaude = origin.`protocol`.lowercased() == "https" && AllowedHosts.isAllowedHost(origin.host)
        if isClaude {
            // iOS still asks for microphone/camera access itself the first time.
            decisionHandler(.grant)
        } else {
            DebugLog.shared.add(
                .native,
                "Denied \(Self.name(of: type)) for \(origin.`protocol`)://\(origin.host)"
            )
            decisionHandler(.deny)
        }
    }

    // MARK: - JavaScript alert / confirm / prompt

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard let presenter = topViewController(for: webView) else {
            completionHandler()
            return
        }
        let alert = UIAlertController(title: frame.securityOrigin.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let presenter = topViewController(for: webView) else {
            completionHandler(false)
            return
        }
        let alert = UIAlertController(title: frame.securityOrigin.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let presenter = topViewController(for: webView) else {
            completionHandler(nil)
            return
        }
        let alert = UIAlertController(title: frame.securityOrigin.host, message: prompt, preferredStyle: .alert)
        alert.addTextField { field in field.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text ?? "")
        })
        presenter.present(alert, animated: true)
    }

    // MARK: - Pull to refresh and the debug gesture

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        store?.refresh()
    }

    @objc func handleDebugGesture(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        store?.showDebugLog = true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    // MARK: - Helpers

    private func openExternally(_ url: URL) {
        DebugLog.shared.add(.native, "Opened outside the app: \(url.absoluteString)")
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func presentShareSheet(for fileURL: URL) {
        guard let webView = store?.webView, let presenter = topViewController(for: webView) else {
            DebugLog.shared.add(.native, "No screen to show the share sheet on")
            return
        }
        let sheet = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        sheet.completionWithItemsHandler = { _, _, _, _ in
            // The file's own folder: shared or saved by now, so the temporary copy can go.
            try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        }
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = webView
            popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 1, height: 1)
        }
        presenter.present(sheet, animated: true)
    }

    private func topViewController(for view: UIView) -> UIViewController? {
        var top = view.window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    private static func name(of type: WKMediaCaptureType) -> String {
        switch type {
        case .camera: return "camera"
        case .microphone: return "microphone"
        case .cameraAndMicrophone: return "camera and microphone"
        @unknown default: return "media capture"
        }
    }
}

/// Temporary files for downloads. Each download gets its own folder, removed after the share sheet
/// closes; anything left over is cleared on the next launch.
enum DownloadFiles {
    static var root: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Downloads", isDirectory: true)
    }

    static func safeName(_ suggested: String) -> String {
        let cleaned = suggested
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty || cleaned == "." || cleaned == ".." ? "download" : cleaned
    }

    static func clearLeftovers() {
        try? FileManager.default.removeItem(at: root)
    }
}

/// Short error descriptions for the debug log.
enum DebugText {
    static func describe(_ error: Error) -> String {
        let ns = error as NSError
        return "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
    }
}
