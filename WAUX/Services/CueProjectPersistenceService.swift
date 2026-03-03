//
//  CueProjectPersistenceService.swift
//  Vaux Cue Sheet
//
//  Created by AI Assistant on 03/03/2026.
//

import Foundation

struct CueProjectMetadata: Codable {
    let version: Int
    let originalFileName: String
    let replaceUnderscoresWithSpaces: Bool
    let skipCatalogExtraction: Bool
    let manualGroupingAssociations: [String: String]
    let composerAssignments: [String: String]

    private enum CodingKeys: String, CodingKey {
        case version
        case originalFileName
        case replaceUnderscoresWithSpaces
        case skipCatalogExtraction
        case manualGroupingAssociations
        case composerAssignments
    }

    init(
        version: Int,
        originalFileName: String,
        replaceUnderscoresWithSpaces: Bool,
        skipCatalogExtraction: Bool,
        manualGroupingAssociations: [String: String],
        composerAssignments: [String: String]
    ) {
        self.version = version
        self.originalFileName = originalFileName
        self.replaceUnderscoresWithSpaces = replaceUnderscoresWithSpaces
        self.skipCatalogExtraction = skipCatalogExtraction
        self.manualGroupingAssociations = manualGroupingAssociations
        self.composerAssignments = composerAssignments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        originalFileName = try container.decode(String.self, forKey: .originalFileName)
        replaceUnderscoresWithSpaces = try container.decodeIfPresent(Bool.self, forKey: .replaceUnderscoresWithSpaces) ?? true
        skipCatalogExtraction = try container.decodeIfPresent(Bool.self, forKey: .skipCatalogExtraction) ?? false
        manualGroupingAssociations = try container.decodeIfPresent([String: String].self, forKey: .manualGroupingAssociations) ?? [:]
        composerAssignments = try container.decodeIfPresent([String: String].self, forKey: .composerAssignments) ?? [:]
    }
}

struct LoadedCueProject {
    let cueFileURL: URL
    let metadata: CueProjectMetadata
}

final class CueProjectPersistenceService {
    private let metadataFileName = "project.json"
    private let projectVersion = 2

    func saveProject(
        at projectURL: URL,
        originalFileURL: URL,
        replaceUnderscoresWithSpaces: Bool,
        skipCatalogExtraction: Bool,
        manualGroupingAssociations: [String: String],
        composerAssignments: [String: String]
    ) throws {
        let fileManager = FileManager.default
        let finalProjectURL = projectURL.pathExtension.isEmpty
            ? projectURL.appendingPathExtension("wauxproject")
            : projectURL

        if fileManager.fileExists(atPath: finalProjectURL.path) {
            try fileManager.removeItem(at: finalProjectURL)
        }

        try fileManager.createDirectory(at: finalProjectURL, withIntermediateDirectories: true)

        let copiedCueFileName = originalFileURL.lastPathComponent
        let copiedCueFileURL = finalProjectURL.appendingPathComponent(copiedCueFileName)
        try fileManager.copyItem(at: originalFileURL, to: copiedCueFileURL)

        let metadata = CueProjectMetadata(
            version: projectVersion,
            originalFileName: copiedCueFileName,
            replaceUnderscoresWithSpaces: replaceUnderscoresWithSpaces,
            skipCatalogExtraction: skipCatalogExtraction,
            manualGroupingAssociations: manualGroupingAssociations,
            composerAssignments: composerAssignments
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let metadataData = try encoder.encode(metadata)
        let metadataURL = finalProjectURL.appendingPathComponent(metadataFileName)
        try metadataData.write(to: metadataURL, options: .atomic)
    }

    func loadProject(from projectURL: URL) throws -> LoadedCueProject {
        let metadataURL = projectURL.appendingPathComponent(metadataFileName)
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try JSONDecoder().decode(CueProjectMetadata.self, from: metadataData)

        let cueFileURL = projectURL.appendingPathComponent(metadata.originalFileName)
        guard FileManager.default.fileExists(atPath: cueFileURL.path) else {
            throw NSError(
                domain: "CueProjectPersistenceService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Original cue file is missing from project package."]
            )
        }

        return LoadedCueProject(cueFileURL: cueFileURL, metadata: metadata)
    }
}

extension Notification.Name {
    static let saveCueProjectRequested = Notification.Name("saveCueProjectRequested")
    static let loadCueProjectRequested = Notification.Name("loadCueProjectRequested")
}
