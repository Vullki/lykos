import Foundation

/// Which URLs stay inside the app. Main-frame navigation stays in-app only for claude.ai and its
/// subdomains; everything else is handed to iOS (Safari, Mail, Phone, ...).
enum AllowedHosts {
    static let rootDomain = "claude.ai"
    static let home = URL(string: "https://claude.ai/")!
    static let newChat = URL(string: "https://claude.ai/new")!

    enum Route {
        /// Load it in the web view.
        case inApp
        /// Cancel it in the web view and open it with `UIApplication.shared.open`.
        case external
        /// Cancel it and do nothing (no usable URL).
        case blocked
    }

    /// True for `claude.ai` and any subdomain of it (`www.claude.ai`, `a.b.claude.ai`).
    /// `notclaude.ai` and `claude.ai.example.com` are not allowed.
    static func isAllowedHost(_ host: String?) -> Bool {
        guard var host = host?.lowercased(), !host.isEmpty else { return false }
        if host.hasSuffix(".") { host.removeLast() }
        return host == rootDomain || host.hasSuffix("." + rootDomain)
    }

    /// The route for a main-frame (or new-window) navigation. Subframes are never routed here.
    static func mainFrameRoute(for url: URL) -> Route {
        switch url.scheme?.lowercased() {
        case "https"?, "http"?:
            return isAllowedHost(url.host) ? .inApp : .external
        case "about"?, "blob"?, "data"?:
            // about:blank and page-generated content. Real downloads are caught by the
            // navigation and response policies before they get here.
            return .inApp
        case .none:
            return .blocked
        default:
            // mailto:, tel:, sms:, itms-apps:, maps: and other apps' schemes.
            return .external
        }
    }
}
