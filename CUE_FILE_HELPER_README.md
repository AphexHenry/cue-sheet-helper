# Vaux Cue Sheet - Cue File Parser and Metadata Extractor

## Overview
Vaux Cue Sheet is a native macOS application that replicates the functionality of your JUCE File Parser for Maja application. This tool helps parse DAW cue files and fetch composer metadata from audio files.

## What Was Added

### 1. Menu Item
- **Location**: File → Open Cue File Helper
- **Keyboard Shortcut**: Cmd+Shift+H

### 2. New Files Created

#### Services
- **`CueFileParsingService.swift`**: Parses tab-delimited cue files, aggregates events, and processes clip names
  - Implements `getSimplifiedName()` - processes "_UPRIGHT_" prefixed names and removes .L/.R suffixes
  - Implements `aggregateEvents()` - parses events, combines duplicates, sums durations
  
- **`ComposerFetchingService.swift`**: Searches audio files and extracts composer metadata
  - Uses AVFoundation to extract ID3 metadata (TCOM field)
  - Searches recursively through directories for matching audio files
  - Supports: MP3, WAV, AIFF, M4A, FLAC
  - Remembers last search directory in UserDefaults

#### Views
- **`CueFileHelperView.swift`**: Main interface for the Cue File Helper
  - Drag & drop interface for .txt files
  - Table view displaying: Channel, Event, Clip Name, Start Time, End Time, Duration, State, Composer
  - Progress indicator for composer fetching
  - Export to CSV functionality
  - Clear button to reset

### 3. App Structure
- **`WAUXApp.swift`**: Main app entry point
  - Simplified to show only the Cue File Helper interface
  - Clean, focused application structure

## How to Use

1. **Launch Vaux Cue Sheet**
   - Open the application
   - The main interface will appear

2. **Load a Cue File**
   - Drag and drop a .txt file exported from your DAW
   - The file will be parsed and events will appear in the table

3. **Fetch Composer Metadata**
   - Click "Select Audio Directory" to choose the folder containing your audio files
   - Click "Fetch Composers" to automatically search for and extract composer info
   - Progress will be displayed as it processes each clip

4. **Export Results**
   - Click "Export to CSV" to save the results
   - The CSV will be created next to the original .txt file
   - Format: Clip Name, Duration, Composer

5. **Clear and Start Over**
   - Click "Clear" to reset and load a new file

## Features Replicated from JUCE App

✅ Drag and drop .txt file parsing
✅ Tab-delimited event parsing
✅ Simplified name processing (removes _UPRIGHT_, handles .L/.R)
✅ Event aggregation (combines duplicates, sums durations)
✅ Composer metadata extraction from audio files
✅ Recursive directory searching
✅ CSV export with proper escaping
✅ Progress indicator during composer fetching
✅ Duration formatting (MM:SS)
✅ State filtering (ignores "Muted" events)

## Technical Details

### File Format
The parser expects tab-delimited text files with the following columns:
1. Channel
2. Event ID
3. Clip Name
4. Start Time
5. End Time
6. Duration (HH:MM:SS:FF format)
7. State (optional)

Lines must start with "1" to be processed.

### Name Processing
- Removes everything after last ")"
- Handles "_UPRIGHT_" prefix transformations
- Removes .L/.R stereo channel suffixes
- Replaces underscores with spaces for searching

### Composer Fetching
- Searches recursively through selected directory
- Matches clip names to audio file names (case insensitive)
- Tries exact match first, then with underscores replaced by spaces
- Extracts composer from AVFoundation metadata (commonKeyCreator, TCOM)

### CSV Export
- Properly escapes values containing commas, quotes, or newlines
- Creates file next to original .txt file
- Reveals in Finder after export

## Building the Project

Since this project uses Xcode's file system synchronization (objectVersion 77), all new files are automatically included. Simply:

1. Open the project in Xcode
2. Build and run (Cmd+R)
3. The new files will be automatically compiled

## Testing

1. Export a cue list from your DAW as a .txt file
2. Open Vaux Cue Sheet
3. Drag the .txt file into the window
4. Select your audio files directory
5. Click "Fetch Composers"
6. Export to CSV

## Notes

- The window can be opened multiple times for comparing different cue files
- Each window instance is independent
- The last selected audio directory is saved and will be remembered
- All audio file searching is done on a background thread to keep the UI responsive
