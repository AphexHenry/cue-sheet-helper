# Vaux Cue Sheet - Cue File Parser and Metadata Extractor

A native macOS application for parsing DAW cue files and extracting composer metadata from audio files, built with SwiftUI.

## Features

### Collection Service
- **Database Reading**: Can read SQLite databases created by the Flutter audio_looker app
- **Track Management**: Displays tracks with metadata including title, artist, album, duration, rating, and source type
- **Search Functionality**: Search tracks by title, artist, album, or comment
- **Sorting**: Sort tracks by various criteria with configurable sort order
- **Path Resolution**: Handles both local and shared collection types with proper path resolution

### Audio Player
- Basic audio playback functionality
- Play, pause, stop controls
- Volume control
- Progress tracking

### UI Features
- Modern SwiftUI interface
- Table view for track listing with sortable columns
- Search bar for filtering tracks
- Rating display with star icons
- Source type indicators (local, YouTube, URL)

## Architecture

### Models
- `Track`: Represents an audio track with all metadata fields
- `TimeMarker`: Represents time-based markers for tracks
- `CollectionDefinition`: Defines collection types (local/shared)
- `AudioTrack`: Legacy model for basic audio functionality

### Services
- `CollectionService`: Manages database operations and track loading
- `AudioService`: Handles audio playback functionality

### Views
- `TrackListView`: Displays tracks in a sortable table format
- `AudioPlayerView`: Audio player controls
- `ContentView`: Main application interface

## Database Schema

The app reads SQLite databases with the following structure:
- `music` table: Contains track information
- `playlists` table: Playlist definitions
- `playlist_tracks` table: Playlist-track relationships
- `local_root_folders` table: Root folder paths for local collections
- `ui_settings` table: UI configuration settings

## Usage

1. Launch the application
2. Click "Open Database" to select a SQLite database file
3. The app will load and display all tracks in the database
4. Use the search bar to filter tracks
5. Click column headers to sort by different criteria
6. Use the audio player controls to play tracks

## Development

### Requirements
- macOS 14.6+
- Xcode 15.0+
- Swift 5.9+

### Building
```bash
cd "native osx"
xcodebuild -project WAUX.xcodeproj -scheme WAUX -configuration Debug build
```

### Project Structure
```
WAUX/
├── Models/
│   ├── Track.swift          # Track model with full metadata
│   ├── AudioTrack.swift     # Legacy audio track model
│   └── Playlist.swift       # Playlist model
├── Services/
│   ├── CollectionService.swift  # Database and collection management
│   └── AudioService.swift       # Audio playback
├── Views/
│   ├── TrackListView.swift      # Track table view
│   └── AudioPlayerView.swift    # Audio player controls
├── ContentView.swift            # Main application view
└── WAUXApp.swift               # App entry point
```

## Migration from Flutter

This native macOS app is designed to read databases created by the Flutter audio_looker application. The collection service implements the same database schema and data structures to ensure compatibility.

### Key Differences from Flutter Version
- Uses native SQLite3 instead of sqflite
- SwiftUI instead of Flutter widgets
- Native macOS UI patterns and conventions
- Simplified architecture focused on reading existing databases

## Future Enhancements

- Write operations (add, edit, delete tracks)
- Playlist management
- Audio file import
- Waveform visualization
- Advanced filtering and tagging
- Sync with cloud storage
