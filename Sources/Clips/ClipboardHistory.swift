import AppKit
import CryptoKit
import Foundation
import ClipsKit

@MainActor
@Observable
final class ClipboardHistory {
    static let shared = ClipboardHistory()

    var items: [ClipItem] = []
    var searchText: String = ""
    var filterFavoritesOnly: Bool = false
    var selectedItemID: UUID?
    var editingLabelItem: ClipItem?

    private var timer: Timer?
    private var lastChangeCount: Int = -1
    private var saveTask: Task<Void, Never>?

    private let thumbnailCache = NSCache<NSString, NSImage>()

    private var storageDirectory: URL {
        if let custom = ProcessInfo.processInfo.environment["APP_STORE"], !custom.isEmpty {
            return URL(fileURLWithPath: custom).deletingLastPathComponent()
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("Clips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Ensure secure directory permissions (owner-only read/write)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
        return dir
    }

    private var storageFile: URL {
        if let custom = ProcessInfo.processInfo.environment["APP_STORE"], !custom.isEmpty {
            let jsonPath = custom.hasSuffix(".store") ? custom.replacingOccurrences(of: ".store", with: ".json") : custom
            return URL(fileURLWithPath: jsonPath)
        }
        return storageDirectory.appendingPathComponent("clipboard.json")
    }

    private var imagesDirectory: URL {
        let dir = storageDirectory.appendingPathComponent("clips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        load()
    }

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer?.invalidate()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        t.tolerance = 0.1
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        let types = pb.types?.map(\.rawValue) ?? []
        guard !PasteboardFilter.shouldIgnore(types: types) else { return }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // 1. Files
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            let paths = urls.map(\.path)
            let item = ClipItem(
                kind: .files,
                filePaths: paths,
                sourceAppName: sourceApp
            )
            add(item)
            return
        }

        // 2. Images (PNG or TIFF)
        if let pngData = pb.data(forType: .png) ?? convertTIFFToPNG(pb.data(forType: .tiff)) {
            let hash = SHA256.hash(data: pngData)
            let hexPrefix = hash.prefix(12).map { String(format: "%02x", $0) }.joined()
            let fileName = "\(hexPrefix).png"
            let filePath = imagesDirectory.appendingPathComponent(fileName)

            if !FileManager.default.fileExists(atPath: filePath.path) {
                try? pngData.write(to: filePath)
            }

            let item = ClipItem(
                kind: .image,
                imageFileName: fileName,
                sourceAppName: sourceApp
            )
            add(item)
            return
        }

        // 3. String / URL
        if let string = pb.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let isURL = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
            let item = ClipItem(
                kind: isURL ? .url : .text,
                textContent: trimmed,
                sourceAppName: sourceApp
            )
            add(item)
        }
    }

    private func convertTIFFToPNG(_ tiffData: Data?) -> Data? {
        guard let data = tiffData,
              let rep = NSBitmapImageRep(data: data) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    func add(_ item: ClipItem) {
        // Deduplicate: remove existing identical item and move to top
        items.removeAll { existing in
            if existing.kind != item.kind { return false }
            switch item.kind {
            case .text, .url:
                return existing.textContent == item.textContent
            case .image:
                return existing.imageFileName == item.imageFileName
            case .files:
                return existing.filePaths == item.filePaths
            }
        }

        items.insert(item, at: 0)

        // Limit to historyLimit items (default 100, preserving favorites)
        let limit = historyLimit
        if items.count > limit {
            for i in stride(from: items.count - 1, through: limit, by: -1) {
                if !items[i].isFavorite {
                    let removed = items.remove(at: i)
                    cleanupImageFileIfNeeded(for: removed)
                }
            }
        }

        scheduleSave()
    }

    var historyLimit: Int {
        let val = UserDefaults.standard.integer(forKey: "historyLimit")
        return val > 0 ? val : 100
    }

    func enforceLimit() {
        let limit = historyLimit
        if items.count > limit {
            for i in stride(from: items.count - 1, through: limit, by: -1) {
                if !items[i].isFavorite {
                    let removed = items.remove(at: i)
                    cleanupImageFileIfNeeded(for: removed)
                }
            }
            scheduleSave()
        }
    }

    func toggleFavorite(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isFavorite.toggle()
        scheduleSave()
    }

    func maskItem(_ item: ClipItem, label: String?) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isMasked = true
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[idx].customLabel = (trimmed?.isEmpty ?? true) ? nil : trimmed
        scheduleSave()
    }

    func removeLabel(from item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].customLabel = nil
        scheduleSave()
    }

    func unmaskItem(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isMasked = false
        scheduleSave()
    }

    func toggleMask(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isMasked.toggle()
        scheduleSave()
    }

    func updateLabel(_ item: ClipItem, label: String?) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[idx].customLabel = (trimmed?.isEmpty ?? true) ? nil : trimmed
        scheduleSave()
    }

    func delete(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        cleanupImageFileIfNeeded(for: item)
        scheduleSave()
    }

    func clear() {
        // Keep favorites
        let toRemove = items.filter { !$0.isFavorite }
        for item in toRemove {
            cleanupImageFileIfNeeded(for: item)
        }
        items = items.filter { $0.isFavorite }
        scheduleSave()
    }

    private func cleanupImageFileIfNeeded(for item: ClipItem) {
        guard let fileName = item.imageFileName else { return }
        let stillUsed = items.contains { $0.imageFileName == fileName }
        if !stillUsed {
            thumbnailCache.removeObject(forKey: fileName as NSString)
            let path = imagesDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: path)
        }
    }

    func imageURL(for fileName: String) -> URL {
        imagesDirectory.appendingPathComponent(fileName)
    }

    func thumbnail(for fileName: String) -> NSImage? {
        let key = fileName as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }
        let url = imageURL(for: fileName)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 128,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let thumb = NSImage(cgImage: cgThumb, size: NSSize(width: 32, height: 32))
        thumbnailCache.setObject(thumb, forKey: key)
        return thumb
    }

    // MARK: - Copy Back & Paste

    func copyToPasteboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.kind {
        case .text, .url:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let fileName = item.imageFileName {
                let file = imagesDirectory.appendingPathComponent(fileName)
                if let data = try? Data(contentsOf: file) {
                    pb.setData(data, forType: .png)
                    if let img = NSImage(data: data), let tiff = img.tiffRepresentation {
                        pb.setData(tiff, forType: .tiff)
                    }
                }
            }
        case .files:
            if let paths = item.filePaths {
                let urls = paths.map { NSURL(fileURLWithPath: $0) }
                pb.writeObjects(urls)
            }
        }

        // Keep lastChangeCount in sync so Clips does not detect its own copy as a new clip
        lastChangeCount = pb.changeCount
    }

    var currentSelectedItem: ClipItem? {
        let current = filteredItems
        if let id = selectedItemID, let match = current.first(where: { $0.id == id }) {
            return match
        }
        return current.first
    }

    func selectFirstItem() {
        selectedItemID = filteredItems.first?.id
    }

    func moveSelection(delta: Int) {
        let current = filteredItems
        guard !current.isEmpty else { return }

        let currentIndex = current.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + delta, 0), current.count - 1)
        selectedItemID = current[nextIndex].id
    }

    func pasteCurrentSelectedItem() {
        if let selected = currentSelectedItem {
            pasteItem(selected)
        }
    }

    func pasteItem(_ item: ClipItem) {
        copyToPasteboard(item)
        let targetApp = FloatingPanelController.shared.previousApp
        FloatingPanelController.shared.hide()

        // Reactivate target app so simulated paste arrives at the right destination
        if let targetApp, !targetApp.isTerminated {
            targetApp.activate()
        } else {
            NSApp.hide(nil)
        }

        // Give previous app time to receive focus before sending simulated Command-V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            if SyntheticPaste.isAccessibilityGranted {
                SyntheticPaste.postPasteCommand()
            } else {
                SyntheticPaste.requestAccessibility()
            }
        }
    }

    // MARK: - Filtered items

    var filteredItems: [ClipItem] {
        var result = items
        if filterFavoritesOnly {
            result = result.filter(\.isFavorite)
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.searchContent.contains(query) }
        }
        return result
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1.0))
            self.saveNow()
        }
    }

    func saveNow() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageFile, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageFile.path) else { return }
        do {
            let data = try Data(contentsOf: storageFile)
            items = try JSONDecoder().decode([ClipItem].self, from: data)
        } catch {
            print("Failed to load clipboard history: \(error)")
        }
    }
}
