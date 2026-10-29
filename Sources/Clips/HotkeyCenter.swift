import Carbon.HIToolbox
import Foundation

@MainActor
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    var onTrigger: (@MainActor () -> Void)?

    private init() {}

    func register() {
        unregister()

        // Register Command + Shift + V
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_4950), id: 1) // 'CLIP'
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V) // 9

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Failed to register hotkey Command-Shift-V: status \(status)")
        }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in
                HotkeyCenter.shared.onTrigger?()
            }
            return noErr
        }, 1, &spec, nil, &eventHandlerRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
