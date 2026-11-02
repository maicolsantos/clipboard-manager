import AppKit
import Carbon.HIToolbox
import Foundation

/// A keyboard shortcut combination consisting of a virtual key code, modifier flags, and display representation.
public struct KeyCombo: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt16
    public var modifiers: UInt
    public var keyDisplay: String

    public static let empty = KeyCombo(keyCode: 0, modifiers: 0, keyDisplay: "")

    public init(keyCode: UInt16, modifiers: UInt, keyDisplay: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyDisplay = keyDisplay
    }

    public init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, keyDisplay: String) {
        self.keyCode = keyCode
        let relevant = modifierFlags.intersection([.command, .shift, .option, .control])
        self.modifiers = relevant.rawValue
        self.keyDisplay = keyDisplay
    }

    public init(event: NSEvent) {
        self.keyCode = event.keyCode
        var flags = event.modifierFlags.intersection([.command, .shift, .option, .control])

        let code = event.keyCode
        switch code {
        case 53:
            self.keyDisplay = "Esc"
        case 36, 76:
            self.keyDisplay = "↩"
        case 48:
            self.keyDisplay = "⇥"
        case 49:
            self.keyDisplay = "Space"
        case 51:
            self.keyDisplay = "⌫"
        case 117:
            self.keyDisplay = "⌦"
        case 123:
            self.keyDisplay = "←"
        case 124:
            self.keyDisplay = "→"
        case 125:
            self.keyDisplay = "↓"
        case 126:
            self.keyDisplay = "↑"
        case 122:
            self.keyDisplay = "F1"
        case 120:
            self.keyDisplay = "F2"
        case 99:
            self.keyDisplay = "F3"
        case 118:
            self.keyDisplay = "F4"
        case 96:
            self.keyDisplay = "F5"
        case 97:
            self.keyDisplay = "F6"
        case 98:
            self.keyDisplay = "F7"
        case 100:
            self.keyDisplay = "F8"
        case 101:
            self.keyDisplay = "F9"
        case 109:
            self.keyDisplay = "F10"
        case 103:
            self.keyDisplay = "F11"
        case 111:
            self.keyDisplay = "F12"
        case 10:
            self.keyDisplay = "<"
        default:
            if event.characters?.contains("<") == true || event.charactersIgnoringModifiers?.contains("<") == true {
                self.keyDisplay = "<"
                flags.remove(.shift)
            } else if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                self.keyDisplay = chars.uppercased()
            } else if let chars = event.characters, !chars.isEmpty {
                self.keyDisplay = chars.uppercased()
            } else {
                self.keyDisplay = "?"
            }
        }
        self.modifiers = flags.rawValue
    }

    public var isEmpty: Bool {
        keyDisplay.isEmpty && keyCode == 0 && modifiers == 0
    }

    public var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    public var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        let flags = modifierFlags
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }

    public var displayString: String {
        guard !isEmpty else { return "" }
        var result = ""
        let flags = modifierFlags
        if flags.contains(.command) { result += "⌘" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.shift) { result += "⇧" }
        result += keyDisplay
        return result
    }

    public func matches(event: NSEvent) -> Bool {
        guard !isEmpty else { return false }
        let eventMods = event.modifierFlags.intersection([.command, .shift, .option, .control])

        // Special handling for '<' (can be typed with ISO Section key 10 or Shift+Comma on US layout)
        if keyDisplay == "<" {
            let matchesCmd = eventMods.contains(.command)
            let isAngleBracket = event.characters?.contains("<") == true
                || event.charactersIgnoringModifiers?.contains("<") == true
                || event.keyCode == 10
                || (event.keyCode == UInt16(kVK_ANSI_Comma) && eventMods.contains(.shift))
            return matchesCmd && isAngleBracket
        }

        // Return key matches both Return (36) and Keypad Enter (76)
        if keyCode == 36 || keyCode == 76 {
            let isReturnKey = event.keyCode == 36 || event.keyCode == 76
            return isReturnKey && eventMods.rawValue == modifierFlags.rawValue
        }

        // Escape matches keyCode 53
        if keyCode == 53 {
            return event.keyCode == 53 && eventMods.rawValue == modifierFlags.rawValue
        }

        // Generic matching by keycode and modifiers, or characters ignoring modifiers
        if eventMods.rawValue != modifierFlags.rawValue {
            return false
        }

        if event.keyCode == keyCode {
            return true
        }

        if let chars = event.charactersIgnoringModifiers?.uppercased(), chars == keyDisplay {
            return true
        }

        return false
    }
}

/// Identifiers for customizable keyboard shortcuts in Clips.
public enum ShortcutAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case openClips
    case allClips
    case favorites
    case paste
    case close

    public var id: String { rawValue }

    public var defaultCombo: KeyCombo {
        switch self {
        case .openClips:
            return KeyCombo(keyCode: UInt16(kVK_ANSI_V), modifierFlags: [.command, .shift], keyDisplay: "V")
        case .allClips:
            return KeyCombo(keyCode: 10, modifierFlags: [.command], keyDisplay: "<")
        case .favorites:
            return KeyCombo(keyCode: UInt16(kVK_ANSI_1), modifierFlags: [.command], keyDisplay: "1")
        case .paste:
            return KeyCombo(keyCode: UInt16(kVK_Return), modifierFlags: [], keyDisplay: "↩")
        case .close:
            return KeyCombo(keyCode: UInt16(kVK_Escape), modifierFlags: [], keyDisplay: "Esc")
        }
    }
}
