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

    @Test("Masking hides content as ****** and preserves underlying text")
    func maskingBehavior() {
        var item = ClipItem(kind: .text, textContent: "super-secret-password-123", sourceAppName: "Safari")
        #expect(item.preview == "super-secret-password-123")
        #expect(item.unmaskedPreview == "super-secret-password-123")
        #expect(item.searchContent.contains("super-secret"))

        item.isMasked = true
        item.customLabel = "OpenAI API Key"
        #expect(item.preview == "******")
        #expect(item.unmaskedPreview == "super-secret-password-123")
        #expect(item.textContent == "super-secret-password-123")
        // Search matches label, not the hidden secret
        #expect(item.searchContent.contains("openai"))
        #expect(item.searchContent.contains("api key"))
        #expect(!item.searchContent.contains("super-secret"))

        // Unmask
        item.isMasked = false
        #expect(item.preview == "super-secret-password-123")
        #expect(item.searchContent.contains("super-secret"))
    }

    @Test("Encoding and decoding with isMasked and customLabel")
    func serialization() throws {
        let item = ClipItem(
            kind: .text,
            textContent: "token-abc-xyz",
            isFavorite: true,
            sourceAppName: "Terminal",
            isMasked: true,
            customLabel: "Prod Secret"
        )
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipItem.self, from: data)

        #expect(decoded.id == item.id)
        #expect(decoded.textContent == "token-abc-xyz")
        #expect(decoded.isMasked == true)
        #expect(decoded.customLabel == "Prod Secret")
        #expect(decoded.preview == "******")
        #expect(decoded.unmaskedPreview == "token-abc-xyz")
    }
}
