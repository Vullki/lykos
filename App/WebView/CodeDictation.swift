import WebKit

/// Brings back Claude's own dictation (the "Press and hold to record" mic) in claude.ai's Code tab with
/// the phone held upright.
///
/// claude.ai turns Code dictation off on a touch screen narrower than 600 points. It asks the browser
/// `matchMedia("(max-width: 599px)")` for that, and it's the only place in claude.ai's scripts that asks
/// exactly that question (checked 2026-11-25 across about 4,700 script files). An iPhone is about 400
/// points wide upright, so the mic disappears; on its side it's past 600 and the mic is back. The chat
/// tab has no such rule.
///
/// This script answers "no" to that one question and passes every other media query through untouched.
/// CSS media queries are not affected (they don't go through `matchMedia`), so the layout stays the
/// phone layout. The mic it brings back is claude.ai's own, using Anthropic's transcription, not Apple's.
/// If claude.ai renames the query, this simply stops matching and the app behaves like Safari again.
enum CodeDictation {
    static let source = """
    (function () {
      if (window.__lykosCodeDictation) { return; }
      if (!/(^|\\.)claude\\.ai$/.test(location.hostname)) { return; }
      var original = window.matchMedia;
      if (typeof original !== 'function' || typeof Proxy !== 'function') { return; }
      window.__lykosCodeDictation = true;
      var target = '(max-width: 599px)';
      var logged = false;
      window.matchMedia = function (query) {
        var list = original.call(window, query);
        if (String(query).replace(/\\s+/g, ' ').trim() !== target) { return list; }
        if (!logged) { logged = true; try { console.log('Lykos: Code tab dictation width check answered as wide'); } catch (e) {} }
        return new Proxy(list, {
          get: function (t, p) {
            if (p === 'matches') { return false; }
            var v = t[p];
            return typeof v === 'function' ? v.bind(t) : v;
          },
          set: function (t, p, v) { t[p] = v; return true; }
        });
      };
    })();
    """

    static var userScript: WKUserScript {
        WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
