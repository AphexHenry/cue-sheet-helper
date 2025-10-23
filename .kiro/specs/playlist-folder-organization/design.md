# Design Document

## Overview

Add playlist folder organization to the existing WAUX playlist system. This feature will allow users to create folders, organize playlists hierarchically, and manage both playlists and folders through drag-and-drop operations. The design integrates seamlessly with the existing PlaylistService and database architecture.

## Architecture

The solution extends the current playlist system with minimal changes:

1. **New PlaylistFolder Model** - Represents folders that can contain playlists and other folders
2. **Extended Database Schema** - Add playlist_folders table and folder_id column to playlists table
3. **Enhanced PlaylistService** - Add folder management methods
4. **Updated PlaylistSidebar** - Support hierarchical display and folder operations
5. **New UI Components** - Folder creation sheets and hierarchical rendering

## Components and Interfaces

### Data Models

#### PlaylistFolder Model
```swift
struct PlaylistFolder: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var parentFolderId: String? // nil for root level folders
    let dateCreated: Date
    var dateModified: Date
    var isExpanded: Bool // UI state for expand/collapse
}
```

#### Updated Playlist Model
```swift
struct Playlist: Identifiable, Codable, Hashable {
    // ... existing properties
    var folderId: String? // nil for root level playlists
}
```

### Database Schema Changes

#### New playlist_folders Table
```sql
CREATE TABLE playlist_folders (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_folder_id TEXT,
    date_created TEXT NOT NULL,
    date_modified TEXT NOT NULL,
    FOREIGN KEY (parent_folder_id) REFERENCES playlist_folders(id) ON DELETE CASCADE
);
```

#### Updated playlists Table
```sql
ALTER TABLE playlists ADD COLUMN folder_id TEXT;
ALTER TABLE playlists ADD FOREIGN KEY (folder_id) REFERENCES playlist_folders(id) ON DELETE SET NULL;
```

### PlaylistService Extensions

#### New Methods
- `loadFolders() async throws`
- `createFolder(name: String, parentFolderId: String?) async throws -> PlaylistFolder`
- `deleteFolder(folderId: String) async throws`
- `renameFolder(folderId: String, newName: String) async throws`
- `movePlaylistToFolder(playlistId: String, folderId: String?) async throws`
- `moveFolderToFolder(folderId: String, parentFolderId: String?) async throws`

#### Updated Properties
```swift
@Published var folders: [PlaylistFolder] = []
@Published var folderExpandedStates: [String: Bool] = [:]
```

### UI Components

#### Updated PlaylistSidebar
- Replace simple + button with dropdown menu (Playlist/Folder)
- Add hierarchical rendering with proper indentation
- Support drag-and-drop for playlists and folders
- Add expand/collapse chevrons for folders

#### New Sheet Components
- `CreateFolderSheet` - Similar to CreatePlaylistSheet
- `RenameFolderSheet` - Similar to RenamePlaylistSheet

#### Hierarchical Rendering Logic
```swift
struct HierarchicalItem {
    enum ItemType {
        case folder(PlaylistFolder)
        case playlist(Playlist)
    }
    
    let type: ItemType
    let depth: Int
}
```

## Data Models

### Folder Hierarchy Structure
- Folders can contain playlists and other folders
- Maximum nesting depth of 10 levels to prevent performance issues
- Circular reference prevention in move operations
- Orphaned items (when parent folder is deleted) move to root level

### Database Relationships
- `playlist_folders.parent_folder_id` → `playlist_folders.id` (self-referencing)
- `playlists.folder_id` → `playlist_folders.id`
- CASCADE DELETE for folder hierarchy
- SET NULL for playlist folder references

## Error Handling

### New Error Cases
```swift
enum PlaylistError: Error {
    // ... existing cases
    case folderNotFound
    case circularReference
    case maxDepthExceeded
    case folderNotEmpty // when trying to delete non-empty folder
}
```

### Validation Rules
- Folder names cannot be empty or whitespace-only
- Prevent moving folder into its own descendants
- Limit folder nesting depth to 10 levels
- Validate folder existence before operations

## Testing Strategy

### Manual Testing Scenarios
1. **Folder Creation**: Create folders at root and nested levels
2. **Playlist Organization**: Drag playlists into folders and between folders
3. **Folder Nesting**: Create nested folder structures and test navigation
4. **Drag and Drop**: Test all drag combinations (playlist→folder, folder→folder)
5. **Context Menus**: Test rename, delete operations on folders
6. **Edge Cases**: Test circular reference prevention, max depth limits
7. **Database Integrity**: Verify proper CASCADE/SET NULL behavior

### Performance Considerations
- Lazy loading of folder contents for large hierarchies
- Efficient SQL queries with proper indexing
- Minimal UI updates during drag operations
- Debounced expand/collapse state persistence

## Migration Strategy

### Database Migration
1. Add new playlist_folders table
2. Add folder_id column to playlists table
3. Create indexes for performance
4. All existing playlists remain at root level (folder_id = NULL)

### Backward Compatibility
- Existing playlists continue to work without folders
- No breaking changes to existing PlaylistService API
- Graceful handling of missing folder references