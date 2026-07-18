import Foundation

enum ImportError: LocalizedError {
    case emptyCollection

    var errorDescription: String? {
        switch self {
        case .emptyCollection: return "The collection has no codes."
        }
    }
}

/// Single source of truth: JSON-file persistence plus the bundled seed catalog.
@MainActor
final class CodeStore: ObservableObject {
    @Published private(set) var data = AppData()

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        fileURL = support.appendingPathComponent("app-data.json")
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let raw = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            seed()
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let raw = try? encoder.encode(data) {
            try? raw.write(to: fileURL, options: .atomic)
        }
    }

    /// Loads the bundled GSM standard collection (verbatim copy of the catalog repo file).
    private func seed() {
        guard let url = Bundle.main.url(forResource: "gsm-standard", withExtension: "json"),
              let raw = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(CodeCollection.self, from: raw)
        else { return }
        data = AppData(codes: collection.codes, importedCollections: [collection.id])
        persist()
    }

    // MARK: - Codes

    func upsert(code: UssdCode) {
        data.codes.removeAll { $0.id == code.id }
        data.codes.append(code)
        persist()
    }

    func deleteCode(id: String) {
        data.codes.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Groups

    func upsert(group: CodeGroup) {
        data.groups.removeAll { $0.id == group.id }
        data.groups.append(group)
        persist()
    }

    func deleteGroup(id: String) {
        data.groups.removeAll { $0.id == id }
        data.codes = data.codes.map { code in
            var code = code
            if code.groupId == id { code.groupId = nil }
            return code
        }
        persist()
    }

    // MARK: - Import / reset

    /// Parses a collection JSON and merges it in (same-id codes are replaced).
    @discardableResult
    func importCollection(json raw: Data) throws -> Int {
        let collection = try JSONDecoder().decode(CodeCollection.self, from: raw)
        guard !collection.codes.isEmpty else { throw ImportError.emptyCollection }
        data.codes.removeAll { existing in
            collection.codes.contains { $0.id == existing.id }
        }
        data.codes.append(contentsOf: collection.codes)
        if !data.importedCollections.contains(collection.id) {
            data.importedCollections.append(collection.id)
        }
        persist()
        return collection.codes.count
    }

    @discardableResult
    func importCollection(from url: URL) async throws -> Int {
        let (raw, _) = try await URLSession.shared.data(from: url)
        return try importCollection(json: raw)
    }

    /// Wipes local data and reloads the bundled seed collection.
    func reset() {
        try? FileManager.default.removeItem(at: fileURL)
        data = AppData()
        seed()
    }
}
