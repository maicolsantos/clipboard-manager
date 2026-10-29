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
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
        MenuBarExtra("Clips", systemImage: "clipboard") {
            MenuBarMenu(model: model)
        }

        Settings {
            SettingsView()
                .environment(model)
                .themed()
        }
        .windowResizability(.contentSize)
    }
}

struct MenuBarMenu: View {
    @Bindable var model: AppModel
    @State private var history = ClipboardHistory.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(L10n.tr(.openClips)) {
            FloatingPanelController.shared.toggle()
        }
        .keyboardShortcut("v", modifiers: [.command, .shift])

        Button(L10n.tr(.allClipsMenu)) {
            history.filterFavoritesOnly = false
            FloatingPanelController.shared.show()
        }

        Button(L10n.tr(.favoritesMenu)) {
            history.filterFavoritesOnly = true
            FloatingPanelController.shared.show()
        }
        .keyboardShortcut("1", modifiers: [.command])

        Divider()

        Button(L10n.tr(.clearNonFavorites)) {
            history.clear()
        }

        Divider()

        Button(L10n.tr(.settings)) {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button(L10n.tr(.quit)) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("Clips")
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
