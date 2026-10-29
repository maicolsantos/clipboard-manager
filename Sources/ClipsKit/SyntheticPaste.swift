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
        let source = CGEventSource(stateID: .privateState)
        source?.userData = marker
        // 0x09 is kVK_ANSI_V
        for down in [true, false] {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: down) {
                event.flags = .maskCommand
                event.setIntegerValueField(.eventSourceUserData, value: marker)
                event.post(tap: .cgSessionEventTap)
            }
        }
    }
}
