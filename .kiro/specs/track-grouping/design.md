# Design Document

## Overview

The track grouping feature allows users to organize multiple track variations (remixes, live versions, different formats) into collapsible containers within the track table. The design leverages existing Track structures and adds minimal new data models to maintain system simplicity and performance.

## Architecture

### Core Principles

1. **Non-invasive Design**: Existing Track model remains unchanged
2. **Lightweight Data Structure**: Minimal additional database tables
3. **Virtual Containers**: Groups are represented as virtual Track objects for UI consistency
4. **Efficient Querying**: Simple relationships without complex joins
5. **Backward Compatibility**: Ungrouped tracks continue to work exactly as before

### High-Level Flow

```
User selects tracks → Creates group → System stores relationships → 
UI displays container → User interacts with container → 
System delegates to main track
```

## Components and Interfaces

### 1. Data Models

#### TrackGroup
```swift
struct TrackGroup: Identifiable, Codable {
    let id: String // UUID
    let name: String // User-defined or auto-generated
    let mainTrackId: Int // References Track.id
    let trackIds: [Int] // All tracks in group including main
    let dateCreated: Date
    let isExpanded: Bool // UI state
}
```

#### TrackGroupService
```swift
class TrackGroupService: ObservableObject {
    @Published var groups: [TrackGroup] = []
    
    func createGroup(trackIds: [Int], name: String?) async throws -> TrackGroup
    func deleteGroup(groupId: String) async throws
    func addTracksToGroup(groupId: String, trackIds: [Int]) async throws
    func removeTrackFromGroup(groupId: String, trackId: Int) async throws
    func setMainTrack(groupId: String, trackId: Int) async throws
    func toggleGroupExpansion(groupId: String)
    func getGroupForTrack(trackId: Int) -> TrackGroup?
}
```

#### GroupedTrack (Virtual Container)
```swift
struct GroupedTrack {
    let group: TrackGroup
    let mainTrack: Track
    let allTracks: [Track]
    
    // Implements Track-like interface for UI compatibility
    var id: Int? { mainTrack.id }
    var title: String { group.name.isEmpty ? mainTrack.title : group.name }
    var artist: String { mainTrack.artist }
    // ... delegates all properties to mainTrack
    
    var isGroup: Bool { true }
    var trackCount: Int { allTracks.count }
}
```

### 2. Database Schema

#### track_groups Table
```sql
CREATE TABLE track_groups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    main_track_id INTEGER NOT NULL,
    date_created TEXT NOT NULL,
    is_expanded INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (main_track_id) REFERENCES music (id) ON DELETE CASCADE
);
```

#### track_group_members Table
```sql
CREATE TABLE track_group_members (
    group_id TEXT NOT NULL,
    track_id INTEGER NOT NULL,
    PRIMARY KEY (group_id, track_id),
    FOREIGN KEY (group_id) REFERENCES track_groups (id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES music (id) ON DELETE CASCADE
);
```

### 3. UI Components

#### Enhanced TrackTable
- Detects grouped tracks and renders containers
- Shows chevron indicators for expandable groups
- Handles expand/collapse state
- Renders grouped tracks with visual distinction

#### GroupContextMenu
- "Group Tracks" option for multiple selection
- "Ungroup Tracks" for container tracks
- "Set as Main Track" for tracks within expanded groups
- "Add to Group" for adding tracks to existing groups

#### TrackRowView Variants
- **ContainerRowView**: Shows group info with chevron
- **GroupedTrackRowView**: Shows individual tracks within expanded group
- **RegularTrackRowView**: Standard track display (unchanged)

### 4. Service Integration

#### CollectionService Extensions
```swift
extension CollectionService {
    func createTrackGroupsTable() throws
    func loadTrackGroups() async throws -> [TrackGroup]
    func saveTrackGroup(_ group: TrackGroup) async throws
    func deleteTrackGroup(id: String) async throws
    func updateTrackGroupMainTrack(groupId: String, mainTrackId: Int) async throws
}
```

## Data Models

### TrackGroup Structure
```swift
struct TrackGroup: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var mainTrackId: Int
    var trackIds: Set<Int>
    let dateCreated: Date
    var isExpanded: Bool
    
    init(trackIds: Set<Int>, mainTrackId: Int, name: String = "") {
        self.id = UUID().uuidString
        self.trackIds = trackIds
        self.mainTrackId = mainTrackId
        self.name = name
        self.dateCreated = Date()
        self.isExpanded = false
    }
}
```

### Display Models
```swift
enum TrackDisplayItem: Identifiable {
    case individual(Track)
    case container(GroupedTrack)
    case groupMember(Track, groupId: String)
    
    var id: String {
        switch self {
        case .individual(let track):
            return "track_\(track.id ?? -1)"
        case .container(let groupedTrack):
            return "group_\(groupedTrack.group.id)"
        case .groupMember(let track, let groupId):
            return "member_\(groupId)_\(track.id ?? -1)"
        }
    }
}
```

## Error Handling

### Group Creation Validation
- Minimum 2 tracks required for grouping
- All tracks must exist in database
- Cannot group tracks that are already in other groups
- Main track must be one of the selected tracks

### Deletion Scenarios
- When main track is deleted: Auto-select new main track
- When group has only 1 track remaining: Auto-dissolve group
- When all tracks in group are deleted: Remove group record

### Conflict Resolution
- Duplicate group names: Append number suffix
- Missing main track: Select first available track in group
- Corrupted group data: Skip group and log warning

## Testing Strategy

### Unit Tests
1. **TrackGroupService Tests**
   - Group creation with valid/invalid inputs
   - Main track selection and updates
   - Track addition/removal from groups
   - Group deletion and cleanup

2. **Data Model Tests**
   - TrackGroup serialization/deserialization
   - GroupedTrack property delegation
   - TrackDisplayItem identification

3. **Database Tests**
   - Schema creation and migration
   - Foreign key constraint enforcement
   - Cascade deletion behavior
   - Data integrity after operations

### Integration Tests
1. **UI Interaction Tests**
   - Context menu group creation
   - Expand/collapse functionality
   - Drag and drop with grouped tracks
   - Keyboard navigation with groups

2. **Service Integration Tests**
   - CollectionService + TrackGroupService coordination
   - Database transaction consistency
   - Error propagation and handling

3. **Performance Tests**
   - Large group handling (100+ tracks per group)
   - Multiple groups display performance
   - Database query efficiency with groups

### User Acceptance Tests
1. **Workflow Tests**
   - Complete group creation workflow
   - Group management operations
   - Playback behavior with grouped tracks
   - Playlist operations with containers

2. **Edge Case Tests**
   - Empty groups handling
   - Circular group references prevention
   - Concurrent group modifications
   - Database corruption recovery

## Implementation Phases

### Phase 1: Core Data Layer
- Database schema creation
- TrackGroup model implementation
- Basic TrackGroupService operations
- Database migration for existing collections

### Phase 2: Service Integration
- CollectionService extensions
- Group loading and persistence
- Error handling and validation
- Data consistency enforcement

### Phase 3: UI Foundation
- TrackDisplayItem enum and logic
- Enhanced TrackTable with group detection
- Basic container rendering
- Expand/collapse functionality

### Phase 4: User Interactions
- Context menu enhancements
- Group creation workflow
- Main track management
- Group dissolution handling

### Phase 5: Advanced Features
- Drag and drop with groups
- Keyboard shortcuts for groups
- Group naming and customization
- Performance optimizations

## Performance Considerations

### Database Optimization
- Indexed foreign keys for fast lookups
- Minimal additional queries for group data
- Efficient cascade deletion handling
- Batch operations for multiple group changes

### UI Performance
- Lazy loading of group member details
- Virtual scrolling compatibility
- Minimal re-renders on group state changes
- Efficient diff calculations for table updates

### Memory Management
- Weak references in group relationships
- Proper cleanup of expanded group state
- Efficient caching of grouped track data
- Minimal duplication of track objects