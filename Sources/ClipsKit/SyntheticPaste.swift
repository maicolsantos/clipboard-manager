import Foundation
import ApplicationServices

public enum SyntheticPaste {
    public static let marker: Int64 = 0x434C_4950   // "CLIP"

    public static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    public static func requestAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    public static let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    public static func postPasteCommand() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        source.userData = marker
        let vKeyCode: CGKeyCode = 0x09 // kVK_ANSI_V

        if let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            down.flags = .maskCommand
            down.setIntegerValueField(.eventSourceUserData, value: marker)
            down.post(tap: .cgSessionEventTap)
            down.post(tap: .cghidEventTap)
        }

        if let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            up.flags = []
            up.setIntegerValueField(.eventSourceUserData, value: marker)
            up.post(tap: .cgSessionEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}
