# Implementation Plan

- [ ] 1. Create new data model structures
  - Define RawCueEvent, AggregatedEvent, ChannelMergedEvent, and FinalCueEvent structs
  - Implement CueEventType enum with fade event types
  - Add proper initializers and computed properties for time calculations
  - _Requirements: 1.1, 1.2, 1.4, 5.3_

- [ ] 2. Implement Layer 1 - Raw Parsing
- [ ] 2.1 Create RawParsingLayer class with core parsing logic
  - Implement parseLines method to convert raw strings to RawCueEvent objects
  - Add field validation and error handling for malformed lines
  - _Requirements: 1.1, 1.5, 5.1, 5.4_

- [ ] 2.2 Implement catalog/title extraction logic
  - Create extractCatalogAndTitle method with regex pattern matching
  - Handle various naming conventions and edge cases
  - _Requirements: 1.2, 1.4_

- [ ] 2.3 Add fade event detection and normalization
  - Implement determineEventType method to identify fade events
  - Create normalizeFadeEventName method for consistent naming
  - _Requirements: 1.3_

- [ ]* 2.4 Write unit tests for Layer 1 parsing
  - Test catalog extraction with various naming patterns
  - Test fade event detection and normalization
  - Test error handling with malformed input data
  - _Requirements: 1.1, 1.2, 1.3, 5.5_

- [ ] 3. Implement Layer 2 - Event Aggregation
- [ ] 3.1 Create EventAggregationLayer class
  - Implement aggregateEvents method for processing RawCueEvent arrays
  - Add sequential event processing logic
  - _Requirements: 2.5, 5.1_

- [ ] 3.2 Implement fade merging logic
  - Create mergeFadeIn method for fade in + clip combinations
  - Create mergeFadeOut method for clip + fade out combinations
  - Add proper time range calculations for merged events
  - _Requirements: 2.1, 2.2_

- [ ] 3.3 Implement cross-fade handling
  - Create handleCrossFade method with catalog prefix comparison
  - Handle same-prefix merging (count once) vs different-prefix (count twice)
  - Preserve original event data in merged results
  - _Requirements: 2.3, 2.4, 2.5_

- [ ]* 3.4 Write unit tests for Layer 2 aggregation
  - Test fade in/out merging scenarios
  - Test cross-fade handling for same and different catalog prefixes
  - Test preservation of original event data
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.5_

- [ ] 4. Implement Layer 3 - Channel Merging
- [ ] 4.1 Create ChannelMergingLayer class
  - Implement mergeChannels method for processing AggregatedEvent arrays
  - Add catalog prefix grouping logic
  - _Requirements: 3.3, 5.1_

- [ ] 4.2 Implement overlap detection and merging
  - Create findOverlappingEvents method with time range comparison
  - Implement calculateTimeOverlap for precise overlap detection
  - Create mergeOverlappingEvents method using min/max time ranges
  - _Requirements: 3.1, 3.4_

- [ ] 4.3 Add title preservation logic
  - Collect unique titles from all merged events
  - Maintain title list in ChannelMergedEvent structure
  - _Requirements: 3.2_

- [ ]* 4.4 Write unit tests for Layer 3 channel merging
  - Test overlap detection with various time ranges
  - Test merging of overlapping events with same catalog prefix
  - Test preservation of unique titles from multiple channels
  - _Requirements: 3.1, 3.2, 3.4, 5.5_

- [ ] 5. Implement Layer 4 - Duration Calculation
- [ ] 5.1 Create DurationCalculationLayer class
  - Implement calculateFinalDurations method for processing ChannelMergedEvent arrays
  - Add catalog prefix grouping and duration summation
  - _Requirements: 4.1, 5.1_

- [ ] 5.2 Implement duration summation and title collection
  - Create sumDurations method for calculating total time per catalog
  - Implement collectUniqueTitles method for gathering all title variations
  - Add proper time format conversion and validation
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 5.3 Add final data structure creation
  - Create FinalCueEvent objects with calculated totals
  - Preserve timing information and occurrence counts
  - _Requirements: 4.3, 4.4_

- [ ]* 5.4 Write unit tests for Layer 4 duration calculation
  - Test duration summation for events with same catalog ID
  - Test unique title collection and preservation
  - Test final data structure creation and validation
  - _Requirements: 4.1, 4.2, 4.4, 5.5_

- [ ] 6. Refactor main CueFileParsingService class
- [ ] 6.1 Update service class to use new pipeline architecture
  - Replace existing parsing logic with layer-based approach
  - Implement parseAndProcess method as main entry point
  - Add individual layer method calls for testing access
  - _Requirements: 5.1, 5.2_

- [ ] 6.2 Add error handling and logging
  - Implement comprehensive error handling across all layers
  - Add logging for debugging and monitoring
  - Ensure graceful degradation when processing fails
  - _Requirements: 5.4, 6.1, 6.2_

- [ ] 6.3 Optimize memory usage and performance
  - Review data structure usage for memory efficiency
  - Add performance monitoring for large file processing
  - Implement proper cleanup of intermediate data
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ]* 6.4 Write integration tests for complete pipeline
  - Test end-to-end processing with real cue file data
  - Test performance with large datasets
  - Test memory usage and cleanup
  - _Requirements: 5.5, 6.1, 6.2_

- [ ] 7. Update existing code integration points
- [ ] 7.1 Update calls to CueFileParsingService methods
  - Review existing usage of aggregateEvents method
  - Update method signatures to match new pipeline output
  - Ensure backward compatibility where possible
  - _Requirements: 5.2_

- [ ] 7.2 Verify integration with existing cue file processing
  - Test integration with current cue file workflow
  - Ensure output format matches expected data structures
  - Update any dependent code that relies on specific data formats
  - _Requirements: 5.2_

- [ ]* 7.3 Add regression tests for existing functionality
  - Create tests to ensure no breaking changes to existing features
  - Test with current cue file examples and expected outputs
  - Validate that refactoring maintains functional equivalence
  - _Requirements: 5.5_