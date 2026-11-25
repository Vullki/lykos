import Foundation

/// iOS keeps a picture of each app's launch screen in the app's own `Library/SplashBoard` folder and
/// plays it while the app opens. Installing a new build over an old one doesn't always refresh that
/// picture, so after the icon change in build 6 the phone still opened with the old "Ly" for about two
/// seconds, then faded to the new "LY" when LaunchView took over. Deleting the folder makes iOS draw the
/// launch screen again from the current build the next time the app opens.
///
/// It runs once per installed build (version + build number), not on every launch, so an unchanged
/// build keeps its cached picture and opens as fast as before. The current launch can't be helped (the
/// picture has already been shown by the time any app code runs); the next one is right.
enum LaunchSnapshot {
    private static let clearedForBuildKey = "LaunchSnapshot.clearedForBuild"

    /// Returns a line for the debug log when it did something, nil when this build was already handled.
    static func clearIfBuildChanged() -> String? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let current = "\(version) (\(build))"

        let defaults = UserDefaults.standard
        guard defaults.string(forKey: clearedForBuildKey) != current else { return nil }
        defaults.set(current, forKey: clearedForBuildKey)

        let folder = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library/SplashBoard", isDirectory: true)
        guard FileManager.default.fileExists(atPath: folder.path) else {
            return "Launch snapshot: none cached for \(current)"
        }
        do {
            try FileManager.default.removeItem(at: folder)
            return "Launch snapshot: cleared for \(current), iOS redraws it on the next launch"
        } catch {
            return "Launch snapshot: couldn't clear for \(current): \(error.localizedDescription)"
        }
    }
}
