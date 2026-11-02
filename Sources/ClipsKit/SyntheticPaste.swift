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
        }

        if let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            up.flags = []
            up.setIntegerValueField(.eventSourceUserData, value: marker)
            up.post(tap: .cgSessionEventTap)
        }
    }

    /// Determines whether the specified application currently has an active text input or editable destination.
    /// This prevents simulated paste keystrokes from firing into applications that do not have an active text focus
    /// (such as Finder on the Desktop or in a folder window, which creates unwanted .textClipping documents).
    public static func hasActiveTextInput(pid: pid_t?, bundleIdentifier: String?) -> Bool {
        guard let pid, pid > 0 else { return false }
        guard isAccessibilityGranted else { return false }

        let bundleID = (bundleIdentifier ?? "").lowercased()
        let isFinder = bundleID == "com.apple.finder"

        let appElement = AXUIElementCreateApplication(pid)
        var focusedRef: AnyObject?
        let err = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef)

        guard err == .success, let focusedElement = focusedRef else {
            // If it is a known terminal emulator with an open window, it accepts paste commands
            if isTerminalApp(bundleID: bundleID) {
                var windowRef: AnyObject?
                if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success, windowRef != nil {
                    return true
                }
            }
            return false
        }

        guard CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return false
        }
        let axElement = focusedElement as! AXUIElement

        var roleRef: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String

        // Standard text input roles in macOS
        let textInputRoles: Set<String> = [
            kAXTextFieldRole as String,        // "AXTextField" (also includes search & secure fields)
            kAXTextAreaRole as String,         // "AXTextArea"
            kAXComboBoxRole as String,         // "AXComboBox"
            "AXSearchField"
        ]

        if let role, textInputRoles.contains(role) {
            // In Finder, only allow text input if it is an explicit text field
            // (e.g. inline file/folder renaming or search field).
            // A regular window or desktop list must NEVER receive Cmd+V because Finder
            // generates a .textClipping file on disk.
            if isFinder {
                return role == (kAXTextFieldRole as String) || role == "AXSearchField"
            }
            return true
        }

        // In Finder, if the focused element is not an explicit text field, it is NOT an active input.
        if isFinder {
            return false
        }

        // Terminal emulators accept input on the terminal screen
        if isTerminalApp(bundleID: bundleID) {
            return true
        }

        // Rich web / contenteditable fields (e.g. WebKit or Chromium)
        var subroleRef: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXSubroleAttribute as CFString, &subroleRef)
        if let subrole = subroleRef as? String, subrole.contains("AXContentEditable") {
            return true
        }

        var rangeSettable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(axElement, "AXSelectedTextRange" as CFString, &rangeSettable) == .success, rangeSettable.boolValue {
            return true
        }

        var valueSettable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(axElement, kAXValueAttribute as CFString, &valueSettable) == .success, valueSettable.boolValue {
            return true
        }

        return false
    }

    public static func isTerminalApp(bundleID: String) -> Bool {
        let id = bundleID.lowercased()
        let terminals: Set<String> = [
            "com.apple.terminal",
            "com.googlecode.iterm2",
            "org.alacritty",
            "com.mitchellh.ghostty",
            "net.kovidgoyal.kitty",
            "com.github.wez.wezterm",
            "co.zeit.hyper",
            "dev.warp.warp-stable"
        ]
        if terminals.contains(id) { return true }
        return id.contains("terminal") || id.contains("iterm")
    }
}
