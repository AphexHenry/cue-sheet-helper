# Requirements Document

## Introduction

The folder hierarchy view currently displays all folders in a flat structure without showing their actual nesting relationships. Users need to see the proper folder hierarchy with visual indentation to understand the folder structure of their music collection, similar to how file explorers display nested folders.

## Requirements

### Requirement 1

**User Story:** As a user, I want to see folders displayed with proper nesting hierarchy, so that I can understand the actual folder structure of my music collection.

#### Acceptance Criteria

1. WHEN the folder hierarchy view loads THEN the system SHALL display folders in their actual nested structure
2. WHEN a folder contains subfolders THEN the system SHALL show those subfolders as children of the parent folder
3. WHEN displaying nested folders THEN the system SHALL use visual indentation to show the depth level
4. WHEN a folder is at depth level N THEN the system SHALL indent it by N * 20 pixels from the left margin

### Requirement 2

**User Story:** As a user, I want to expand and collapse nested folders, so that I can navigate through the folder structure efficiently.

#### Acceptance Criteria

1. WHEN a folder has children THEN the system SHALL display an expand/collapse chevron button
2. WHEN I click the expand button THEN the system SHALL show all direct children of that folder
3. WHEN I click the collapse button THEN the system SHALL hide all children of that folder
4. WHEN a folder is collapsed THEN the system SHALL maintain the collapsed state until explicitly expanded
5. WHEN expanding a folder THEN the system SHALL preserve the expansion state of any previously expanded subfolders

### Requirement 3

**User Story:** As a user, I want the folder hierarchy to build correctly from file paths, so that the structure matches my actual file system organization.

#### Acceptance Criteria

1. WHEN tracks are loaded THEN the system SHALL analyze file paths to determine folder relationships
2. WHEN building the hierarchy THEN the system SHALL create parent-child relationships based on path components
3. WHEN a folder path is "/Music/Rock/Classic Rock" THEN the system SHALL create nested folders: Music > Rock > Classic Rock
4. WHEN multiple tracks share a common parent path THEN the system SHALL group them under the same parent folder
5. WHEN calculating folder depth THEN the system SHALL set the level property correctly for each folder node

### Requirement 4

**User Story:** As a user, I want folder selection and interaction to work properly with the hierarchical display, so that I can perform actions on nested folders.

#### Acceptance Criteria

1. WHEN I select a parent folder THEN the system SHALL include all tracks from child folders in the selection
2. WHEN dragging a folder THEN the system SHALL include all tracks from nested subfolders
3. WHEN displaying folder track counts THEN the system SHALL show the total count including tracks from subfolders
4. WHEN searching for tracks THEN the system SHALL maintain the hierarchical structure while filtering results