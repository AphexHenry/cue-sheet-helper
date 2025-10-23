# Requirements Document

## Introduction

This feature modifies the tag column sorting behavior in the track table to sort by the number of tags each track has, rather than alphabetically by the tag content. This provides a more useful sorting mechanism for users who want to organize tracks by how extensively they are tagged.

## Requirements

### Requirement 1

**User Story:** As a user, I want to sort tracks by the number of tags they have, so that I can quickly identify tracks that are well-tagged or need more tagging.

#### Acceptance Criteria

1. WHEN I click on the Tags column header to sort THEN the tracks SHALL be sorted by the number of tags each track has
2. WHEN sorting by tag count in ascending order THEN tracks with fewer tags SHALL appear first
3. WHEN sorting by tag count in descending order THEN tracks with more tags SHALL appear first
4. WHEN tracks have the same number of tags THEN they SHALL be sorted alphabetically by track title as a secondary sort
5. WHEN a track has no tags THEN it SHALL be treated as having 0 tags for sorting purposes

### Requirement 2

**User Story:** As a user, I want the tag count sorting to work consistently with grouped tracks, so that the sorting behavior is predictable regardless of track grouping.

#### Acceptance Criteria

1. WHEN sorting grouped tracks by tag count THEN container tracks SHALL be sorted by their main track's tag count
2. WHEN a group is expanded THEN group members SHALL maintain their relative order within the group
3. WHEN sorting by tag count THEN group containers and individual tracks SHALL be sorted together in the same list
4. WHEN group members are visible THEN they SHALL not be independently sorted by tag count (group structure is preserved)

### Requirement 3

**User Story:** As a user, I want the tag count sorting to be efficient and responsive, so that I can sort large collections without performance issues.

#### Acceptance Criteria

1. WHEN sorting by tag count THEN the operation SHALL complete within 500ms for collections up to 10,000 tracks
2. WHEN the tag count sort is applied THEN it SHALL not cause UI freezing or blocking
3. WHEN tracks are modified (tags added/removed) THEN the sort order SHALL update automatically if tag count sorting is active
4. WHEN switching between different sort criteria THEN the transition SHALL be smooth and immediate