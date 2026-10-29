import Testing
import Foundation
@testable import ClipsKit

@Suite("ClipItem and PasteboardFilter tests")
struct ClipItemTests {
    @Test("Filters out sensitive types")
    func filtersSensitive() {
        #expect(PasteboardFilter.shouldIgnore(types: ["org.nspasteboard.ConcealedType"]))
        #expect(PasteboardFilter.shouldIgnore(types: ["com.agilebits.onepassword"]))
        #expect(PasteboardFilter.shouldIgnore(types: ["org.nspasteboard.TransientType"]))
        #expect(PasteboardFilter.shouldIgnore(types: ["com.maicolsantos.clips.internal"]))
        #expect(!PasteboardFilter.shouldIgnore(types: ["public.utf8-plain-text", "NSStringPboardType"]))
    }

    @Test("Text and URL preview")
    func textPreview() {
        let textItem = ClipItem(kind: .text, textContent: "  Hello World \n")
        #expect(textItem.preview == "Hello World")

        let urlItem = ClipItem(kind: .url, textContent: "https://apple.com")
        #expect(urlItem.preview == "https://apple.com")
    }

    @Test("Files preview")
    func filesPreview() {
        let filesItem = ClipItem(kind: .files, filePaths: ["/Users/test/Doc.pdf", "/Users/test/Photo.png"])
        #expect(filesItem.preview == "Doc.pdf, Photo.png")
    }

    @Test("Image preview")
    func imagePreview() {
        let imgItem = ClipItem(kind: .image, imageFileName: "abc.png")
        #expect(imgItem.preview == "Image")
    }
}
