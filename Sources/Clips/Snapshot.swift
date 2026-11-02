import AppKit
import SwiftUI
import ClipsKit

/// Screenshot mode for agents.
///   APP_STORE=/tmp/test.store APP_SNAPSHOT=/tmp/shots /Applications/Clips.app/Contents/MacOS/Clips
/// writes clips-light.png and clips-dark.png, and
/// settings-<tab>-light.png and settings-<tab>-dark.png for every Settings tab, then quits.
@MainActor
enum Snapshot {
    static func runIfRequested(model: AppModel) {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["APP_SNAPSHOT"], !dir.isEmpty else { return }
        // Snapshots never run against the real database.
        guard Store.isOverridden else {
            print("SNAPSHOT refused: set APP_STORE to a file in /tmp")
            NSApp.terminate(nil)
            return
        }

        Task {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? await Task.sleep(for: .milliseconds(300))

            let history = ClipboardHistory.shared
            if history.items.isEmpty {
                history.items = [
                    ClipItem(kind: .text, textContent: "https://apple.com/macos", isFavorite: true, sourceAppName: "Safari"),
                    ClipItem(kind: .text, textContent: "swift build -c release", isFavorite: false, sourceAppName: "Terminal"),
                    ClipItem(kind: .text, textContent: "Colors.palette.accent", isFavorite: false, sourceAppName: "Xcode")
                ]
                history.selectFirstItem()
            }

            for mode in ["light", "dark"] {
                let appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
                NSApp.appearance = appearance

                // 1. Capture Settings tabs
                for tab in SettingsTab.allCases {
                    model.settingsTab = tab
                    let settingsView = SettingsView().environment(model).themed()
                    let hosting = NSHostingView(rootView: settingsView)
                    hosting.appearance = appearance
                    hosting.frame = NSRect(x: 0, y: 0, width: 520, height: 420)
                    hosting.layoutSubtreeIfNeeded()

                    captureView(hosting, to: "\(dir)/settings-\(tab.rawValue)-\(mode).png")
                }

                // 2. Capture Clips floating panel
                let clipsView = ClipsView().environment(history).themed()
                let panelHosting = NSHostingView(rootView: clipsView)
                panelHosting.appearance = appearance
                panelHosting.frame = NSRect(x: 0, y: 0, width: 700, height: 440)
                panelHosting.layoutSubtreeIfNeeded()

                captureView(panelHosting, to: "\(dir)/clips-\(mode).png")
            }

            print("SNAPSHOT done \(dir)")
            NSApp.terminate(nil)
        }
    }

    private static func captureView(_ view: NSView, to path: String) {
        try? FileManager.default.removeItem(atPath: path)
        if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            if let data = rep.representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: path))
                print("SNAPSHOT \(path)")
            }
        }
    }
}
