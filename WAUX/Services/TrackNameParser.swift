//
//  TrackNameParser.swift
//  Vaux Cue Sheet
//
//  Created by AI Assistant on 03/03/2026.
//

import Foundation

// Parsed name structure
struct ParsedName {
    let catalogID: String      // e.g., "UPM_MAT103_7" or "MISS_25FPS_MX_DCP_STEREO_WIP_250721"
    let title: String          // e.g., "Champions_Instrumental_Martin_8168"
    let fullName: String       // Original full name

    var isFadeIn: Bool { fullName.lowercased().contains("(fade in)") }
    var isFadeOut: Bool { fullName.lowercased().contains("(fade out)") }
    var isCrossFade: Bool { fullName.lowercased().contains("(cross fade)") }
    var isFade: Bool { isFadeIn || isFadeOut || isCrossFade }
}

enum TrackNameParser {
    /// Parse a clip name into catalog ID and title
    /// Example: "UPM_MAT103_7_Champions_Instrumental_Martin_8168-04.L" ->
    ///          catalogID: "UPM_MAT103_7", title: "Champions_Instrumental_Martin_8168"
    static func parse(_ clipName: String, skipCatalogExtraction: Bool = false) -> ParsedName {
        var trimmedName = clipName

        // Check if it's a fade event
        let lowerName = clipName.lowercased()
        if lowerName.contains("(fade in)") {
            return ParsedName(catalogID: "FADE_IN", title: "", fullName: clipName)
        } else if lowerName.contains("(fade out)") {
            return ParsedName(catalogID: "FADE_OUT", title: "", fullName: clipName)
        } else if lowerName.contains("(cross fade)") {
            return ParsedName(catalogID: "CROSS_FADE", title: "", fullName: clipName)
        }

        // Step 1: Remove channel suffix (.L/.R/.A1/...) only.
        // We intentionally keep trailing "-NN" at this stage because some catalogs include it.
        var channelTrimmedName = clipName
        if let channelSuffixMatch = channelTrimmedName.range(
            of: "\\.(L|R|A\\d+|Ls|LFE|C|Rs)$",
            options: .regularExpression
        ) {
            channelTrimmedName = String(channelTrimmedName[..<channelSuffixMatch.lowerBound])
        }

        // If skip catalog extraction is enabled, use the cleaned name as catalog ID
        if skipCatalogExtraction {
            trimmedName = channelTrimmedName
            if let takeSuffixMatch = trimmedName.range(of: "[-.]\\d+$", options: .regularExpression) {
                trimmedName = String(trimmedName[..<takeSuffixMatch.lowerBound])
            }
            return normalizeFallback(catalogID: trimmedName, title: "", fullName: clipName)
        }

        // Step 2: Handle trailing catalog formats like:
        // "CROSSROADS_..._TSH_289_002-19" -> title: "CROSSROADS_...", catalogID: "TSH_289_002-19"
        if let trailingCatalogRange = channelTrimmedName.range(
            of: "_([A-Z]{2,}[A-Z0-9]*_\\d+(?:_\\d+)*-\\d+)$",
            options: .regularExpression
        ) {
            let titlePart = String(channelTrimmedName[..<trailingCatalogRange.lowerBound])
            let catalogPart = String(channelTrimmedName[channelTrimmedName.index(after: trailingCatalogRange.lowerBound)...])
            // Heuristic: this trailing-catalog format is used with descriptive titles.
            // Guard against all-uppercase catalog-like names such as MISS_25FPS_..._WIP_250721-152.
            let hasLowercaseInTitle = titlePart.range(of: "[a-z]", options: .regularExpression) != nil
            if !titlePart.isEmpty && hasLowercaseInTitle {
                return normalizeFallback(catalogID: catalogPart, title: titlePart, fullName: clipName)
            }
        }

        // Step 3: General cleanup for regular formats.
        trimmedName = channelTrimmedName
        if let takeSuffixMatch = trimmedName.range(of: "[-.]\\d+$", options: .regularExpression) {
            trimmedName = String(trimmedName[..<takeSuffixMatch.lowerBound])
        }

        // Step 4: Handle leading catalog formats like:
        // "UPRIGHT_2FM_035_015_Cold_Shadows(...)" -> catalogID: "UPRIGHT_2FM_035_015", title: "Cold_Shadows(...)"
        let prefixRegex = try? NSRegularExpression(pattern: "^(_?[A-Z]+(?:_[A-Z0-9]+)*_\\d+(?:_\\d+)*)_(.+)$")
        if let regex = prefixRegex,
           let result = regex.firstMatch(in: trimmedName, range: NSRange(trimmedName.startIndex..., in: trimmedName)),
           let codeRange = Range(result.range(at: 1), in: trimmedName),
           let titleRange = Range(result.range(at: 2), in: trimmedName) {
            return normalizeFallback(
                catalogID: String(trimmedName[codeRange]),
                title: String(trimmedName[titleRange]),
                fullName: clipName
            )
        }

        // Step 5: Extract catalog ID and title based on the original pattern
        // Pattern: Find the first digit, then find the first letter after it - that's where the title starts
        // Example: "UPM_NTP504_3_Take_My_Hand..." -> catalogID: "UPM_NTP504_3", title: "Take_My_Hand..."
        var catalogID = trimmedName
        var title = ""

        // Find the first digit in the string
        if let firstDigitRange = trimmedName.range(of: "\\d", options: .regularExpression) {
            let firstDigitIndex = firstDigitRange.lowerBound

            // Look for the first letter after this digit (skipping any non-letter characters)
            let afterDigitString = String(trimmedName[firstDigitIndex...])
            if let firstLetterAfterDigitRange = afterDigitString.range(of: "[A-Za-z]", options: .regularExpression) {
                let letterIndex = trimmedName.index(
                    firstDigitIndex,
                    offsetBy: afterDigitString.distance(
                        from: afterDigitString.startIndex,
                        to: firstLetterAfterDigitRange.lowerBound
                    )
                )

                // Everything before this letter is the catalog ID
                // Only trim trailing separators, preserve leading ones
                let catalogPart = String(trimmedName[..<letterIndex])
                catalogID = catalogPart.trimmingCharacters(in: CharacterSet(charactersIn: "_-"))

                // If the original string started with underscore, preserve it
                if trimmedName.hasPrefix("_") && !catalogID.hasPrefix("_") {
                    catalogID = "_" + catalogID
                }
                title = String(trimmedName[letterIndex...])
            }
        }

        return normalizeFallback(catalogID: catalogID, title: title, fullName: clipName)
    }

    private static func normalizeFallback(catalogID: String, title: String, fullName: String) -> ParsedName {
        // If parsing could not extract a title but did produce a catalog token,
        // treat the token as title and leave catalog empty.
        if title.isEmpty && !catalogID.isEmpty {
            return ParsedName(catalogID: "", title: catalogID, fullName: fullName)
        }
        return ParsedName(catalogID: catalogID, title: title, fullName: fullName)
    }
}
