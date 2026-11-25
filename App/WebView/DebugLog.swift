import Foundation
import os
import UIKit
import WebKit

/// Collects console messages from claude.ai and native load errors, for the hidden debug screen.
/// There's no Web Inspector or Xcode console on Windows, so this is how problems on the phone get seen.
/// Entries also go to the unified log (subsystem `com.vullki.lykos`), so `idevicesyslog` shows them.
@MainActor
final class DebugLog: ObservableObject {
    enum Level: String {
        case log, warn, error, native

        var label: String { rawValue.uppercased() }
    }

    struct Entry: Identifiable {
        let id = UUID()
        let time: String
        let level: Level
        let message: String
    }

    static let shared = DebugLog()

    @Published private(set) var entries: [Entry] = []

    private let maxEntries = 500
    private let maxMessageLength = 4000
    private let logger = Logger(subsystem: "com.vullki.lykos", category: "debug")
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private init() {}

    func add(_ level: Level, _ message: String) {
        let text = message.count > maxMessageLength
            ? String(message.prefix(maxMessageLength)) + " …"
            : message
        entries.append(Entry(time: timeFormatter.string(from: Date()), level: level, message: text))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        logger.log("[\(level.rawValue, privacy: .public)] \(text, privacy: .public)")
    }

    func clear() {
        entries.removeAll()
    }

    /// The whole log as plain text, oldest first, for the share sheet.
    var exportText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        var lines = [
            "Lykos debug log",
            "App \(version) (\(build)), iOS \(UIDevice.current.systemVersion)",
            "Exported \(ISO8601DateFormatter().string(from: Date()))",
            "",
        ]
        lines += entries.map { "\($0.time) [\($0.level.label)] \($0.message)" }
        return lines.joined(separator: "\n")
    }
}

/// Receives the messages the console bridge script posts and adds them to `DebugLog`.
/// The script below is the only JavaScript Lykos injects into claude.ai. It wraps
/// `console.log/warn/error` and listens for uncaught errors; it changes nothing on the page.
@MainActor
final class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
    static let name = "lykosLog"

    static let source = """
    (function () {
      var h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.lykosLog;
      if (!h || window.__lykosLog) { return; }
      window.__lykosLog = true;
      function send(l, m) { try { h.postMessage({ l: l, m: String(m).slice(0, 4000) }); } catch (e) {} }
      function text(args) {
        return Array.prototype.map.call(args, function (a) {
          if (a instanceof Error) { return a.stack || String(a); }
          if (a !== null && typeof a === 'object') { try { return JSON.stringify(a); } catch (e) {} }
          return String(a);
        }).join(' ');
      }
      ['log', 'warn', 'error'].forEach(function (l) {
        var original = console[l];
        console[l] = function () {
          try { send(l, text(arguments)); } catch (e) {}
          return original.apply(console, arguments);
        };
      });
      window.addEventListener('error', function (e) {
        send('error', 'Uncaught ' + e.message + ' (' + e.filename + ':' + e.lineno + ':' + e.colno + ')');
      });
      window.addEventListener('unhandledrejection', function (e) {
        var r = e.reason;
        send('error', 'Unhandled rejection: ' + (r && r.stack ? r.stack : String(r)));
      });
    })();
    """

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any] else { return }
        let text = body["m"] as? String ?? ""
        let level: DebugLog.Level
        switch body["l"] as? String {
        case "warn"?: level = .warn
        case "error"?: level = .error
        default: level = .log
        }
        DebugLog.shared.add(level, text)
    }
}
