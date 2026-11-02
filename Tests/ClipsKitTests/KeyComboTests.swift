import Testing
import AppKit
import Carbon.HIToolbox
@testable import ClipsKit

@Suite("KeyCombo and ShortcutAction tests")
struct KeyComboTests {
    @Test("Default shortcuts match expected definitions")
    func testDefaultShortcuts() {
        let openClips = ShortcutAction.openClips.defaultCombo
        #expect(openClips.displayString == "⌘⇧V")
        #expect(openClips.keyCode == UInt16(kVK_ANSI_V))
        #expect(openClips.modifierFlags.contains(.command))
        #expect(openClips.modifierFlags.contains(.shift))

        let allClips = ShortcutAction.allClips.defaultCombo
        #expect(allClips.displayString == "⌘<")
        #expect(allClips.modifierFlags.contains(.command))

        let favorites = ShortcutAction.favorites.defaultCombo
        #expect(favorites.displayString == "⌘1")
        #expect(favorites.keyCode == UInt16(kVK_ANSI_1))
        #expect(favorites.modifierFlags == .command)

        let paste = ShortcutAction.paste.defaultCombo
        #expect(paste.displayString == "↩")
        #expect(paste.keyCode == UInt16(kVK_Return))
        #expect(paste.modifierFlags.isEmpty)

        let close = ShortcutAction.close.defaultCombo
        #expect(close.displayString == "Esc")
        #expect(close.keyCode == UInt16(kVK_Escape))
        #expect(close.modifierFlags.isEmpty)
    }

    @Test("KeyCombo display strings format modifiers in standard order")
    func testDisplayStringFormatting() {
        let optCmd = KeyCombo(keyCode: 9, modifierFlags: [.option, .command], keyDisplay: "V")
        #expect(optCmd.displayString == "⌘⌥V")

        let ctrlOptShiftCmd = KeyCombo(keyCode: 9, modifierFlags: [.control, .option, .shift, .command], keyDisplay: "V")
        #expect(ctrlOptShiftCmd.displayString == "⌘⌥⌃⇧V")

        let empty = KeyCombo.empty
        #expect(empty.displayString == "")
        #expect(empty.isEmpty)
    }

    @Test("KeyCombo encodes and decodes properly")
    func testCodableRoundTrip() throws {
        let combo = KeyCombo(keyCode: 9, modifierFlags: [.command, .shift], keyDisplay: "V")
        let encoder = JSONEncoder()
        let data = try encoder.encode(combo)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(KeyCombo.self, from: data)

        #expect(decoded == combo)
        #expect(decoded.displayString == "⌘⇧V")
    }

    @Test("KeyCombo converts modifiers to Carbon modifiers")
    func testCarbonModifiers() {
        let combo = KeyCombo(keyCode: 9, modifierFlags: [.command, .shift], keyDisplay: "V")
        let carbon = combo.carbonModifiers
        #expect(carbon & UInt32(cmdKey) != 0)
        #expect(carbon & UInt32(shiftKey) != 0)
        #expect(carbon & UInt32(optionKey) == 0)
    }
}
