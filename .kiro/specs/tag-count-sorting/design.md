# Design Document

## Overview

This feature modifies the existing tag column sorting in TrackListView to sort by tag count instead of alphabetical tag content. The implementation leverages the existing SwiftUI Table sorting infrastructure with a new computed property for tag count.

## Architecture

### Core Changes

1. **Track Model Extension**: Add a computed property for tag count sorting
2. **TrackDisplayItem Extension**: Add tag count sorting support for grouped tracks  
3. **TrackListView Update**: Modify the Tags column to use tag count for sorting

## Components and Interfaces

### 1. Track Model Enhancement

Add a new computed property to the Track model:

```swift
extension Track {
    var generalTagsCount: Int { 
        return generalTags.count 
    }
}
```

### 2. TrackDisplayItem Enhancement

Extend TrackDisplayItem to support tag count sorting:

```swift
extension TrackDisplayItem {
    var tagCount: Int {
        return track.generalTagsCount
    }
}
```

### 3. TrackListView Column Update

Modify the Tags column in TrackTable to use tag count for sorting:

```swift
TableColumn("Tags", value: \.tagCount) { displayItem in
    // existing tag display logic
}
```

## Data Models

No new data models required. The implementation uses existing Track and TrackDisplayItem structures with new computed properties.

## Error Handling

- **Nil Safety**: Tag count computation handles empty or nil tag arrays gracefully
- **Performance**: Tag count calculation is O(1) operation on existing array property

## Testing Strategy

### Unit Tests
- Test tag count computation for tracks with various tag configurations
- Test sorting behavior with mixed tag counts
- Test grouped track tag count delegation to main track

### Integration Tests  
- Test tag count sorting with large track collections
- Test sorting performance benchmarks
- Test interaction with existing search and filter functionality

### UI Tests
- Test column header click behavior for tag count sorting
- Test sort direction indicators
- Test sorting with grouped tracks expanded/collapsed