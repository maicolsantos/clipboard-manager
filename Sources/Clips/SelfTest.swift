import AppKit
import SwiftData
import SwiftUI
import ClipsKit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
///   APP_STORE=/tmp/Clips-self.store ~/Applications/Clips.app/Contents/MacOS/Clips --selftest
/// (tools/selftest.sh does this.) Add a check for every story with logic.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    static var previewRequested: Bool { CommandLine.arguments.contains("--render-preview") }
    /// Read by AppDelegate.applicationWillTerminate.
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(model: AppModel) {
        if previewRequested {
            renderPreview()
            return
        }
        guard requested else { return }
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            finish(code: 1)
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))

            // 1. Test ClipboardHistory core
            let history = ClipboardHistory.shared
            let beforeCount = history.items.count

            let testItem1 = ClipItem(kind: .text, textContent: "Hello SelfTest 1", sourceAppName: "Xcode")
            history.add(testItem1)
            check("Add clip item increases count", history.items.count == beforeCount + 1)
            check("Latest clip is at the top", history.items.first?.textContent == "Hello SelfTest 1")

            // Test deduplication
            let duplicateItem = ClipItem(kind: .text, textContent: "Hello SelfTest 1", sourceAppName: "Safari")
            history.add(duplicateItem)
            check("Adding duplicate keeps count unchanged", history.items.count == beforeCount + 1)
            check("Duplicate moves to top", history.items.first?.textContent == "Hello SelfTest 1")

            // Test Starring
            if let first = history.items.first {
                history.toggleFavorite(first)
                check("Starring marks item as favorite", history.items.first?.isFavorite == true)

                // Test Filter favorites
                history.filterFavoritesOnly = true
                check("Filtered items contains favorite", history.filteredItems.contains { $0.id == first.id })
                history.filterFavoritesOnly = false
            }

            // Test Search
            history.searchText = "SelfTest"
            check("Search finds query match", history.filteredItems.contains { $0.textContent == "Hello SelfTest 1" })
            history.searchText = "NonExistentKeywordXYZ"
            check("Search filters out non-matches", history.filteredItems.isEmpty)
            history.searchText = ""

            // Test selection navigation
            let itemA = ClipItem(kind: .text, textContent: "Item A")
            let itemB = ClipItem(kind: .text, textContent: "Item B")
            history.add(itemB)
            history.add(itemA)
            history.selectFirstItem()
            check("selectFirstItem selects top item", history.selectedItemID == itemA.id)
            history.moveSelection(delta: 1)
            check("moveSelection down selects next item", history.selectedItemID == itemB.id)
            history.moveSelection(delta: -1)
            check("moveSelection up selects first item", history.selectedItemID == itemA.id)
            history.delete(itemA)
            history.delete(itemB)

            // Test deletion
            if let first = history.items.first {
                history.delete(first)
                check("Deleting item removes it", history.items.count == beforeCount)
            }

            // Test history limit
            check("Default history limit is 100", history.historyLimit == 100)

            // Test sensitive type filter
            check("ConcealedType is filtered", PasteboardFilter.shouldIgnore(types: ["org.nspasteboard.ConcealedType"]))
            check("1Password is filtered", PasteboardFilter.shouldIgnore(types: ["com.agilebits.onepassword"]))
            check("Bitwarden is filtered", PasteboardFilter.shouldIgnore(types: ["com.bitwarden.pasteboard.concealed"]))
            check("KeePassXC is filtered", PasteboardFilter.shouldIgnore(types: ["net.keepassxc.keepassxc"]))
            check("TransientType is filtered", PasteboardFilter.shouldIgnore(types: ["org.nspasteboard.TransientType"]))

            // Test Masking, Custom Label, and Reveal
            let secretItem = ClipItem(kind: .text, textContent: "ghp_1234567890SecretToken")
            history.add(secretItem)
            check("Secret item added", history.items.first?.textContent == "ghp_1234567890SecretToken")

            if let itemToMask = history.items.first {
                history.maskItem(itemToMask, label: "GitHub PAT")
                let masked = history.items.first
                check("Masked item has isMasked = true", masked?.isMasked == true)
                check("Masked item has custom label", masked?.customLabel == "GitHub PAT")
                check("Masked item preview is ******", masked?.preview == "******")
                check("Underlying textContent is intact", masked?.textContent == "ghp_1234567890SecretToken")

                // Search by label
                history.searchText = "GitHub PAT"
                check("Search matches custom label when masked", history.filteredItems.contains { $0.id == itemToMask.id })
                // Search by hidden secret does not match
                history.searchText = "1234567890SecretToken"
                check("Search by hidden secret does not leak masked item", !history.filteredItems.contains { $0.id == itemToMask.id })
                history.searchText = ""

                // Test Remove Label
                history.maskItem(itemToMask, label: "Temporary Label")
                check("Custom label set", history.items.first?.customLabel == "Temporary Label")
                history.removeLabel(from: itemToMask)
                check("Custom label removed successfully", history.items.first?.customLabel == nil)

                // Reveal / unmask
                history.unmaskItem(itemToMask)
                let unmasked = history.items.first
                check("Unmasked item has isMasked = false", unmasked?.isMasked == false)
                check("Unmasked item preview shows original text", unmasked?.preview == "ghp_1234567890SecretToken")
                history.delete(itemToMask)
            }

            // Test Move Item (Drag & Drop Reordering)
            let fav1 = ClipItem(kind: .text, textContent: "Fav 1", isFavorite: true)
            let fav2 = ClipItem(kind: .text, textContent: "Fav 2", isFavorite: true)
            history.add(fav2)
            history.add(fav1)
            check("Fav 1 is first", history.items.first?.id == fav1.id)
            history.moveItem(from: fav1.id, to: fav2.id)
            check("Fav 2 is now first after reordering", history.items.first?.id == fav2.id)
            history.delete(fav1)
            history.delete(fav2)

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            finish(code: failures == 0 ? 0 : 1)
        }
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    static func renderPreview() {
        let history = ClipboardHistory.shared
        history.items = [
            ClipItem(
                kind: .text,
                textContent: "sk-proj-78a9c3b889a741f238b901",
                isFavorite: true,
                sourceAppName: "Terminal",
                isMasked: true,
                customLabel: "OpenAI API Key"
            ),
            ClipItem(
                kind: .url,
                textContent: "https://github.com/maicolsantos/clipboard-manager",
                isFavorite: true,
                sourceAppName: "Safari"
            ),
            ClipItem(
                kind: .text,
                textContent: "func copyToPasteboard(_ item: ClipItem) { ... }",
                isFavorite: false,
                sourceAppName: "Xcode"
            ),
            ClipItem(
                kind: .text,
                textContent: "npm install -g @anthropic-ai/claude-code",
                isFavorite: false,
                sourceAppName: "Terminal"
            ),
            ClipItem(
                kind: .text,
                textContent: "SELECT * FROM users WHERE active = true ORDER BY created_at DESC;",
                isFavorite: false,
                sourceAppName: "DataGrip"
            )
        ]
        history.selectFirstItem()

        let view = NSHostingView(rootView: ClipsView().themed())
        view.frame = NSRect(x: 0, y: 0, width: 700, height: 440)
        view.layoutSubtreeIfNeeded()

        if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            if let data = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
                let path1 = "/Users/maicolsantos/Documents/MAICOL/bama-clipboard/Clips/docs/assets/preview.png"
                let path2 = "/Users/maicolsantos/Documents/MAICOL/bama-clipboard/docs/assets/preview.png"
                try? data.write(to: URL(fileURLWithPath: path1))
                try? data.write(to: URL(fileURLWithPath: path2))
                print("PREVIEW RENDERED to \(path1)")
            }
        }
        finish(code: 0)
    }

    static func finish(code: Int32) {
        exitCode = code
        for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
        NSApp.terminate(nil)
    }
}
