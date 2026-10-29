import AppKit
import SwiftUI
import ClipsKit

struct ClipsView: View {
    @State private var history = ClipboardHistory.shared
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().opacity(0.3)
            contentList
            Divider().opacity(0.3)
            footerBar
        }
        .frame(width: 700, height: 440)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
            if history.selectedItemID == nil, let first = history.filteredItems.first {
                history.selectedItemID = first.id
            }
        }
        .onKeyPress(.escape) {
            FloatingPanelController.shared.hide()
            return .handled
        }
        .onKeyPress(.return) {
            if let selected = currentSelectedItem {
                history.pasteItem(selected)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.upArrow) {
            moveSelection(delta: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(delta: 1)
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "123456789")) { press in
            // When Cmd is down or search is empty, paste the corresponding number
            if let digit = Int(press.characters), digit >= 1 && digit <= 9 {
                let items = history.filteredItems
                let index = digit - 1
                if index < items.count {
                    history.pasteItem(items[index])
                    return .handled
                }
            }
            return .ignored
        }
    }

    private var currentSelectedItem: ClipItem? {
        let items = history.filteredItems
        if let id = history.selectedItemID, let match = items.first(where: { $0.id == id }) {
            return match
        }
        return items.first
    }

    private func moveSelection(delta: Int) {
        let items = history.filteredItems
        guard !items.isEmpty else { return }

        let currentIndex = items.firstIndex(where: { $0.id == history.selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + delta, 0), items.count - 1)
        history.selectedItemID = items[nextIndex].id
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            // Filter Pills
            HStack(spacing: 4) {
                filterButton(title: "All", isSelected: !history.filterFavoritesOnly) {
                    history.filterFavoritesOnly = false
                }
                filterButton(title: "Favorites", systemImage: "star.fill", isSelected: history.filterFavoritesOnly) {
                    history.filterFavoritesOnly = true
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.06), in: Capsule())

            // Search Box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13, weight: .medium))

                TextField("Search clips or apps...", text: $history.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .onChange(of: history.searchText) { _, _ in
                        if let first = history.filteredItems.first {
                            history.selectedItemID = first.id
                        }
                    }

                if !history.searchText.isEmpty {
                    Button {
                        history.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Clip count
            Text("\(history.filteredItems.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func filterButton(title: String, systemImage: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Palette.accent : Color.clear, in: Capsule())
            .foregroundStyle(isSelected ? Palette.onAccent : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - List

    private var contentList: some View {
        let items = history.filteredItems

        return Group {
            if items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: history.filterFavoritesOnly ? "star.slash" : "clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text(history.filterFavoritesOnly ? "No favorite clips yet" : "No clips found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(history.filterFavoritesOnly ? "Star any clip to keep it handy here." : "Copy text, URLs, or images and they will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ClipRowView(
                                    item: item,
                                    index: index,
                                    isSelected: item.id == history.selectedItemID,
                                    onSelect: {
                                        history.selectedItemID = item.id
                                    },
                                    onDoubleClick: {
                                        history.pasteItem(item)
                                    },
                                    onToggleFavorite: {
                                        history.toggleFavorite(item)
                                    },
                                    onDelete: {
                                        history.delete(item)
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .onChange(of: history.selectedItemID) { _, newID in
                        if let newID {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack(spacing: 16) {
            shortcutHint(key: "1..9", desc: "Quick paste")
            shortcutHint(key: "↩", desc: "Paste")
            shortcutHint(key: "⌘↩", desc: "Copy only")
            shortcutHint(key: "Esc", desc: "Close")

            Spacer()

            if let item = currentSelectedItem {
                Button {
                    history.delete(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete clip (⌘⌫)")
            }

            // Accessibility Status
            if !SyntheticPaste.isAccessibilityGranted {
                Button {
                    SyntheticPaste.requestAccessibility()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Enable Auto-Paste")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
                .buttonStyle(.plain)
                .help("Accessibility permission required to auto-paste into active apps")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .background(Color.primary.opacity(0.03))
    }

    private func shortcutHint(key: String, desc: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            Text(desc)
                .font(.system(size: 11))
        }
    }
}

// MARK: - ClipRowView

struct ClipRowView: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Star Button
            Button(action: onToggleFavorite) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(item.isFavorite ? Color.yellow : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Kind Icon or Image Thumbnail
            kindPreview

            // Main Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundStyle(isSelected ? Palette.onAccent : .primary)
                    .textSelection(.disabled)

                HStack(spacing: 6) {
                    if let app = item.sourceAppName {
                        Text(app)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.primary.opacity(isSelected ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 3))
                    }
                    Text(formattedDate(item.createdAt))
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Palette.onAccent.opacity(0.8) : .secondary)
                }
            }

            Spacer(minLength: 8)

            // Numerical Badge (1..9)
            if index < 9 {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Palette.onAccent : .secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Palette.accent : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
    }

    @ViewBuilder
    private var kindPreview: some View {
        switch item.kind {
        case .image:
            if let fileName = item.imageFileName {
                let url = ClipboardHistory.shared.imageURL(for: fileName)
                if let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "photo")
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.secondary)
                }
            }
        case .url:
            Image(systemName: "link")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Palette.onAccent : .blue)
                .frame(width: 24)
        case .files:
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Palette.onAccent : .orange)
                .frame(width: 24)
        case .text:
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Palette.onAccent : .secondary)
                .frame(width: 24)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
