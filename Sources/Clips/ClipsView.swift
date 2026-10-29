import AppKit
import SwiftUI
import ClipsKit

struct ClipsView: View {
    @State private var history = ClipboardHistory.shared
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isLabelInputFocused: Bool
    @State private var labelInput: String = ""
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                Divider().opacity(0.3)
                contentList
                Divider().opacity(0.3)
                footerBar
            }

            if let item = history.editingLabelItem {
                labelModal(for: item)
            }
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
            if history.selectedItemID == nil {
                history.selectFirstItem()
            }
        }
        .onKeyPress(.escape) {
            if history.editingLabelItem != nil {
                history.editingLabelItem = nil
                isSearchFocused = true
                return .handled
            }
            FloatingPanelController.shared.hide()
            return .handled
        }
        .onKeyPress(.return) {
            if history.editingLabelItem != nil {
                return .ignored
            }
            history.pasteCurrentSelectedItem()
            return .handled
        }
        .onKeyPress(.upArrow) {
            if history.editingLabelItem != nil {
                return .ignored
            }
            history.moveSelection(delta: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            if history.editingLabelItem != nil {
                return .ignored
            }
            history.moveSelection(delta: 1)
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "123456789")) { press in
            if history.editingLabelItem != nil {
                return .ignored
            }
            if history.searchText.isEmpty, let digit = Int(press.characters), digit >= 1 && digit <= 9 {
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
        history.currentSelectedItem
    }

    private func moveSelection(delta: Int) {
        history.moveSelection(delta: delta)
    }

    // MARK: - Label Modal

    private func labelModal(for item: ClipItem) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    history.editingLabelItem = nil
                    isSearchFocused = true
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(Palette.accent)
                        .font(.system(size: 15))
                    Text(L10n.tr(.hideContent))
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Button {
                        history.editingLabelItem = nil
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(L10n.tr(.maskDialogDescription))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField(L10n.tr(.labelPlaceholder), text: $labelInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Palette.accent.opacity(0.5), lineWidth: 1)
                    )
                    .focused($isLabelInputFocused)
                    .onSubmit {
                        submitMask(for: item)
                    }

                HStack {
                    Spacer()
                    Button(L10n.tr(.cancel)) {
                        history.editingLabelItem = nil
                        isSearchFocused = true
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

                    Button {
                        submitMask(for: item)
                    } label: {
                        Text(L10n.tr(.hide))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.onAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(width: 360)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        }
        .onAppear {
            labelInput = item.customLabel ?? ""
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                isLabelInputFocused = true
            }
        }
    }

    private func submitMask(for item: ClipItem) {
        history.maskItem(item, label: labelInput)
        history.editingLabelItem = nil
        isSearchFocused = true
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            // Filter Pills
            HStack(spacing: 4) {
                filterButton(title: L10n.tr(.all), hint: "⌘<", isSelected: !history.filterFavoritesOnly) {
                    history.filterFavoritesOnly = false
                    history.selectFirstItem()
                }
                filterButton(title: L10n.tr(.favorites), hint: "⌘1", systemImage: "star.fill", isSelected: history.filterFavoritesOnly) {
                    history.filterFavoritesOnly = true
                    history.selectFirstItem()
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.06), in: Capsule())

            // Search Box
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13, weight: .medium))

                TextField(L10n.tr(.searchPlaceholder), text: $history.searchText)
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

    private func filterButton(title: String, hint: String? = nil, systemImage: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                if let hint {
                    Text(hint)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .opacity(isSelected ? 0.9 : 0.5)
                }
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
                    Text(history.filterFavoritesOnly ? L10n.tr(.noFavoritesYet) : L10n.tr(.noClipsFound))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(history.filterFavoritesOnly ? L10n.tr(.starHint) : L10n.tr(.copyHint))
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
                                        history.pasteItem(item)
                                    },
                                    onToggleFavorite: {
                                        history.toggleFavorite(item)
                                    },
                                    onMask: {
                                        history.editingLabelItem = item
                                    },
                                    onUnmask: {
                                        history.unmaskItem(item)
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
        HStack(spacing: 14) {
            shortcutHint(key: "1..9", desc: L10n.tr(.quickPaste))
            shortcutHint(key: "↩", desc: L10n.tr(.paste))
            shortcutHint(key: "Esc", desc: L10n.tr(.close))
            shortcutHint(key: "⌘1", desc: L10n.tr(.favorites))
            shortcutHint(key: "⌘<", desc: L10n.tr(.all))

            Spacer()

            if let item = history.currentSelectedItem {
                Button {
                    history.delete(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(L10n.tr(.deleteClip))
            }

            // Accessibility Status
            if !SyntheticPaste.isAccessibilityGranted {
                Button {
                    SyntheticPaste.requestAccessibility()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(L10n.tr(.enableAutoPaste))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
                .buttonStyle(.plain)
                .help(L10n.tr(.accessibilityHelp))
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
    let onToggleFavorite: () -> Void
    let onMask: () -> Void
    let onUnmask: () -> Void
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
                HStack(spacing: 6) {
                    if let label = item.customLabel, !label.isEmpty {
                        Button(action: onMask) {
                            HStack(spacing: 3) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 8))
                                Text(label)
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.2) : Palette.accent.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                        .help(L10n.tr(.editLabel))
                    }

                    if item.isMasked {
                        Button(action: onUnmask) {
                            HStack(spacing: 4) {
                                Text("******")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                Image(systemName: "eye")
                                    .font(.system(size: 10))
                                    .opacity(0.7)
                            }
                            .foregroundStyle(isSelected ? Palette.onAccent : .primary)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.tr(.revealContent))
                    } else {
                        Text(item.preview)
                            .font(.system(size: 13))
                            .lineLimit(2)
                            .foregroundStyle(isSelected ? Palette.onAccent : .primary)
                            .textSelection(.disabled)
                    }
                }

                HStack(spacing: 6) {
                    if item.isMasked {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                            Text(L10n.tr(.maskedTag))
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundStyle(isSelected ? Palette.onAccent.opacity(0.8) : .secondary)
                    }

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

            // Trailing actions: Eye button ("fechar olho" / "ver") + Numerical Badge
            HStack(spacing: 6) {
                Button {
                    if item.isMasked {
                        onUnmask()
                    } else {
                        onMask()
                    }
                } label: {
                    Image(systemName: item.isMasked ? "eye" : "eye.slash")
                        .font(.system(size: 11))
                        .foregroundStyle(item.isMasked ? (isSelected ? Palette.onAccent : Palette.accent) : (isSelected ? Palette.onAccent.opacity(0.8) : Color.secondary.opacity(0.6)))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(item.isMasked ? L10n.tr(.revealContent) : L10n.tr(.hideContent))

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
        .contextMenu {
            if item.isMasked {
                Button(action: onUnmask) {
                    Label(L10n.tr(.revealContent), systemImage: "eye")
                }
                Button(action: onMask) {
                    Label(L10n.tr(.editLabel), systemImage: "tag")
                }
            } else {
                Button(action: onMask) {
                    Label(L10n.tr(.hideContent), systemImage: "eye.slash")
                }
            }

            Divider()

            Button(action: onToggleFavorite) {
                Label(item.isFavorite ? L10n.tr(.removeFromFavorites) : L10n.tr(.addToFavorites), systemImage: item.isFavorite ? "star.slash" : "star")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label(L10n.tr(.deleteClip), systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var kindPreview: some View {
        switch item.kind {
        case .image:
            if let fileName = item.imageFileName {
                if let thumb = ClipboardHistory.shared.thumbnail(for: fileName) {
                    Image(nsImage: thumb)
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
