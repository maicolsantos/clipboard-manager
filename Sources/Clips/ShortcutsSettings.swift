import AppKit
import SwiftUI
import ClipsKit

/// Settings > Shortcuts: configure global hotkey and in-app navigation shortcuts.
struct ShortcutsSettings: View {
    @State private var store = ShortcutStore.shared
    @State private var recordingAction: ShortcutAction? = nil
    @State private var displacedAction: ShortcutAction? = nil

    var body: some View {
        Section(L10n.tr(.globalShortcut)) {
            ShortcutRow(
                action: .openClips,
                title: L10n.tr(.openClipsAction),
                combo: store.openClips,
                recordingAction: $recordingAction,
                onDisplaced: { displacedAction = $0 }
            )

            if HotkeyCenter.shared.lastRegistrationStatus != noErr {
                HStack(spacing: Space.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(L10n.tr(.hotkeyConflictWarning))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text(L10n.tr(.globalShortcutDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section(L10n.tr(.windowShortcuts)) {
            ShortcutRow(
                action: .allClips,
                title: L10n.tr(.allClipsAction),
                combo: store.allClips,
                recordingAction: $recordingAction,
                onDisplaced: { displacedAction = $0 }
            )

            ShortcutRow(
                action: .favorites,
                title: L10n.tr(.favoritesAction),
                combo: store.favorites,
                recordingAction: $recordingAction,
                onDisplaced: { displacedAction = $0 }
            )

            ShortcutRow(
                action: .paste,
                title: L10n.tr(.pasteAction),
                combo: store.paste,
                recordingAction: $recordingAction,
                onDisplaced: { displacedAction = $0 }
            )

            ShortcutRow(
                action: .close,
                title: L10n.tr(.closeAction),
                combo: store.close,
                recordingAction: $recordingAction,
                onDisplaced: { displacedAction = $0 }
            )
        }

        Section {
            HStack(spacing: Space.sm) {
                Text(L10n.tr(.shortcutsHelp))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(L10n.tr(.resetDefaults)) {
                    store.resetToDefaults()
                    recordingAction = nil
                    displacedAction = nil
                }
            }
        }
    }
}

private struct ShortcutRow: View {
    let action: ShortcutAction
    let title: String
    let combo: KeyCombo
    @Binding var recordingAction: ShortcutAction?
    let onDisplaced: (ShortcutAction?) -> Void

    @State private var eventMonitor: Any?

    private var isRecording: Bool {
        recordingAction == action
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: Space.sm) {
                Button {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    if isRecording {
                        Text(L10n.tr(.recordingPrompt))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.accentText)
                            .padding(.horizontal, Space.sm)
                            .padding(.vertical, Space.xs)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Palette.accent, lineWidth: 2)
                            )
                    } else if combo.isEmpty {
                        Text(L10n.tr(.recordShortcut))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Space.sm)
                            .padding(.vertical, Space.xs)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Text(combo.displayString)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, Space.sm)
                            .padding(.vertical, Space.xs)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .buttonStyle(.plain)

                if !combo.isEmpty && !isRecording {
                    Button {
                        ShortcutStore.shared.set(.empty, for: action)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.tr(.clearShortcut))
                }
            }
        }
        .onChange(of: recordingAction) { _, newAction in
            if newAction != action && eventMonitor != nil {
                stopRecording()
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        recordingAction = action
        HotkeyCenter.shared.pause()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Esc cancels
            if event.keyCode == 53 && event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty {
                stopRecording()
                return nil
            }

            // Delete clears
            if event.keyCode == 51 && event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty {
                ShortcutStore.shared.set(.empty, for: action)
                stopRecording()
                return nil
            }

            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            let isSpecial = [36, 48, 49, 53, 76, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 123, 124, 125, 126].contains(Int(event.keyCode))

            // Global shortcut requires at least one modifier
            if action == .openClips && flags.isEmpty {
                NSSound.beep()
                return nil
            }

            // Normal letters/numbers without modifiers are disallowed
            if flags.isEmpty && !isSpecial {
                NSSound.beep()
                return nil
            }

            let newCombo = KeyCombo(event: event)
            let displaced = ShortcutStore.shared.set(newCombo, for: action)
            onDisplaced(displaced)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if recordingAction == action {
            recordingAction = nil
        }
        HotkeyCenter.shared.resume()
    }
}
