import SwiftUI

/// The hidden debug screen: console messages from claude.ai and native load errors, newest first,
/// shareable as plain text. Opened by a three-finger long press on the web view or a long press on
/// the offline screen.
struct DebugLogView: View {
    @ObservedObject var log: DebugLog
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false   // iOS 15 only; iOS 16+ uses ShareLink

    var body: some View {
        NoirNavigation {
            Group {
                if log.entries.isEmpty {
                    Text("No messages yet.")
                        .font(.system(size: 15))
                        .foregroundStyle(Noir.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(log.entries.reversed()) { entry in
                        EntryRow(entry: entry)
                            .listRowBackground(Noir.background)
                            .listRowSeparatorTint(Noir.deep)
                    }
                    .listStyle(.plain)
                    .modifier(HiddenListBackground())
                }
            }
            .background(Noir.background.ignoresSafeArea())
            .navigationTitle("Debug log")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(NoirNavigationBar())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { log.clear() }
                        .disabled(log.entries.isEmpty)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    shareButton
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Noir.text)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showShareSheet) {
            ActivitySheet(items: [log.exportText])
        }
    }

    @ViewBuilder private var shareButton: some View {
        if #available(iOS 16.0, *) {
            ShareLink(item: log.exportText) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share log")
        } else {
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share log")
        }
    }
}

// MARK: - iOS 15 fallbacks (the minimum is iOS 15 so TrollStore devices can run Lykos)

/// NavigationStack on iOS 16+, a stack-style NavigationView on iOS 15.
private struct NoirNavigation<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
                .navigationViewStyle(.stack)
        }
    }
}

/// Black navigation bar with light text on iOS 16+; iOS 15 keeps the system dark bar.
private struct NoirNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(Noir.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            content
        }
    }
}

/// Lets the black background show through the list on iOS 16+.
private struct HiddenListBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

/// The system share sheet, for iOS 15 where ShareLink doesn't exist.
private struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct EntryRow: View {
    let entry: DebugLog.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.label)
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(Noir.labelTracking(10))
                    .foregroundStyle(entry.level == .error ? Noir.text : Noir.label)
                Spacer()
                Text(entry.time)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Noir.muted)
            }
            Text(entry.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Noir.text)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}
