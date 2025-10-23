# Requirements Document

## Introduction

This feature implements visual feedback for drag and drop operations when adding tracks to playlists. It provides a bounce animation for the playlist and shows a snackbar notification only when some tracks were already present in the playlist.

## Requirements

### Requirement 1

**User Story:** As a user, I want visual feedback when I drag and drop tracks onto a playlist, so that I know the operation is being processed.

#### Acceptance Criteria

1. WHEN a user drags and drops tracks onto a playlist THEN the playlist SHALL animate with a bounce/scale effect
2. WHEN the bounce animation plays THEN it SHALL scale the playlist up by 10-15% and then back to normal size over 0.3-0.5 seconds
3. WHEN the animation completes THEN the playlist SHALL return to its normal visual state

### Requirement 2

**User Story:** As a user, I want to know when some tracks I'm adding to a playlist were already present, so that I understand what happened during the operation.

#### Acceptance Criteria

1. WHEN adding tracks to a playlist and some tracks were already in the playlist THEN the system SHALL display a snackbar notification showing "N tracks were already in [playlist name]"
2. WHEN adding tracks to a playlist and all tracks are new THEN the system SHALL NOT display any notification
3. WHEN a snackbar notification is displayed THEN it SHALL automatically disappear after 3-4 seconds
4. WHEN a user clicks on the snackbar THEN it SHALL dismiss immediately