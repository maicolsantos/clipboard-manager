# Stories

## M1 Core loop

### S-001 Background clipboard capture
As the user, when I copy text, URLs, or images in any app, they are automatically saved to my history.
Screens: 01-main.png
Acceptance:
- [unit] Text copied with pbcopy is recorded in history within 0.5s.
- [unit] Copying duplicate content moves the existing item to the top rather than duplicating.
- [unit] Images copied from Finder/web are stored as PNG locally with SHA-256 hash naming.
- [self] History persists across app restarts.
Status: done

### S-002 Floating Liquid Glass panel & global hotkey
As the user, pressing `⌥⌘C` (or configured hotkey) opens the floating panel without stealing focus from the active app.
Screens: 01-main.png
Depends: S-001
Acceptance:
- [snap] Panel renders with translucent Liquid Glass material, rounded corners, and subtle borders.
- [manual] Frontmost application retains focus while panel is visible.
- [manual] Pressing `Esc` or clicking outside dismisses the panel.
Status: done

### S-003 Auto-paste into frontmost app
As the user, selecting an item and pressing `Return`, double-clicking, or pressing numbers `1` through `9` immediately pastes that clip into the app I was working in.
Screens: 01-main.png
Depends: S-002
Acceptance:
- [manual] Pressing `1` through `9` selects that item, closes the panel, and inserts text/image via simulated ⌘V.
- [manual] Pressing `Return` pastes the currently selected row.
- [manual] If Accessibility permission is not yet granted, the app guides the user to grant it in System Settings.
Status: done

## M2 Favorites & Search

### S-004 Star & filter favorites
As the user, I can toggle a star on any item so it remains permanently in my Favorites list.
Screens: 01-main.png, 03-lists-dropdown.png
Depends: S-001
Acceptance:
- [snap] Star icon (☆ / ★) on each row toggles favorite state.
- [snap] Switching to "Favorites" view displays only starred items.
- [unit] Starred items are never pruned by history limit cleanups.
Status: done

### S-005 Instant fuzzy search
As the user, I can type immediately when the panel opens to filter clips by text, URL, or source app name.
Screens: 01-main.png
Depends: S-002
Acceptance:
- [snap] Search field is automatically focused upon opening the panel.
- [unit] Typing filters results in real-time with sub-millisecond response.
- [manual] Shortcut numbers `1`..`9` dynamically bind to the filtered results.
Status: done
