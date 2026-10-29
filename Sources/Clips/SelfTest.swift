import AppKit
import SwiftData
import ClipsKit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
///   APP_STORE=/tmp/Clips-self.store ~/Applications/Clips.app/Contents/MacOS/Clips --selftest
/// (tools/selftest.sh does this.) Add a check for every story with logic.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    /// Read by AppDelegate.applicationWillTerminate.
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(model: AppModel) {
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

            // Test deletion
            if let first = history.items.first {
                history.delete(first)
                check("Deleting item removes it", history.items.count == beforeCount)
            }

            // Test sensitive type filter
            check("ConcealedType is filtered", PasteboardFilter.shouldIgnore(types: ["org.nspasteboard.ConcealedType"]))
            check("1Password is filtered", PasteboardFilter.shouldIgnore(types: ["com.agilebits.onepassword"]))

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            finish(code: failures == 0 ? 0 : 1)
        }
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    static func finish(code: Int32) {
        exitCode = code
        for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
        NSApp.terminate(nil)
    }
}
