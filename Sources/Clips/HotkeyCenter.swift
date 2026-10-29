import Carbon.HIToolbox
import Foundation

@MainActor
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    private var hotKeyRef: EventHotKeyRef?
    var onTrigger: (@MainActor () -> Void)?

    private init() {}

    func register() {
        // Register Option + Command + C
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_4950), id: 1) // 'CLIP'
        let modifiers = UInt32(cmdKey | optionKey)
        let keyCode = UInt32(kVK_ANSI_C) // 8

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Failed to register hotkey Option-Command-C: status \(status)")
        }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in
                HotkeyCenter.shared.onTrigger?()
            }
            return noErr
        }, 1, &spec, nil, nil)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
