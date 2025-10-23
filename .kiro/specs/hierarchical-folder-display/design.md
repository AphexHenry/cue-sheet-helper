# Design Document

## Overview

Fix the flat folder display by making minimal changes to the existing code. The current `FolderHierarchyBuilder.buildHierarchy` method creates a flat list of folders instead of a proper nested structure. We need to build the actual hierarchy and add visual indentation to show folder depth.

## Architecture

Keep all existing components unchanged, only modify:

1. **FolderHierarchyBuilder.buildHierarchy()** - Build proper nested structure instead of flat list
2. **FolderNodeView** - Add visual indentation based on folder.level
3. **FolderNodeView** - Recursively render child folders when expanded

## Components and Interfaces

### FolderHierarchyBuilder Changes

Replace the current flat folder creation with a proper hierarchy builder:

- Group tracks by folder path (keep existing logic)
- Build nested folder structure from paths
- Set correct level values for visual indentation
- Populate children arrays with subfolders

### FolderNodeView Changes

Add minimal visual changes:

- Apply left padding based on `folder.level * 20` pixels to the folder header
- Recursively render `folder.children` when the folder is expanded
- Keep all existing functionality (selection, drag, etc.)

## Data Models

No changes to FolderNode struct - it already has all needed properties:
- `level` - for indentation depth
- `children` - for nested folders  
- `tracks` - for tracks in this folder
- `allTracks` - computed property works correctly

## Error Handling

Keep existing error handling. No new error cases introduced.

## Testing Strategy

Manual testing:
1. Load music collection with nested folders
2. Verify folders show proper indentation
3. Test expand/collapse works with nested structure
4. Ensure all existing functionality still works