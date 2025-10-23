# Implementation Plan

- [x] 1. Update FolderHierarchyBuilder to create proper nested structure
  - Replace the flat folder creation logic in `buildHierarchy` method
  - Build actual parent-child relationships from file paths
  - Set correct level values for each folder based on depth
  - _Requirements: 1.1, 1.2, 3.1, 3.2, 3.3, 3.5_

- [x] 2. Add visual indentation to FolderHeaderView
  - Apply left padding based on `folder.level * 20` pixels
  - Ensure chevron button and folder content are properly indented
  - _Requirements: 1.3, 1.4_

- [x] 3. Add recursive child folder rendering to FolderNodeView
  - Render `folder.children` when folder is expanded
  - Ensure child folders appear below parent folder with proper indentation
  - Maintain all existing functionality (selection, drag, search)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_