# Implementation Plan

- [x] 1. Create app snackbar component
  - Create simple SnackbarView SwiftUI component that displays at bottom of screen
  - Add basic slide-in animation and auto-dismiss after 3-4 seconds
  - Add @Published snackbar message to PlaylistService to trigger display
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 2. Use snackbar when tracks are not all new
  - Modify existing handleDrop method in PlaylistSidebar to count duplicates
  - Show snackbar with "N tracks were already in [playlist name]" only when duplicates exist
  - No notification when all tracks are new to playlist
  - _Requirements: 2.1, 2.2_

- [x] 3. Add bounce animation to playlist on drop
  - Add @State scale property to playlist rows in PlaylistSidebar
  - Trigger bounce animation (scale 1.0 → 1.15 → 1.0) when tracks are dropped
  - Use withAnimation(.spring()) for natural bounce effect over 0.4 seconds
  - _Requirements: 1.1, 1.2, 1.3_