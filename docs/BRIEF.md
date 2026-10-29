# Clips

A lightning-fast, native macOS clipboard manager in Liquid Glass. Replaces Copy'em Paste with a clean, modern aesthetic: keeps copies, stars favorites, and auto-pastes into the frontmost app with numerical shortcuts.

## Replaces
Copy'em Paste (and older clipboard managers).

## Main jobs
1. **Background Capture**: Automatically monitor macOS pasteboard and store copied texts, URLs, and images locally.
2. **Instant Floating Panel**: Open with a global shortcut (`⌥⌘C` or `⇧⌘V`) as a floating non-activating Liquid Glass panel.
3. **Instant Auto-Paste**: Pressing `1` through `9` or `Return` immediately pastes the selected clip into the frontmost app and hides the panel.
4. **Favorites**: Star clips (`⭐`) to retain them in a quick-access Favorites view.
5. **Instant Search**: Type to immediately filter history.

## Data
- `ClipItem`:
  - `id`: `UUID`
  - `createdAt`: `Date`
  - `kind`: `.text`, `.url`, `.image`
  - `textContent`: `String?`
  - `imagePath`: `String?` (stored as PNG in Application Support/Clips/images)
  - `isFavorite`: `Bool`
  - `sourceAppName`: `String?`

## Shape
Floating non-activating panel (`NSPanel` with `.nonactivatingPanel`), menu bar extra (`MenuBarExtra`), and Settings.
macOS 26 or later. Menu-bar only (`LSUIElement`). 100% local data with SwiftData. Offline. No accounts.

## System hooks
- Clipboard polling: `NSPasteboard.general.changeCount`
- Global hotkey: Carbon `RegisterEventHotKey` (default `⌥⌘C`)
- Auto-paste into front app: Synthetic `⌘V` via `CGEvent`
- Accessibility permissions detection & prompt

## Reference Look
Modern macOS Liquid Glass: 
- Vibrancy translucency, subtle border, SF Symbols.
- Selected item highlighted with macOS accent color.
- Number badge (`1`..`9`) at the trailing edge of top rows for instant muscle-memory pasting.
- Clean star icon (`☆` / `★`) on each item.

## Not in version one
- Cloud / multi-device sync
- Built-in screenshot editing tool (keeps clipboard pure and fast)
- Complex nested tag folders (kept focused on All & Favorites)
