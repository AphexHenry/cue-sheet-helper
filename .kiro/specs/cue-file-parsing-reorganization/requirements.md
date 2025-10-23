# Requirements Document

## Introduction

The CueFileParsingService needs to be reorganized into a structured, multi-layered parsing system that processes cue file data through distinct phases: raw parsing, event aggregation, channel merging, and final duration calculation. This will improve maintainability, testability, and accuracy of the parsing logic while handling complex fade and cross-fade scenarios correctly.

## Requirements

### Requirement 1: Layer 1 - Raw File Parsing

**User Story:** As a developer, I want the system to parse cue file lines into structured CueEvent objects with proper name extraction, so that I have clean, structured data to work with in subsequent processing layers.

#### Acceptance Criteria

1. WHEN a cue file line is processed THEN the system SHALL extract channel, event ID, clip name, start time, end time, duration, and state fields
2. WHEN parsing clip names THEN the system SHALL separate catalog/ID prefix from the title portion
3. WHEN encountering fade events THEN the system SHALL normalize fade names to FADE_IN, FADE_OUT, and CROSS_FADE
4. WHEN parsing any clip name THEN the system SHALL store both the catalog/ID prefix and the full title
5. IF a line contains insufficient fields THEN the system SHALL skip that line and continue processing

### Requirement 2: Layer 2 - Event Aggregation

**User Story:** As a developer, I want fade events to be properly merged with adjacent clips, so that the timing and duration calculations accurately reflect the actual audio content.

#### Acceptance Criteria

1. WHEN a FADE_IN event is encountered THEN the system SHALL merge it with the next clip using the fade in start time and clip end time
2. WHEN a FADE_OUT event is encountered THEN the system SHALL merge it with the previous aggregated event using the event start time and fade out end time
3. WHEN a CROSS_FADE event occurs between clips with different catalog/ID prefixes THEN the system SHALL add the cross fade to both the previous and next events (counted twice)
4. WHEN a CROSS_FADE event occurs between clips with the same catalog/ID prefix THEN the system SHALL merge all events together with the cross fade counted once
5. WHEN merging events THEN the system SHALL preserve all original clip names in a list for reference

### Requirement 3: Layer 3 - Channel Merging

**User Story:** As a developer, I want events from different channels that overlap in time and share the same catalog/ID prefix to be merged, so that stereo or multi-channel content is properly consolidated.

#### Acceptance Criteria

1. WHEN events from different channels have the same catalog/ID prefix AND overlap in time THEN the system SHALL merge them using the minimum start time and maximum end time
2. WHEN merging channel events THEN the system SHALL preserve all unique full titles from both channels
3. WHEN events do not overlap in time THEN the system SHALL keep them as separate events even if they share the same catalog/ID prefix
4. WHEN merging channels THEN the system SHALL update the duration to reflect the merged time range

### Requirement 4: Layer 4 - Final Duration Calculation

**User Story:** As a developer, I want events with the same catalog ID to have their durations summed together with proper title tracking, so that I can see the total usage time for each piece of content.

#### Acceptance Criteria

1. WHEN multiple events share the same catalog ID THEN the system SHALL sum their individual durations
2. WHEN merging by catalog ID THEN the system SHALL maintain a list of all unique full titles that were merged
3. WHEN calculating final durations THEN the system SHALL preserve the original timing information for reference
4. WHEN events have different titles but same catalog ID THEN the system SHALL track all unique title variations

### Requirement 5: Data Structure and Organization

**User Story:** As a developer, I want clear data structures and separation of concerns between parsing layers, so that the code is maintainable and testable.

#### Acceptance Criteria

1. WHEN implementing the parsing layers THEN each layer SHALL have its own dedicated method or class
2. WHEN processing data THEN each layer SHALL take the output of the previous layer as input
3. WHEN storing parsed data THEN the system SHALL use appropriate data structures for each layer's needs
4. WHEN errors occur in any layer THEN the system SHALL handle them gracefully without affecting other layers
5. WHEN testing the system THEN each layer SHALL be independently testable

### Requirement 6: Performance and Memory Management

**User Story:** As a developer, I want the parsing system to handle large cue files efficiently, so that the application remains responsive during processing.

#### Acceptance Criteria

1. WHEN processing large files THEN the system SHALL use memory-efficient data structures
2. WHEN parsing multiple layers THEN the system SHALL avoid unnecessary data duplication
3. WHEN encountering malformed data THEN the system SHALL continue processing without memory leaks
4. WHEN processing is complete THEN the system SHALL release intermediate data structures appropriately