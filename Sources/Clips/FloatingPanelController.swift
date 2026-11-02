import AppKit
import Carbon.HIToolbox
import SwiftUI
import ClipsKit

final class ClipboardFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        FloatingPanelController.shared.hide()
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if handleKeyDown(event) {
                return
            }
        }
        super.sendEvent(event)
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        // If the label dialog or delete confirmation is open, let the dialog handle keys (Esc cancels dialog)
        if ClipboardHistory.shared.editingLabelItem != nil || ClipboardHistory.shared.deletingConfirmationItem != nil {
            if event.keyCode == 53 { // Escape
                ClipboardHistory.shared.editingLabelItem = nil
                ClipboardHistory.shared.deletingConfirmationItem = nil
                return true
            }
            return false
        }

        let shortcuts = ShortcutStore.shared

        // 1. Close: Configured shortcut or Escape
        if shortcuts.close.matches(event: event) || (shortcuts.close.isEmpty && event.keyCode == 53) {
            FloatingPanelController.shared.hide()
            return true
        }

        // 2. Switch to Favorites
        if shortcuts.favorites.matches(event: event) {
            ClipboardHistory.shared.filterFavoritesOnly = true
            ClipboardHistory.shared.selectFirstItem()
            return true
        }

        // 3. Switch to All
        if shortcuts.allClips.matches(event: event) {
            ClipboardHistory.shared.filterFavoritesOnly = false
            ClipboardHistory.shared.selectFirstItem()
            return true
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Cmd + ,: Open Settings
        if flags.contains(.command) && ((event.keyCode == UInt16(kVK_ANSI_Comma) && !flags.contains(.shift)) || event.charactersIgnoringModifiers == ",") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            return true
        }

        // 4. Up Arrow: Move selection up
        if event.keyCode == 126 { // kVK_UpArrow
            ClipboardHistory.shared.moveSelection(delta: -1)
            return true
        }

        // 5. Down Arrow: Move selection down
        if event.keyCode == 125 { // kVK_DownArrow
            ClipboardHistory.shared.moveSelection(delta: 1)
            return true
        }

        // 6. Enter / Return: Paste selected item immediately
        if shortcuts.paste.matches(event: event) {
            ClipboardHistory.shared.pasteCurrentSelectedItem()
            return true
        }

        // 7. Quick Paste 1..9 (when search is empty and no command/control/option modifiers)
        if flags.isDisjoint(with: [.command, .control, .option]) {
            if let chars = event.characters,
               let digit = Int(chars),
               (1...9).contains(digit) {
                if ClipboardHistory.shared.searchText.isEmpty {
                    let items = ClipboardHistory.shared.filteredItems
                    let index = digit - 1
                    if index < items.count {
                        ClipboardHistory.shared.pasteItem(items[index])
                        return true
                    }
                }
            }
        }

        return false
    }
}

@MainActor
final class FloatingPanelController: NSObject {
    static let shared = FloatingPanelController()

    private(set) var panel: ClipboardFloatingPanel?
    private(set) var previousApp: NSRunningApplication?
    private(set) var previousAppHadActiveInput: Bool = false
    private var globalKeyMonitor: Any?
    private var globalMouseMonitor: Any?

    private override init() {
        super.init()
    }

    func setup() {
        guard panel == nil else { return }

        let contentView = ClipsView()
        let hostingView = NSHostingView(rootView: contentView)

        let p = ClipboardFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 440),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.isFloatingPanel = true
        p.level = .popUpMenu // Always on top of everything
        p.hidesOnDeactivate = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.contentView = hostingView

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: p
        )

        self.panel = p
    }

    func toggle() {
        guard let p = panel else {
            setup()
            toggle()
            return
        }

        if p.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        // Record frontmost application before Clips activates.
        // For Finder specifically, also check whether a text field is active so we
        // can avoid firing Cmd+V into a folder window (which would create a .textClipping).
        // For all other apps we skip the AX check — it would fail anyway once the
        // panel steals focus, and non-Finder apps handle Cmd+V safely on their own.
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = frontApp
            let isFinder = frontApp.bundleIdentifier?.lowercased() == "com.apple.finder"
            self.previousAppHadActiveInput = isFinder
                ? SyntheticPaste.hasActiveTextInput(
                    pid: frontApp.processIdentifier,
                    bundleIdentifier: frontApp.bundleIdentifier)
                : true  // Non-Finder apps always accept paste
        }

        guard let p = panel else {
            setup()
            show()
            return
        }

        // Reset search and selection on open
        ClipboardHistory.shared.searchText = ""
        ClipboardHistory.shared.selectFirstItem()

        // Position in the top 20% of screen containing mouse
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - (p.frame.width / 2)
        let y = screenFrame.maxY - (p.frame.height) - (screenFrame.height * 0.12)

        p.setFrameOrigin(NSPoint(x: x, y: y))
        p.orderFrontRegardless()
        p.makeKey()
        NSApp.activate(ignoringOtherApps: true)

        startGlobalMonitors()
    }

    func hide() {
        stopGlobalMonitors()
        panel?.orderOut(nil)
    }

    @objc private func panelDidResignKey(_ notification: Notification) {
        if ClipboardHistory.shared.editingLabelItem != nil || ClipboardHistory.shared.deletingConfirmationItem != nil {
            return
        }
        hide()
    }

    private func startGlobalMonitors() {
        stopGlobalMonitors()

        // Hide when clicking anywhere outside the window
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }

        // Hide when Escape is pressed
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor in
                    self?.hide()
                }
            }
        }
    }

    private func stopGlobalMonitors() {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }
}
