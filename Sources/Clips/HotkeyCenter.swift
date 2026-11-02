import Carbon.HIToolbox
import Foundation
import ClipsKit

@MainActor
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    var onTrigger: (@MainActor () -> Void)?
    private(set) var lastRegistrationStatus: OSStatus = noErr
    private var isPaused = false

    private init() {}

    func pause() {
        isPaused = true
        unregister()
    }

    func resume() {
        isPaused = false
        register()
    }

    func register() {
        unregister()
        guard !isPaused else { return }

        let combo = ShortcutStore.shared.openClips
        guard !combo.isEmpty else {
            lastRegistrationStatus = noErr
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_4950), id: 1) // 'CLIP'
        let modifiers = combo.carbonModifiers
        let keyCode = UInt32(combo.keyCode)

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        lastRegistrationStatus = status
        if status != noErr {
            print("Failed to register hotkey \(combo.displayString): status \(status)")
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
