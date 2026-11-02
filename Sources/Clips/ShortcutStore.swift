import AppKit
import Foundation
import SwiftUI
import ClipsKit

/// App-wide keyboard shortcuts manager.
@MainActor
@Observable
public final class ShortcutStore {
    public static let shared = ShortcutStore()

    public var openClips: KeyCombo {
        didSet {
            save(.openClips, openClips)
            HotkeyCenter.shared.register()
        }
    }

    public var allClips: KeyCombo {
        didSet {
            save(.allClips, allClips)
        }
    }

    public var favorites: KeyCombo {
        didSet {
            save(.favorites, favorites)
        }
    }

    public var paste: KeyCombo {
        didSet {
            save(.paste, paste)
        }
    }

    public var close: KeyCombo {
        didSet {
            save(.close, close)
        }
    }

    private init() {
        self.openClips = Self.load(.openClips)
        self.allClips = Self.load(.allClips)
        self.favorites = Self.load(.favorites)
        self.paste = Self.load(.paste)
        self.close = Self.load(.close)
    }

    public func shortcut(for action: ShortcutAction) -> KeyCombo {
        switch action {
        case .openClips: return openClips
        case .allClips: return allClips
        case .favorites: return favorites
        case .paste: return paste
        case .close: return close
        }
    }

    @discardableResult
    public func set(_ combo: KeyCombo, for action: ShortcutAction) -> ShortcutAction? {
        var displacedAction: ShortcutAction? = nil
        // If combo is not empty, remove it from any other action that was using it
        if !combo.isEmpty {
            for otherAction in ShortcutAction.allCases where otherAction != action {
                if shortcut(for: otherAction) == combo {
                    setDirect(.empty, for: otherAction)
                    displacedAction = otherAction
                }
            }
        }
        setDirect(combo, for: action)
        return displacedAction
    }

    private func setDirect(_ combo: KeyCombo, for action: ShortcutAction) {
        switch action {
        case .openClips: openClips = combo
        case .allClips: allClips = combo
        case .favorites: favorites = combo
        case .paste: paste = combo
        case .close: close = combo
        }
    }

    public func resetToDefaults() {
        for action in ShortcutAction.allCases {
            setDirect(action.defaultCombo, for: action)
        }
        HotkeyCenter.shared.register()
    }

    public func menuTitle(for action: ShortcutAction, base: String) -> String {
        let combo = shortcut(for: action)
        if combo.isEmpty || combo.displayString.isEmpty {
            return base
        }
        return "\(base) (\(combo.displayString))"
    }

    // MARK: - Persistence

    private static func defaultsKey(for action: ShortcutAction) -> String {
        "shortcut.\(action.rawValue)"
    }

    private func save(_ action: ShortcutAction, _ combo: KeyCombo) {
        guard !Store.isOverridden else { return }
        if let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey(for: action))
        }
    }

    private static func load(_ action: ShortcutAction) -> KeyCombo {
        guard !Store.isOverridden else { return action.defaultCombo }
        guard let data = UserDefaults.standard.data(forKey: defaultsKey(for: action)),
              let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) else {
            return action.defaultCombo
        }
        return combo
    }
}

// MARK: - SwiftUI KeyEquivalent and Modifiers

extension KeyCombo {
    public var keyEquivalent: KeyEquivalent? {
        guard !isEmpty else { return nil }

        switch keyCode {
        case 36, 76: return .return
        case 53: return .escape
        case 48: return .tab
        case 49: return .space
        case 51: return .delete
        case 123: return .leftArrow
        case 124: return .rightArrow
        case 125: return .downArrow
        case 126: return .upArrow
        default:
            if keyDisplay == "<" {
                return KeyEquivalent("<")
            }
            if let firstChar = keyDisplay.lowercased().first {
                return KeyEquivalent(firstChar)
            }
            return nil
        }
    }

    public var eventModifiers: EventModifiers {
        var mods = EventModifiers()
        let flags = modifierFlags
        if flags.contains(.command) { mods.insert(.command) }
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.option) { mods.insert(.option) }
        if flags.contains(.control) { mods.insert(.control) }
        return mods
    }
}

extension View {
    @ViewBuilder
    public func optionalKeyboardShortcut(_ combo: KeyCombo) -> some View {
        if let key = combo.keyEquivalent {
            self.keyboardShortcut(key, modifiers: combo.eventModifiers)
        } else {
            self
        }
    }
}
