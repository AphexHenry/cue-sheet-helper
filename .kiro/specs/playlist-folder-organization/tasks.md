# Implementation Plan

- [x] 1. Create PlaylistFolder model and update Playlist model
  - Create new `PlaylistFolder.swift` file with complete model implementation
  - Add `folderId` property to existing `Playlist.swift` model
  - Include proper Codable, Identifiable, and Hashable conformance
  - _Requirements: 1.5, 2.2, 4.2_

- [x] 2. Extend database schema with folder support
  - Add database migration methods to PlaylistService for playlist_folders table
  - Add folder_id column to playlists table with proper foreign key constraints
  - Create database indexes for performance optimization
  - _Requirements: 1.3, 2.2, 4.2, 5.5_

- [x] 3. Implement core folder management in PlaylistService
  - Add folder-related properties (@Published folders array, folderExpandedStates)
  - Implement loadFolders() method with proper SQL queries
  - Implement createFolder() method with database insertion and local state updates
  - Implement deleteFolder() method with CASCADE behavior and orphan handling
  - _Requirements: 1.1, 1.2, 1.3, 5.2, 5.3, 5.4_

- [x] 4. Implement folder operations and playlist-folder relationships
  - Implement renameFolder() method with database updates and local state sync
  - Implement movePlaylistToFolder() method to update playlist folder assignments
  - Implement moveFolderToFolder() method with circular reference prevention
  - Add validation logic for maximum nesting depth and circular references
  - _Requirements: 2.1, 2.2, 4.1, 4.2, 4.5, 5.1, 5.5_

- [x] 5. Create folder management UI components
  - Create CreateFolderSheet component similar to CreatePlaylistSheet
  - Create RenameFolderSheet component for folder renaming operations
  - Add folder context menu with rename and delete options
  - Implement lproper error handling and user feedback for folder operations
  - _Requirements: 1.1, 1.2, 1.4, 5.1, 5.2, 5.3, 5.4_

- [x] 6. Update PlaylistSidebar with hierarchical display
  - Replace simple + button with dropdown menu offering Playlist/Folder creation options
  - Implement hierarchical rendering logic with proper indentation based on folder depth
  - Add expand/collapse chevrons for folders with children
  - Implement folder expansion state management and persistence
  - _Requirements: 1.1, 1.5, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 7. Implement drag-and-drop functionality for folders and playlists
  - Add drag-and-drop support for moving playlists into folders
  - Add drag-and-drop support for moving folders into other folders
  - Implement visual feedback during drag operations
  - Add proper drop validation to prevent invalid moves
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 4.1, 4.2_

- [x] 8. Integrate folder system with existing playlist operations
  - Update playlist loading to respect folder organization
  - Ensure playlist selection works correctly within folder hierarchy
  - Update playlist context menus to work within folder structure
  - Test all existing playlist functionality with folder organization
  - _Requirements: 4.3, 4.4_