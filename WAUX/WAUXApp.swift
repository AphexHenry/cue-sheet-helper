//
//  WAUXApp.swift
//  Vaux Cue Sheet
//
//  Created by Baptiste Bohelay on 16/08/2025.
//

import SwiftUI

@main
struct WAUXApp: App {
    var body: some Scene {
        if #available(macOS 13.0, *) {
            return WindowGroup {
                CueFileHelperView()
            }
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 900, height: 600)
            .windowResizability(.automatic)
            .commands {
                CueProjectCommands()
            }
            Settings {
                WAUXSettingsView()
                    .frame(width: 520)
                    .padding()
            }
        } else {
            return WindowGroup {
                CueFileHelperView()
            }
            .windowStyle(.hiddenTitleBar)
            .commands {
                CueProjectCommands()
            }
            Settings {
                WAUXSettingsView()
                    .frame(width: 520)
                    .padding()
            }
        }
    }
}

struct CueProjectCommands: Commands {
    var body: some Commands {
        CommandMenu("Project") {
            Button("Save Cue Project...") {
                NotificationCenter.default.post(name: .saveCueProjectRequested, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Load Cue Project...") {
                NotificationCenter.default.post(name: .loadCueProjectRequested, object: nil)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }
    }
}

struct WAUXSettingsView: View {
    @AppStorage("replaceUnderscoresWithSpaces") private var replaceUnderscoresWithSpaces = true
    @AppStorage("skipCatalogExtraction") private var skipCatalogExtraction = false

    var body: some View {
        Form {
            Section("Import Options") {
                Toggle("Replace underscores with spaces", isOn: $replaceUnderscoresWithSpaces)
                Text("Converts underscores (_) to spaces for CSV export values.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Skip catalog ID extraction", isOn: $skipCatalogExtraction)
                Text("Uses full cleaned clip names as catalog IDs during parsing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
