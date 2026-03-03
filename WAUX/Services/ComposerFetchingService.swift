//
//  ComposerFetchingService.swift
//  Vaux Cue Sheet
//
//  Created by AI Assistant on 03/10/2025.
//

import Foundation
import AVFoundation

class ComposerFetchingService {
    private var lastSearchDirectory: URL?

    // Stable key used to persist composer assignments across save/load
    static func composerAssignmentKey(catalogID: String, title: String) -> String {
        let cleanedCatalogID = catalogID.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(cleanedCatalogID)|\(cleanedTitle)"
    }
    
    // Save last directory to UserDefaults
    private func saveLastDirectory(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: "CueFileHelper_LastSearchDirectory")
    }
    
    // Load last directory from UserDefaults
    private func loadLastDirectory() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: "CueFileHelper_LastSearchDirectory") else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
    // Extract composer from audio file metadata
    private func extractComposer(from fileURL: URL) -> String? {
        let asset = AVAsset(url: fileURL)
        
        // Try to get composer from metadata
        for item in asset.commonMetadata {
            if item.commonKey == .commonKeyCreator || item.identifier?.rawValue.contains("composer") == true {
                if let stringValue = item.stringValue {
                    return stringValue
                }
            }
        }
        
        // Also check ID3 metadata for MP3 files
        let id3Metadata = asset.metadata(forFormat: .id3Metadata)
        for item in id3Metadata {
            if item.identifier?.rawValue.contains("TCOM") == true || 
               item.commonKey == .commonKeyCreator {
                if let stringValue = item.stringValue {
                    return stringValue
                }
            }
        }
        
        return nil
    }
    
    // Find audio files matching both catalog ID and title in a directory
    private func findMatchingFiles(in directory: URL, catalogID: String, title: String) -> [URL] {
        let fileManager = FileManager.default
        var matchingFiles: [URL] = []
        
        // Prepare catalog ID and title for comparison
        let cleanCatalogID = catalogID
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let cleanTitle = title
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Skip if both are empty
        guard !cleanCatalogID.isEmpty || !cleanTitle.isEmpty else {
            return []
        }
        
        // Get all files in directory and subdirectories
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        let audioExtensions = ["mp3", "wav", "aiff", "aif", "m4a", "flac"]
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            guard audioExtensions.contains(fileExtension) else { continue }
            
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            
            // Check if filename contains both catalog ID and title (case insensitive)
            var matchesCatalogID = cleanCatalogID.isEmpty
            var matchesTitle = cleanTitle.isEmpty
            
            if !cleanCatalogID.isEmpty {
                matchesCatalogID = fileName.range(of: cleanCatalogID, options: .caseInsensitive) != nil
            }
            
            if !cleanTitle.isEmpty {
                matchesTitle = fileName.range(of: cleanTitle, options: .caseInsensitive) != nil
            }
            
            if matchesCatalogID && matchesTitle {
                matchingFiles.append(fileURL)
            }
        }
        
        // If no matches, try replacing underscores with spaces and hyphens with spaces
        if matchingFiles.isEmpty {
            let catalogIDWithSpaces = cleanCatalogID
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
            
            let titleWithSpaces = cleanTitle
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
            
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return []
            }
            
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                      resourceValues.isRegularFile == true else {
                    continue
                }
                
                let fileExtension = fileURL.pathExtension.lowercased()
                guard audioExtensions.contains(fileExtension) else { continue }
                
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                
                var matchesCatalogID = catalogIDWithSpaces.isEmpty
                var matchesTitle = titleWithSpaces.isEmpty
                
                if !catalogIDWithSpaces.isEmpty {
                    matchesCatalogID = fileName.range(of: catalogIDWithSpaces, options: .caseInsensitive) != nil
                }
                
                if !titleWithSpaces.isEmpty {
                    matchesTitle = fileName.range(of: titleWithSpaces, options: .caseInsensitive) != nil
                }
                
                if matchesCatalogID && matchesTitle {
                    matchingFiles.append(fileURL)
                }
            }
        }
        
        return matchingFiles
    }
    
    // Get composer for a catalog ID and title from a directory
    func getComposer(for catalogID: String, title: String, in directory: URL?) -> String {
        var searchDirectory = directory ?? lastSearchDirectory
        
        // If no directory is set, prompt user
        if searchDirectory == nil {
            searchDirectory = loadLastDirectory()
        }
        
        guard let searchDirectory = searchDirectory else {
            return ""
        }
        
        lastSearchDirectory = searchDirectory
        saveLastDirectory(searchDirectory)
        
        // Find matching files using both catalog ID and title
        let matchingFiles = findMatchingFiles(in: searchDirectory, catalogID: catalogID, title: title)
        
        // Try to extract composer from the first matching file
        for file in matchingFiles {
            if let composer = extractComposer(from: file), !composer.isEmpty {
                return composer
            }
        }
        
        return ""
    }
    
    // Batch process events to fetch composers
    func fetchComposers(for events: [CueEvent], in directory: URL?, progressHandler: @escaping (Int, Int) -> Void) -> [CueEvent] {
        var updatedEvents = events
        
        for (index, var event) in updatedEvents.enumerated() {
            // Search using both catalog ID and title
            event.composer = getComposer(for: event.catalogID, title: event.title, in: directory)
            updatedEvents[index] = event
            progressHandler(index + 1, updatedEvents.count)
        }
        
        return updatedEvents
    }
}
