//
//  CueFileParsingService.swift
//  Vaux Cue Sheet
//
//  Created by AI Assistant on 03/10/2025.
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

// Manual grouping associations
struct ManualGrouping {
    var associations: [String: String] = [:]  // catalogID -> targetGroupID
    
    mutating func associate(catalogID: String, with targetGroupID: String) {
        associations[catalogID] = targetGroupID
    }
    
    mutating func removeAssociation(for catalogID: String) {
        associations.removeValue(forKey: catalogID)
    }
    
    func getGroupID(for catalogID: String) -> String? {
        return associations[catalogID]
    }
    
    func hasManualAssociation(for catalogID: String) -> Bool {
        return associations[catalogID] != nil
    }
}

// Container for all parsing layers results
struct CueParsingResult {
    let layer1: [CueEvent]  // Raw parsed events
    var layer2: [CueEvent]  // Fades aggregated with clips
    var layer3: [CueEvent]  // Merged across channels
    var layer4: [CueEvent]  // Final aggregation
    var manualGrouping: ManualGrouping = ManualGrouping()  // Manual grouping associations
}

// CueEvent structure - used throughout the parsing layers
struct CueEvent: Identifiable {
    let id = UUID()
    var channel: Int
    var eventID: Int
    var catalogID: String          // The catalog/ID prefix (mutable for cross fade conversions)
    var title: String              // The descriptive title
    var originalClipName: String   // Full original clip name
    var startTime: String
    var endTime: String
    var duration: String
    var state: String
    var uniqueTitles: Set<String>  // Track unique titles when merging
    var composer: String
}

class CueFileParsingService {
    
    // MARK: - Utility Functions
    
    /// Parse timecode format (HH:MM:SS:FF) to total seconds
    private func parseTimecode(_ timecode: String) -> Int {
        let withoutFrames = String(timecode.dropLast(3))
        let parts = withoutFrames.components(separatedBy: ":")
        
        guard parts.count >= 3 else { return 0 }
        
        let hours = Int(parts[0]) ?? 0
        let minutes = Int(parts[1]) ?? 0
        let seconds = Int(parts[2]) ?? 0
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    /// Calculate duration between two timecodes
    private func calculateDuration(from startTime: String, to endTime: String) -> Int {
        let startSeconds = parseTimecode(startTime)
        let endSeconds = parseTimecode(endTime)
        return endSeconds - startSeconds
    }
    
    /// Parse duration format (MM:SS or HH:MM:SS) to seconds
    private func parseDuration(_ durationStr: String) -> Int {
        let parts = durationStr.components(separatedBy: ":")
        
        guard parts.count >= 2 else { return 0 }
        
        var hours = 0
        var minutes = 0
        var seconds = 0
        
        if parts.count == 2 {
            minutes = Int(parts[0]) ?? 0
            seconds = Int(parts[1]) ?? 0
        } else if parts.count >= 3 {
            hours = Int(parts[0]) ?? 0
            minutes = Int(parts[1]) ?? 0
            seconds = Int(parts[2]) ?? 0
        }
        
        return hours * 3600 + minutes * 60 + seconds
    }
    
    /// Format duration as MM:SS
    private func formatDuration(_ totalSeconds: Int) -> String {
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Name Parsing
    
    /// Parse a clip name into catalog ID and title
    /// Example: "UPM_MAT103_7_Champions_Instrumental_Martin_8168-04.L" -> 
    ///          catalogID: "UPM_MAT103_7", title: "Champions_Instrumental_Martin_8168"
    func parseName(_ clipName: String, skipCatalogExtraction: Bool = false) -> ParsedName {
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
        
        // Step 1: Remove common suffixes (.L, .R, .A1, track numbers, etc.)
        // First remove channel suffixes like -03.L, .L, .R, .A1
        if let suffixMatch = trimmedName.range(of: "[-.]\\w+\\.(L|R|A\\d+)$", options: .regularExpression) {
            trimmedName = String(trimmedName[..<suffixMatch.lowerBound])
        } else if let suffixMatch = trimmedName.range(of: "\\.(L|R|A\\d+)$", options: .regularExpression) {
            trimmedName = String(trimmedName[..<suffixMatch.lowerBound])
        }
        
        // Remove remaining track/take numbers like .1, .2, etc.
        if let suffixMatch = trimmedName.range(of: "\\.\\d+$", options: .regularExpression) {
            trimmedName = String(trimmedName[..<suffixMatch.lowerBound])
        }
        
        // If skip catalog extraction is enabled, use the cleaned name as catalog ID
        if skipCatalogExtraction {
            return ParsedName(catalogID: trimmedName, title: "", fullName: clipName)
        }
        
        // Step 2: Extract catalog ID and title based on the pattern
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
                let letterIndex = trimmedName.index(firstDigitIndex, offsetBy: afterDigitString.distance(from: afterDigitString.startIndex, to: firstLetterAfterDigitRange.lowerBound))
                
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
        
        return ParsedName(catalogID: catalogID, title: title, fullName: clipName)
    }
    
    /// Get simplified name (catalog ID only) - convenience method for testing
    func getSimplifiedName(_ clipName: String) -> String {
        return parseName(clipName).catalogID
    }
    
    // MARK: - Layer 1: Parse Raw File
    
    /// Layer 1: Parse each line into a CueEvent with parsed names
    func parseRawFile(lines: [String], skipCatalogExtraction: Bool = false) -> [CueEvent] {
        var allEvents: [CueEvent] = []
        var currentTrack = 1  // Track/channel counter (increments when eventID is 1)
        
        print("\n📄 LAYER 1: Parsing raw file...")
        
        // First pass: Parse all events including muted ones
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Debug first few lines
            if index < 3 {
                print("   🔍 [Debug] Line \(index): '\(trimmedLine)'")
            }
            
            // Skip empty lines and header
            guard !trimmedLine.isEmpty,
                  trimmedLine.first?.isNumber ?? false,
                  !trimmedLine.lowercased().contains("channel"),
                  !trimmedLine.lowercased().contains("event"),
                  !trimmedLine.lowercased().contains("clip name") else { continue }
            
            // Handle both tab and space-separated data
            let fields: [String]
            if trimmedLine.contains("\t") {
                fields = trimmedLine.components(separatedBy: "\t")
            } else {
                // For space-separated data, split by whitespace and filter empty strings
                fields = trimmedLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            }
            
            guard fields.count >= 6 else { continue }
            
            let stereoChannel = Int(fields[0].trimmingCharacters(in: .whitespaces)) ?? 0
            let eventID = Int(fields[1].trimmingCharacters(in: .whitespaces)) ?? 0
            
            // Increment track when eventID is 1 (new track starts)
            if eventID == 1 {
                currentTrack += 1
            }
            
            let clipName = fields[2].trimmingCharacters(in: .whitespaces)
            let startTime = fields[3].trimmingCharacters(in: .whitespaces)
            let endTime = fields[4].trimmingCharacters(in: .whitespaces)
            let durationStr = fields[5].trimmingCharacters(in: .whitespaces)
            let state = fields.count > 6 ? fields[6].trimmingCharacters(in: .whitespaces) : "Unmuted"
            
            // Debug logging for first few events
            if allEvents.count < 5 {
                print("   🔍 [Debug] Fields: \(fields)")
                print("   📋 [Debug] Track: \(currentTrack), StereoCh: \(stereoChannel), EventID: \(eventID), Clip: '\(clipName)'")
            }
            
            // Parse the name
            let parsed = parseName(clipName, skipCatalogExtraction: skipCatalogExtraction)
            
            let event = CueEvent(
                channel: currentTrack,  // Use track number instead of stereo channel
                eventID: eventID,
                catalogID: parsed.catalogID,
                title: parsed.title,
                originalClipName: clipName,
                startTime: startTime,
                endTime: endTime,
                duration: durationStr,
                state: state,
                uniqueTitles: [parsed.title],
                composer: ""
            )
            
            allEvents.append(event)
            
            print("   T\(currentTrack) S\(stereoChannel) E\(eventID): \(parsed.catalogID) | \(parsed.title.isEmpty ? "(fade)" : parsed.title) \(state == "Muted" ? "[MUTED]" : "")")
        }
        
        // Second pass: Convert cross fades adjacent to muted clips
        print("   🔧 Converting cross fades adjacent to muted clips...")
        var convertedCount = 0
        for i in 0..<allEvents.count {
            if allEvents[i].state == "Muted" {
                // Check previous event - if it's a cross fade, convert to fade out
                if i > 0 && allEvents[i - 1].catalogID == "CROSS_FADE" {
                    print("      ⬇️ Converting CROSS_FADE (before muted clip) to FADE_OUT")
                    allEvents[i - 1].catalogID = "FADE_OUT"
                    convertedCount += 1
                }
                
                // Check next event - if it's a cross fade, convert to fade in
                if i < allEvents.count - 1 && allEvents[i + 1].catalogID == "CROSS_FADE" {
                    print("      ⬆️ Converting CROSS_FADE (after muted clip) to FADE_IN")
                    allEvents[i + 1].catalogID = "FADE_IN"
                    convertedCount += 1
                }
            }
        }
        
        if convertedCount > 0 {
            print("   ✅ Converted \(convertedCount) cross fade(s) due to muted clips")
        }
        
        // Third pass: Filter out muted events
        let events = allEvents.filter { $0.state != "Muted" }
        
        print("   ✅ Parsed \(events.count) events (filtered out \(allEvents.count - events.count) muted)")
        return events
    }
    
    // MARK: - Layer 2: Aggregate Fades with Clips
    
    /// Layer 2: Merge fades with adjacent clips according to rules
    func aggregateFadesWithClips(events: [CueEvent], manualGrouping: ManualGrouping = ManualGrouping()) -> [CueEvent] {
        var aggregated: [CueEvent] = []
        
        print("\n🔀 LAYER 2: Aggregating fades with clips...")
        
        // Group by channel first
        let eventsByChannel = Dictionary(grouping: events) { $0.channel }
        
        for channel in eventsByChannel.keys.sorted() {
            guard let channelEvents = eventsByChannel[channel] else { continue }
            
            print("   Processing channel \(channel)...")
            
            var i = 0
            while i < channelEvents.count {
                let event = channelEvents[i]
                
                // Skip if it's a standalone fade (shouldn't happen but handle gracefully)
                if event.catalogID == "FADE_IN" || event.catalogID == "FADE_OUT" || event.catalogID == "CROSS_FADE" {
                    i += 1
                    continue
                }
                
                var mergedEvent = event
                var nextIndex = i + 1
                
                // Look backwards for fade in or cross fade from different catalog
                if i > 0 {
                    let prevEvent = channelEvents[i - 1]
                    if prevEvent.catalogID == "FADE_IN" {
                        // Only merge if temporally adjacent (fade ends where event starts)
                        if prevEvent.endTime == event.startTime {
                            print("      ⬅️ Merging FADE_IN with \(event.catalogID)")
                            mergedEvent.startTime = prevEvent.startTime
                        } else {
                            print("      ⏭️ Skipping non-adjacent FADE_IN (gap: \(prevEvent.endTime) to \(event.startTime))")
                        }
                    } else if prevEvent.catalogID == "CROSS_FADE" {
                        // Check if there's an event before the cross fade
                        if i > 1 {
                            let beforeCrossFade = channelEvents[i - 2]
                            // Only include if previous event has different catalog (cross fade counted twice)
                            // If same catalog, it would have been merged already
                            if beforeCrossFade.catalogID != event.catalogID && beforeCrossFade.catalogID != "FADE_IN" && beforeCrossFade.catalogID != "FADE_OUT" && beforeCrossFade.catalogID != "CROSS_FADE" {
                                // Different catalog ID - cross fade belongs to both
                                print("      ⬅️ Including CROSS_FADE (different catalog) in \(event.catalogID)")
                                mergedEvent.startTime = prevEvent.startTime
                            }
                        }
                    }
                }
                
                // Look forwards and keep merging as long as we find cross fades with same catalog
                while nextIndex < channelEvents.count {
                    let nextEvent = channelEvents[nextIndex]
                    
                    if nextEvent.catalogID == "FADE_OUT" {
                        // Only merge if temporally adjacent (event ends where fade starts)
                        if mergedEvent.endTime == nextEvent.startTime {
                            print("      ➡️ Merging FADE_OUT with \(event.catalogID)")
                            mergedEvent.endTime = nextEvent.endTime
                            nextIndex += 1
                        } else {
                            print("      ⏭️ Skipping non-adjacent FADE_OUT (gap: \(mergedEvent.endTime) to \(nextEvent.startTime))")
                            nextIndex += 1
                        }
                        break // Fade out ends the chain
                    } else if nextEvent.catalogID == "CROSS_FADE" {
                        // Cross fade - check what comes after
                        if nextIndex < channelEvents.count - 1 {
                            let afterCrossFade = channelEvents[nextIndex + 1]
                            
                            // Check if we should merge based on manual grouping or catalog ID match
                            let shouldMerge: Bool
                            if manualGrouping.hasManualAssociation(for: event.catalogID) {
                                // Use manual grouping
                                let eventGroupID = manualGrouping.getGroupID(for: event.catalogID)!
                                let afterCrossFadeGroupID = manualGrouping.getGroupID(for: afterCrossFade.catalogID)
                                shouldMerge = afterCrossFadeGroupID == eventGroupID
                                print("      🔗 Manual grouping check: \(event.catalogID) (group: \(eventGroupID)) vs \(afterCrossFade.catalogID) (group: \(afterCrossFadeGroupID ?? "none")) = \(shouldMerge)")
                            } else {
                                // Use original catalog ID matching
                                shouldMerge = afterCrossFade.catalogID == event.catalogID
                            }
                            
                            if shouldMerge {
                                // Same group - merge and continue looking
                                print("      🔗 Merging CROSS_FADE (same group) with \(event.catalogID)")
                                mergedEvent.endTime = afterCrossFade.endTime
                                mergedEvent.uniqueTitles.insert(afterCrossFade.title)
                                nextIndex += 2 // Skip cross fade and the clip
                                // Continue the loop to check if there's another cross fade
                            } else {
                                // Different catalog ID - cross fade belongs to both events (counted twice)
                                // Add to current event, but DON'T skip so next event can include it too
                                print("      ➡️ CROSS_FADE (different catalog) with \(event.catalogID) - will also apply to next")
                                mergedEvent.endTime = nextEvent.endTime
                                nextIndex += 1
                                break // Don't skip the next clip, it's different
                            }
                        } else {
                            // Cross fade at end - add to current
                            mergedEvent.endTime = nextEvent.endTime
                            nextIndex += 1
                            break
                        }
                    } else {
                        // Regular clip (not a fade) - stop merging
                        break
                    }
                }
                
                // Recalculate duration
                let durationSeconds = calculateDuration(from: mergedEvent.startTime, to: mergedEvent.endTime)
                mergedEvent.duration = formatDuration(durationSeconds)
                
                aggregated.append(mergedEvent)
                
                // Move to the next unprocessed event
                i = nextIndex
            }
        }
        
        print("   ✅ Aggregated to \(aggregated.count) events")
        
        // Debug: Print all events with their time ranges
        for (i, event) in aggregated.enumerated() {
            print("      Event \(i + 1): \(event.catalogID) from \(event.startTime) to \(event.endTime)")
        }
        
        return aggregated
    }
    
    // MARK: - Layer 3: Merge Across Channels
    
    /// Layer 3: Merge events from different channels that overlap in time and have same catalog ID
    func mergeAcrossChannels(events: [CueEvent]) -> [CueEvent] {
        var merged: [CueEvent] = []
        
        print("\n📡 LAYER 3: Merging across channels...")
        
        // Group by catalog ID
        let eventsByCatalog = Dictionary(grouping: events) { $0.catalogID }
        
        for catalogID in eventsByCatalog.keys.sorted() {
            guard let catalogEvents = eventsByCatalog[catalogID] else { continue }
            
            // Sort by start time
            let sortedEvents = catalogEvents.sorted { 
                parseTimecode($0.startTime) < parseTimecode($1.startTime) 
            }
            
            var processedIndices = Set<Int>()
            
            for i in 0..<sortedEvents.count {
                guard !processedIndices.contains(i) else { continue }
                
                var mergedEvent = sortedEvents[i]
                var minStart = parseTimecode(mergedEvent.startTime)
                var maxEnd = parseTimecode(mergedEvent.endTime)
                var minStartTimecode = mergedEvent.startTime  // Preserve original timecode with frames
                var maxEndTimecode = mergedEvent.endTime      // Preserve original timecode with frames
                processedIndices.insert(i)
                
                // Find all overlapping events
                for j in (i+1)..<sortedEvents.count {
                    guard !processedIndices.contains(j) else { continue }
                    
                    let otherEvent = sortedEvents[j]
                    let otherStart = parseTimecode(otherEvent.startTime)
                    let otherEnd = parseTimecode(otherEvent.endTime)
                    
                    // Check for overlap
                    if otherStart <= maxEnd {
                        print("      🔗 Merging overlapping events from channels \(mergedEvent.channel) and \(otherEvent.channel)")
                        
                        // Update min start time and preserve the original timecode string
                        if otherStart < minStart {
                            minStart = otherStart
                            minStartTimecode = otherEvent.startTime
                        }
                        
                        // Update max end time and preserve the original timecode string
                        if otherEnd > maxEnd {
                            maxEnd = otherEnd
                            maxEndTimecode = otherEvent.endTime
                        }
                        
                        mergedEvent.uniqueTitles.formUnion(otherEvent.uniqueTitles)
                        processedIndices.insert(j)
                    }
                }
                
                // Update times and duration based on merged range
                let durationSeconds = maxEnd - minStart
                mergedEvent.duration = formatDuration(durationSeconds)
                
                // Use the preserved original timecodes (with frame precision intact)
                mergedEvent.startTime = minStartTimecode
                mergedEvent.endTime = maxEndTimecode
                
                merged.append(mergedEvent)
            }
        }
        
        print("   ✅ Merged to \(merged.count) events")
        return merged
    }
    
    // MARK: - Layer 4: Final Aggregation
    
    /// Layer 4: Merge by catalog ID, summing up all durations and tracking unique titles
    func finalAggregation(events: [CueEvent], manualGrouping: ManualGrouping = ManualGrouping()) -> [CueEvent] {
        var aggregated: [String: (event: CueEvent, totalDurationSeconds: Int)] = [:]
        
        print("\n📊 LAYER 4: Final aggregation by catalog ID...")
        
        for event in events {
            let startSeconds = parseTimecode(event.startTime)
            let endSeconds = parseTimecode(event.endTime)
            let eventDuration = endSeconds - startSeconds
            
            // Use manual grouping to determine the group ID for this event
            let groupID: String
            if manualGrouping.hasManualAssociation(for: event.catalogID) {
                groupID = manualGrouping.getGroupID(for: event.catalogID)!
                print("      🔗 Using manual grouping: \(event.catalogID) → \(groupID)")
            } else {
                groupID = event.catalogID
            }
            
            if var existing = aggregated[groupID] {
                // Add this event's duration to the total
                let newTotalDuration = existing.totalDurationSeconds + eventDuration
                
                // Merge unique titles
                existing.event.uniqueTitles.formUnion(event.uniqueTitles)
                
                // Update total duration
                existing.totalDurationSeconds = newTotalDuration
                existing.event.duration = formatDuration(newTotalDuration)
                
                aggregated[groupID] = existing
                print("      ♻️ Added to \(groupID): +\(formatDuration(eventDuration)) → total \(existing.event.duration)")
            } else {
                // First occurrence
                var newEvent = event
                newEvent.catalogID = groupID  // Update the catalog ID to the group ID
                newEvent.duration = formatDuration(eventDuration)
                aggregated[groupID] = (newEvent, eventDuration)
                print("      ✨ New entry: \(groupID) - \(newEvent.duration)")
            }
        }
        
        let results = Array(aggregated.values.map { $0.event }).sorted { $0.catalogID < $1.catalogID }
        
        print("\n✅ FINAL: \(results.count) unique catalog IDs")
        for event in results {
            print("   - \(event.catalogID): \(event.duration) (\(event.uniqueTitles.count) unique titles)")
        }
        
        return results
    }
    
    // MARK: - Main Entry Point
    
    /// Process cue file through all 4 layers and return all results
    func parseWithAllLayers(from lines: [String], manualGrouping: ManualGrouping = ManualGrouping(), skipCatalogExtraction: Bool = false) -> CueParsingResult {
        print("\n" + String(repeating: "=", count: 60))
        print("🎬 STARTING CUE FILE PROCESSING")
        print(String(repeating: "=", count: 60))
        
        let layer1 = parseRawFile(lines: lines, skipCatalogExtraction: skipCatalogExtraction)
        let layer2 = aggregateFadesWithClips(events: layer1, manualGrouping: manualGrouping)
        let layer3 = mergeAcrossChannels(events: layer2)
        let layer4 = finalAggregation(events: layer3, manualGrouping: manualGrouping)
        
        print("\n" + String(repeating: "=", count: 60))
        print("✅ PROCESSING COMPLETE")
        print(String(repeating: "=", count: 60) + "\n")
        
        var result = CueParsingResult(layer1: layer1, layer2: layer2, layer3: layer3, layer4: layer4)
        result.manualGrouping = manualGrouping
        return result
    }
    
    /// Process cue file through all 4 layers (convenience method, returns final result)
    func aggregateEvents(from lines: [String], skipCatalogExtraction: Bool = false) -> [CueEvent] {
        return parseWithAllLayers(from: lines, skipCatalogExtraction: skipCatalogExtraction).layer4
    }
    
    /// Recalculate layers 2, 3, and 4 with manual grouping
    func recalculateWithManualGrouping(_ result: CueParsingResult) -> CueParsingResult {
        print("\n🔄 RECALCULATING WITH MANUAL GROUPING...")
        
        let layer2 = aggregateFadesWithClips(events: result.layer1, manualGrouping: result.manualGrouping)
        let layer3 = mergeAcrossChannels(events: layer2)
        let layer4 = finalAggregation(events: layer3, manualGrouping: result.manualGrouping)
        
        let updatedResult = CueParsingResult(
            layer1: result.layer1,
            layer2: layer2,
            layer3: layer3,
            layer4: layer4,
            manualGrouping: result.manualGrouping
        )
        
        print("✅ RECALCULATION COMPLETE")
        return updatedResult
    }
}
