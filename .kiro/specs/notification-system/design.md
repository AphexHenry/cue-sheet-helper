# Design Document

## Overview

This design implements visual feedback for drag and drop operations when adding tracks to playlists. The solution consists of two main components:
1. A bounce animation system for playlist items during drag and drop operations
2. A minimal snackbar notification system that only shows when duplicate tracks are detected

The design integrates with the existing PlaylistService and SwiftUI views while maintaining the current architecture patterns.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PlaylistSidebar                          │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  PlaylistRow    │  │  SnackbarView   │                  │
│  │  + Animation    │  │  (Overlay)      │                  │
│  │  + Drop Target  │  │                 │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 PlaylistService                             │
│  + addTracksToPlaylist(playlistId, trackPaths)             │
│  + returns (newTracksCount, duplicateTracksCount)          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 NotificationService                         │
│  + showDuplicateTracksNotification(count, playlistName)    │
│  + manages snackbar display and auto-dismiss               │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Enhanced PlaylistService

**Purpose**: Extend the existing `addTrackToPlaylist` method to handle multiple tracks and return duplicate information.

**Interface**:
```swift
// New method for batch adding tracks
func addTracksToPlaylist(playlistId: String, trackPaths: [String]) async throws -> (newTracks: Int, duplicateTracks: Int)

// Enhanced existing method to return duplicate status
func addTrackToPlaylist(playlistId: String, absoluteTrackPath: String) async throws -> Bool // returns true if track was new
```

**Key Changes**:
- Modify the existing `addTrackToPlaylist` to detect and return duplicate status
- Add new batch method `addTracksToPlaylist` for handling multiple tracks efficiently
- Return tuple with counts of new vs duplicate tracks

### 2. NotificationService

**Purpose**: Manage snackbar notifications with automatic dismissal.

**Interface**:
```swift
class NotificationService: ObservableObject {
    @Published var currentNotification: NotificationItem?
    
    func showDuplicateTracksNotification(count: Int, playlistName: String)
    func dismissNotification()
}

struct NotificationItem {
    let message: String
    let type: NotificationType
    let timestamp: Date
}

enum NotificationType {
    case info
    case warning
    case error
}
```

### 3. SnackbarView

**Purpose**: Display temporary notifications at the bottom of the screen.

**Interface**:
```swift
struct SnackbarView: View {
    let notification: NotificationItem
    let onDismiss: () -> Void
    
    var body: some View // Animated snackbar with auto-dismiss
}
```

### 4. Enhanced PlaylistRow with Animation

**Purpose**: Add bounce animation and drop target functionality to playlist rows.

**Interface**:
```swift
struct PlaylistRowView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    
    func triggerBounceAnimation()
    func handleTrackDrop(trackPaths: [String])
}
```

## Data Models

### NotificationItem
```swift
struct NotificationItem: Identifiable {
    let id = UUID()
    let message: String
    let type: NotificationType
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 4.0 // 4 second auto-dismiss
    }
}
```

### Animation State
```swift
struct AnimationState {
    var scale: CGFloat = 1.0
    var isAnimating: Bool = false
    
    mutating func triggerBounce() {
        isAnimating = true
        scale = 1.15 // 15% scale up
    }
    
    mutating func reset() {
        isAnimating = false
        scale = 1.0
    }
}
```

## Error Handling

### Drag and Drop Errors
- **Invalid track paths**: Log warning, continue with valid tracks
- **Playlist not found**: Show error notification
- **Database errors**: Show error notification, don't trigger animation

### Animation Errors
- **Animation interruption**: Reset to normal state
- **Multiple simultaneous animations**: Queue or ignore subsequent triggers

### Notification Errors
- **Multiple notifications**: Replace current with new one
- **Notification service unavailable**: Fail silently (animation still works)

## Testing Strategy

### Unit Tests
1. **PlaylistService.addTracksToPlaylist**
   - Test with all new tracks (returns (n, 0))
   - Test with all duplicate tracks (returns (0, n))
   - Test with mixed tracks (returns (x, y))
   - Test with empty track list
   - Test with invalid playlist ID

2. **NotificationService**
   - Test notification creation and auto-dismiss
   - Test notification replacement
   - Test manual dismissal

### Integration Tests
1. **Drag and Drop Flow**
   - Test complete flow from drop to animation to notification
   - Test animation timing and completion
   - Test notification display and dismissal

### UI Tests
1. **Animation Behavior**
   - Verify bounce animation plays correctly
   - Verify animation doesn't interfere with other UI elements
   - Test animation on different playlist row sizes

2. **Snackbar Display**
   - Verify snackbar appears at correct position
   - Verify auto-dismiss timing
   - Verify click-to-dismiss functionality

## Implementation Notes

### SwiftUI Animation Approach
- Use `withAnimation(.spring())` for natural bounce effect
- Apply `scaleEffect()` modifier to playlist row
- Duration: 0.4 seconds total (0.2s up, 0.2s down)

### Drag and Drop Integration
- Extend existing PlaylistSidebar to handle file drops
- Use SwiftUI's `.onDrop()` modifier
- Support UTType.fileURL for audio files

### Performance Considerations
- Batch database operations for multiple tracks
- Debounce rapid successive drops
- Limit animation to one per playlist at a time

### Accessibility
- Ensure animations respect reduced motion preferences
- Provide VoiceOver announcements for successful operations
- Make snackbar content accessible to screen readers