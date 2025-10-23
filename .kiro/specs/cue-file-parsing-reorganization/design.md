# Design Document

## Overview

The CueFileParsingService will be restructured into a pipeline-based architecture with four distinct processing layers. Each layer will have a specific responsibility and will transform data from one representation to the next, creating a clean separation of concerns and improving maintainability.

## Architecture

### Pipeline Flow
```
Raw Cue File Lines
       ↓
Layer 1: Raw Parsing → [RawCueEvent]
       ↓
Layer 2: Event Aggregation → [AggregatedEvent] 
       ↓
Layer 3: Channel Merging → [ChannelMergedEvent]
       ↓
Layer 4: Duration Calculation → [FinalCueEvent]
```

### Core Principles
- **Single Responsibility**: Each layer handles one specific transformation
- **Immutable Data Flow**: Each layer produces new data structures rather than modifying input
- **Error Isolation**: Errors in one layer don't cascade to others
- **Testability**: Each layer can be tested independently

## Components and Interfaces

### Data Models

#### RawCueEvent
```swift
struct RawCueEvent {
    let channel: Int
    let eventID: Int
    let originalClipName: String
    let catalogPrefix: String
    let title: String
    let eventType: CueEventType
    let startTime: String
    let endTime: String
    let duration: String
    let state: String
}

enum CueEventType {
    case clip
    case fadeIn
    case fadeOut
    case crossFade
}
```

#### AggregatedEvent
```swift
struct AggregatedEvent {
    let channel: Int
    let catalogPrefix: String
    let mergedStartTime: String
    let mergedEndTime: String
    let originalEvents: [RawCueEvent]
    let state: String
}
```

#### ChannelMergedEvent
```swift
struct ChannelMergedEvent {
    let catalogPrefix: String
    let finalStartTime: String
    let finalEndTime: String
    let channels: [Int]
    let allTitles: Set<String>
    let originalEvents: [AggregatedEvent]
}
```

#### FinalCueEvent
```swift
struct FinalCueEvent {
    let catalogPrefix: String
    let totalDuration: String
    let uniqueTitles: [String]
    let totalOccurrences: Int
    let timeRanges: [(start: String, end: String)]
}
```

### Processing Layers

#### Layer 1: RawParsingLayer
**Responsibility**: Parse raw cue file lines into structured RawCueEvent objects

**Key Methods**:
- `parseLines(_ lines: [String]) -> [RawCueEvent]`
- `extractCatalogAndTitle(from clipName: String) -> (catalog: String, title: String)`
- `determineEventType(from clipName: String) -> CueEventType`
- `normalizeFadeEventName(_ clipName: String) -> String`

**Processing Logic**:
1. Split each line by tabs and validate field count
2. Extract and clean clip name
3. Separate catalog prefix from title using regex patterns
4. Determine if event is a fade type and normalize the name
5. Create RawCueEvent with all parsed data

#### Layer 2: EventAggregationLayer
**Responsibility**: Merge fade events with adjacent clips

**Key Methods**:
- `aggregateEvents(_ rawEvents: [RawCueEvent]) -> [AggregatedEvent]`
- `mergeFadeIn(_ fadeEvent: RawCueEvent, with nextEvent: RawCueEvent) -> AggregatedEvent`
- `mergeFadeOut(_ fadeEvent: RawCueEvent, with prevEvent: AggregatedEvent) -> AggregatedEvent`
- `handleCrossFade(_ crossFade: RawCueEvent, between prev: AggregatedEvent, and next: RawCueEvent) -> [AggregatedEvent]`

**Processing Logic**:
1. Iterate through raw events in sequence
2. When encountering fade events, look at adjacent events
3. For fade in: merge with next clip using fade start time
4. For fade out: merge with previous aggregated event using fade end time
5. For cross fade: check catalog prefixes and merge accordingly
6. Preserve all original event data in the aggregated result

#### Layer 3: ChannelMergingLayer
**Responsibility**: Merge overlapping events from different channels with same catalog prefix

**Key Methods**:
- `mergeChannels(_ aggregatedEvents: [AggregatedEvent]) -> [ChannelMergedEvent]`
- `findOverlappingEvents(_ events: [AggregatedEvent]) -> [[AggregatedEvent]]`
- `calculateTimeOverlap(event1: AggregatedEvent, event2: AggregatedEvent) -> Bool`
- `mergeOverlappingEvents(_ events: [AggregatedEvent]) -> ChannelMergedEvent`

**Processing Logic**:
1. Group events by catalog prefix
2. Within each group, find events that overlap in time
3. Merge overlapping events using min start time and max end time
4. Collect all unique titles from merged events
5. Preserve channel information and original events

#### Layer 4: DurationCalculationLayer
**Responsibility**: Calculate final durations and consolidate by catalog ID

**Key Methods**:
- `calculateFinalDurations(_ channelMergedEvents: [ChannelMergedEvent]) -> [FinalCueEvent]`
- `sumDurations(for catalogPrefix: String, events: [ChannelMergedEvent]) -> String`
- `collectUniqueTitles(from events: [ChannelMergedEvent]) -> [String]`
- `formatDuration(_ totalSeconds: Int) -> String`

**Processing Logic**:
1. Group channel-merged events by catalog prefix
2. Sum durations for each catalog prefix
3. Collect all unique titles for each catalog
4. Create final events with total duration and title information

### Main Service Class

#### CueFileParsingService
**Responsibility**: Orchestrate the parsing pipeline and provide public interface

**Key Methods**:
- `parseAndProcess(_ lines: [String]) -> [FinalCueEvent]`
- `parseRawEvents(_ lines: [String]) -> [RawCueEvent]` (Layer 1)
- `aggregateEvents(_ rawEvents: [RawCueEvent]) -> [AggregatedEvent]` (Layer 2)
- `mergeChannels(_ aggregatedEvents: [AggregatedEvent]) -> [ChannelMergedEvent]` (Layer 3)
- `calculateFinalDurations(_ channelMergedEvents: [ChannelMergedEvent]) -> [FinalCueEvent]` (Layer 4)

## Data Models

### Time Handling
- **Input Format**: HH:MM:SS:FF (hours:minutes:seconds:frames)
- **Internal Processing**: Convert to total seconds for calculations
- **Output Format**: MM:SS for durations, preserve original format for timestamps
- **Overlap Detection**: Use second-based comparison with tolerance for frame differences

### Name Processing
- **Catalog Extraction**: Use regex patterns to identify catalog/ID prefixes
- **Title Preservation**: Store original titles separately from catalog prefixes
- **Fade Normalization**: Convert variations of fade names to standard enum values
- **Duplicate Handling**: Use Set<String> for unique title collection

## Error Handling

### Layer-Specific Error Handling
- **Layer 1**: Skip malformed lines, log parsing errors, continue with valid data
- **Layer 2**: Handle missing adjacent events gracefully, preserve partial aggregations
- **Layer 3**: Skip events with invalid time formats, continue with valid overlaps
- **Layer 4**: Handle division by zero in duration calculations, provide default values

### Error Recovery Strategies
- **Graceful Degradation**: Continue processing even when some events fail
- **Logging**: Comprehensive logging at each layer for debugging
- **Validation**: Input validation at each layer boundary
- **Fallback Values**: Provide sensible defaults for missing or invalid data

## Testing Strategy

### Unit Testing Approach
- **Layer Isolation**: Test each layer independently with mock data
- **Data Transformation**: Verify correct transformation at each layer boundary
- **Edge Cases**: Test with malformed data, empty inputs, and boundary conditions
- **Performance**: Test with large datasets to ensure acceptable performance

### Test Data Structure
```swift
struct TestCase {
    let name: String
    let input: [String] // Raw cue file lines
    let expectedLayer1: [RawCueEvent]
    let expectedLayer2: [AggregatedEvent]
    let expectedLayer3: [ChannelMergedEvent]
    let expectedLayer4: [FinalCueEvent]
}
```

### Integration Testing
- **End-to-End**: Test complete pipeline with real cue file data
- **Regression**: Ensure refactoring doesn't break existing functionality
- **Performance**: Benchmark against current implementation
- **Memory**: Verify no memory leaks in processing pipeline

### Test Coverage Goals
- **Layer Methods**: 100% coverage of public methods in each layer
- **Error Paths**: Coverage of all error handling scenarios
- **Edge Cases**: Coverage of boundary conditions and malformed data
- **Integration**: Coverage of layer interactions and data flow