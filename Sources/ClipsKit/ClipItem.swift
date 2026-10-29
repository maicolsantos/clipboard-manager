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
    public var isMasked: Bool
    public var customLabel: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        kind: ClipKind,
        textContent: String? = nil,
        imageFileName: String? = nil,
        filePaths: [String]? = nil,
        isFavorite: Bool = false,
        sourceAppName: String? = nil,
        isMasked: Bool = false,
        customLabel: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.textContent = textContent
        self.imageFileName = imageFileName
        self.filePaths = filePaths
        self.isFavorite = isFavorite
        self.sourceAppName = sourceAppName
        self.isMasked = isMasked
        self.customLabel = customLabel
    }

    enum CodingKeys: String, CodingKey {
        case id, createdAt, kind, textContent, imageFileName, filePaths, isFavorite, sourceAppName, isMasked, customLabel
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.kind = try c.decode(ClipKind.self, forKey: .kind)
        self.textContent = try c.decodeIfPresent(String.self, forKey: .textContent)
        self.imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
        self.filePaths = try c.decodeIfPresent([String].self, forKey: .filePaths)
        self.isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        self.sourceAppName = try c.decodeIfPresent(String.self, forKey: .sourceAppName)
        self.isMasked = try c.decodeIfPresent(Bool.self, forKey: .isMasked) ?? false
        self.customLabel = try c.decodeIfPresent(String.self, forKey: .customLabel)
    }

    public var unmaskedPreview: String {
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

    public var preview: String {
        if isMasked {
            return "******"
        }
        return unmaskedPreview
    }

    public var searchContent: String {
        var parts: [String] = []
        if let label = customLabel {
            parts.append(label)
        }
        if let app = sourceAppName {
            parts.append(app)
        }
        if !isMasked {
            parts.append(unmaskedPreview)
            if let text = textContent {
                parts.append(text)
            }
        }
        return parts.joined(separator: " ").lowercased()
    }
}
