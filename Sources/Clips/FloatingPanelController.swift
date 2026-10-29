import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: NSObject {
    static let shared = FloatingPanelController()

    private var panel: NSPanel?

    private override init() {
        super.init()
    }

    func setup() {
        guard panel == nil else { return }

        let contentView = ClipsView()
        let hostingView = NSHostingView(rootView: contentView)

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 440),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.level = .floating
        p.hidesOnDeactivate = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        p.contentView = hostingView

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
        guard let p = panel else {
            setup()
            show()
            return
        }

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
    }

    func hide() {
        panel?.orderOut(nil)
    }
}
