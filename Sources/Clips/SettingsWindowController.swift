import AppKit
import SwiftUI
import ClipsKit

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var model: AppModel?

    private override init() {
        super.init()
    }

    func show(model: AppModel? = nil) {
        if let model {
            self.model = model
        }

        NSApp.activate(ignoringOtherApps: true)

        // 1. If window already exists, bring it to front
        if let w = window {
            if !w.isVisible {
                w.center()
            }
            w.level = .floating
            w.orderFrontRegardless()
            w.makeKeyAndOrderFront(nil)
            return
        }

        // 2. Otherwise create a dedicated Settings window
        let appModel = self.model ?? AppModel(container: Store.makeContainer())
        self.model = appModel

        let settingsView = SettingsView()
            .environment(appModel)
            .themed()

        let hostingView = NSHostingView(rootView: settingsView)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = L10n.tr(.settings).replacingOccurrences(of: "...", with: "")
        w.isReleasedWhenClosed = false
        w.center()
        w.contentView = hostingView
        w.level = .floating
        w.delegate = self
        w.orderFrontRegardless()
        w.makeKeyAndOrderFront(nil)

        self.window = w
    }

    func windowWillClose(_ notification: Notification) {
        // Window closed - kept alive via isReleasedWhenClosed = false for next reopen
    }
}
