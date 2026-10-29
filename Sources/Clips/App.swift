import AppKit
import SwiftData
import SwiftUI
import ClipsKit

// Clips: Modern macOS clipboard manager
//   Clips                      the app
//   APP_STORE=<file> Clips     use another database (tests, experiments)
//   Clips --selftest           run the self-test and quit with 0 or 1 (tools/selftest.sh)

@main
struct ClipsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel(container: Store.makeContainer())
    @State private var history = ClipboardHistory.shared

    var body: some Scene {
        MenuBarExtra("Clips", systemImage: "clipboard") {
            Button("Open Clips (⌘⇧V)") {
                FloatingPanelController.shared.toggle()
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])

            Button("All Clips (⌘<)") {
                history.filterFavoritesOnly = false
                FloatingPanelController.shared.show()
            }

            Button("Favorites (⌘1)") {
                history.filterFavoritesOnly = true
                FloatingPanelController.shared.show()
            }
            .keyboardShortcut("1", modifiers: [.command])

            Divider()

            Button("Clear Non-Favorites") {
                history.clear()
            }

            Divider()

            Button("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",")

            Divider()

            Button("Quit Clips") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
                .environment(model)
                .themed()
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory utility so it doesn't take dock space
        if !SelfTest.requested {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }

        FloatingPanelController.shared.setup()
        ClipboardHistory.shared.startMonitoring()

        HotkeyCenter.shared.onTrigger = {
            FloatingPanelController.shared.toggle()
        }
        HotkeyCenter.shared.register()

        // Run self-test if requested
        let model = AppModel(container: Store.makeContainer())
        SelfTest.runIfRequested(model: model)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        if SelfTest.requested { exit(SelfTest.exitCode) }
    }
}

/// Where the data lives: ~/Library/Application Support/Clips/Clips.store
enum Store {
    static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }

    static var url: URL {
        if let custom = ProcessInfo.processInfo.environment["APP_STORE"], !custom.isEmpty {
            return URL(fileURLWithPath: custom)
        }
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Clips")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Clips.store")
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, url: url)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("Failed to load store: \(error)")
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [memory]))!
        }
    }
}
