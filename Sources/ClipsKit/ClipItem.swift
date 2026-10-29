import Foundation

public enum ClipKind: String, Codable, Sendable {
    case text
    case url
    case image
    case files
}

public struct ClipItem: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public let kind: ClipKind
    public var textContent: String?
    public var imageFileName: String?
    public var filePaths: [String]?
    public var isFavorite: Bool
    public var sourceAppName: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: ClipKind,
        textContent: String? = nil,
        imageFileName: String? = nil,
        filePaths: [String]? = nil,
        isFavorite: Bool = false,
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.textContent = textContent
        self.imageFileName = imageFileName
        self.filePaths = filePaths
        self.isFavorite = isFavorite
        self.sourceAppName = sourceAppName
    }

    public var preview: String {
        switch kind {
        case .text, .url:
            return (textContent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return "Image"
        case .files:
            if let files = filePaths, !files.isEmpty {
                return files.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
            }
            return "Files"
        }
    }

    public var searchContent: String {
        var parts: [String] = [preview]
        if let app = sourceAppName {
            parts.append(app)
        }
        if let text = textContent {
            parts.append(text)
        }
        return parts.joined(separator: " ").lowercased()
    }
}
