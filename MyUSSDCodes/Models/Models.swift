import Foundation

enum VariableType: String, Codable, CaseIterable, Identifiable {
    case text
    case number
    case phone

    var id: String { rawValue }
}

/// An input the app asks for right before dialing (fills a `{placeholder}` in the code).
struct CodeVariable: Codable, Hashable, Identifiable {
    var key: String
    var label: String
    var type: VariableType
    var hint: String

    var id: String { key }

    init(key: String, label: String, type: VariableType = .text, hint: String = "") {
        self.key = key
        self.label = label
        self.type = type
        self.hint = hint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        label = try container.decode(String.self, forKey: .label)
        type = try container.decodeIfPresent(VariableType.self, forKey: .type) ?? .text
        hint = try container.decodeIfPresent(String.self, forKey: .hint) ?? ""
    }
}

struct UssdCode: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var description: String
    var code: String
    var category: String
    var tags: [String]
    var variables: [CodeVariable]
    var dangerous: Bool
    var source: String
    var notes: String
    var custom: Bool
    var groupId: String?

    init(
        id: String,
        name: String,
        description: String = "",
        code: String,
        category: String = "General",
        tags: [String] = [],
        variables: [CodeVariable] = [],
        dangerous: Bool = false,
        source: String = "",
        notes: String = "",
        custom: Bool = false,
        groupId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.code = code
        self.category = category
        self.tags = tags
        self.variables = variables
        self.dangerous = dangerous
        self.source = source
        self.notes = notes
        self.custom = custom
        self.groupId = groupId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        code = try container.decode(String.self, forKey: .code)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "General"
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        variables = try container.decodeIfPresent([CodeVariable].self, forKey: .variables) ?? []
        dangerous = try container.decodeIfPresent(Bool.self, forKey: .dangerous) ?? false
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        custom = try container.decodeIfPresent(Bool.self, forKey: .custom) ?? false
        groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
    }

    func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        return name.localizedCaseInsensitiveContains(trimmed)
            || code.localizedCaseInsensitiveContains(trimmed)
            || description.localizedCaseInsensitiveContains(trimmed)
            || category.localizedCaseInsensitiveContains(trimmed)
            || tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
    }
}

/// A user-created group ("super personalized" collections of codes).
struct CodeGroup: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var icon: String

    init(id: String, name: String, icon: String = "📁") {
        self.id = id
        self.name = name
        self.icon = icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "📁"
    }
}

/// A collection as published in the catalog repository.
struct CodeCollection: Codable {
    var id: String
    var name: String
    var description: String
    var version: Int
    var country: String
    var carrier: String
    var language: String
    var codes: [UssdCode]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        carrier = try container.decodeIfPresent(String.self, forKey: .carrier) ?? ""
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        codes = try container.decodeIfPresent([UssdCode].self, forKey: .codes) ?? []
    }
}

/// Everything the app persists locally.
struct AppData: Codable {
    var codes: [UssdCode] = []
    var groups: [CodeGroup] = []
    var importedCollections: [String] = []

    init() {}

    init(codes: [UssdCode], groups: [CodeGroup] = [], importedCollections: [String] = []) {
        self.codes = codes
        self.groups = groups
        self.importedCollections = importedCollections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codes = try container.decodeIfPresent([UssdCode].self, forKey: .codes) ?? []
        groups = try container.decodeIfPresent([CodeGroup].self, forKey: .groups) ?? []
        importedCollections = try container.decodeIfPresent([String].self, forKey: .importedCollections) ?? []
    }
}
