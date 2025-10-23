# Implementation Plan

- [x] 1. Update TrackListView Tags column to sort by tag count
  - Modify existing TableColumn("Tags") to use tag count for sorting value
  - Change `value: \.track.generalTagsText` to `value: \.track.generalTags.count`
  - Preserve existing tag display UI unchanged
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.3, 1.5, 3.3_