import Foundation
import SwiftData

// MARK: - JSON Decoding Types

struct MarkerDataJSON: Decodable {
    struct CategoryJSON: Decodable {
        let name: String
        let displayOrder: Int
    }

    struct MarkerJSON: Decodable {
        let displayName: String
        let category: String
        let defaultUnit: String
        let defaultReferenceLow: Double?
        let defaultReferenceHigh: Double?
        let plausibleMin: Double?
        let plausibleMax: Double?
        let higherIsBetter: Bool
        let aliases: [String]
    }

    let categories: [CategoryJSON]
    let markers: [MarkerJSON]
}

// MARK: - MarkerLibrary

@MainActor
final class MarkerLibrary {

    static let shared = MarkerLibrary()

    private init() {}

    /// Seeds the SwiftData store with predefined markers if not already seeded.
    /// Idempotent: calling multiple times has no additional effect.
    func seedIfNeeded(context: ModelContext, bundle: Bundle = .main) {
        guard notYetSeeded(context: context) else { return }
        do {
            let data = try loadJSON(from: bundle)
            seed(context: context, with: data)
        } catch {
            // Silent failure: no system-defined markers will be available
        }
    }

    /// Seeds using raw JSON data — used in unit tests to avoid bundle lookup issues.
    func seedIfNeeded(context: ModelContext, jsonData: Data) {
        guard notYetSeeded(context: context) else { return }
        if let data = try? JSONDecoder().decode(MarkerDataJSON.self, from: jsonData) {
            seed(context: context, with: data)
        }
    }

    // MARK: - Private

    private func notYetSeeded(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { def in
                def.isSystemDefined == true
            }
        )
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        return existingCount == 0
    }

    private func loadJSON(from bundle: Bundle) throws -> MarkerDataJSON {
        guard let url = bundle.url(forResource: "MarkerData", withExtension: "json") else {
            throw MarkerLibraryError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(MarkerDataJSON.self, from: data)
    }

    private func seed(context: ModelContext, with data: MarkerDataJSON) {
        // Create categories and build a lookup map
        var categoryMap: [String: MarkerCategory] = [:]
        for catJSON in data.categories {
            let category = MarkerCategory(name: catJSON.name, displayOrder: catJSON.displayOrder)
            context.insert(category)
            categoryMap[catJSON.name] = category
        }

        // Create marker definitions
        for markerJSON in data.markers {
            let category = categoryMap[markerJSON.category]
            let definition = MarkerDefinition(
                displayName: markerJSON.displayName,
                category: category,
                defaultUnit: markerJSON.defaultUnit,
                defaultReferenceLow: markerJSON.defaultReferenceLow,
                defaultReferenceHigh: markerJSON.defaultReferenceHigh,
                plausibleMin: markerJSON.plausibleMin,
                plausibleMax: markerJSON.plausibleMax,
                higherIsBetter: markerJSON.higherIsBetter,
                aliases: markerJSON.aliases,
                isSystemDefined: true
            )
            context.insert(definition)
        }

        try? context.save()
    }

    enum MarkerLibraryError: Error {
        case fileNotFound
        case decodingFailed
    }
}
