# Screen Index: Copy'em Paste -> Modern BAMA App

## 01-main.png

- **Page**: Main Clipboard Panel (floating window).
- **Layout**:
  - **Header Bar**:
    - Left: Close button (X), Pin toggle button (blue push-pin icon to keep panel always floating / on-top).
    - Center: Title dropdown menu `Copy'em Paste (102) ▾` showing current list/collection name and total clip count (102 items).
    - Right: Sort indicator/button (`↓ N`), Search button (magnifying glass 🔍).
  - **List Content**:
    - Vertical list of recent clips.
    - Left icon on each row: Star icon (☆) to toggle favorite.
    - Content renderers:
      - Plain text & URLs (URLs highlighted in blue with underline).
      - Images: rendered as a centered preview in the row.
    - Right indicator: Numerical shortcut indicator (`1`, `2`, `3`, `4`, `5`, `6`...) for fast 1-key paste.
  - **Bottom Toolbar**:
    - Left icons: ⚙️ Settings, ⏸️ Pause/Resume capture, 📷 Screenshot, ⭐ Quick filter by Favorites.
    - Right icons: `T :` Plain text toggle, 🗑️ Delete.

## 02-gear-menu.png

- **Page**: Action & Settings Popover Menu (opened by clicking ⚙️ gear icon).
- **Items**:
  - `About Copy'em Paste`
  - `Show Tutorial`
  - `Preferences >` (Submenu with configuration options / preferences window)
  - `Customer Support`
  - `Rate App`
  - `Quit (⌘Q)`

## 03-lists-dropdown.png

- **Page**: Collections / Lists Dropdown.
- **Items**:
  - `✓ All` (`⌘<`)
  - `My Shortcuts` (`⌘S`)
  - `Unstarred` (`⌘U`)
  - `⭐ Favorites` (`⌘1`)
  - `Edit >` (manage lists)

---

## Navigation Map

```text
[Global Shortcut] (e.g. ⌥⌘C or ⇧⌘V)
  └── Floating Panel (Liquid Glass)
        ├── All Clips (Default list)
        ├── Favorites Filter (Starred clips)
        ├── Search Bar (instant fuzzy filter)
        └── Settings Window (⌘,)
```

## Command Map

| Action | Shortcut / Key | Behavior |
| --- | --- | --- |
| Open panel | `⌥⌘C` (Global) | Opens floating Liquid Glass panel centered or near mouse |
| Auto-Paste #1..9 | `1` .. `9` | Copies item, closes panel, simulates ⌘V into frontmost app |
| Auto-Paste selected | `Return` | Copies selected item, closes panel, simulates ⌘V |
| Copy only (no paste) | `⌘ Return` | Copies selected item to clipboard without pasting |
| Toggle Favorite | `S` or click ⭐ | Marks/unmarks clip as favorite |
| Filter Favorites | `⌘1` | Switches view to starred/favorite clips |
| Filter All | `⌘<` or `Esc` in search | Shows all clips |
| Delete clip | `⌘ ⌫` (Delete) | Removes clip from history |
| Close panel | `Esc` | Hides panel without pasting |

## Data Model

- **`ClipItem`**:
  - `id`: `UUID`
  - `createdAt`: `Date`
  - `kind`: `.text`, `.image`, `.url`, `.file`
  - `content`: Plain string, URL, or image file hash
  - `isFavorite`: `Bool`
  - `sourceAppName`: String (e.g. "Safari", "Xcode", "Terminal")
- **`ClipCollection`**:
  - `id`: `UUID`
  - `title`: String ("All", "Favorites", custom lists)
  - `filter`: predicate or item IDs
