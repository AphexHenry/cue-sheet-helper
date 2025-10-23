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
        } else {
            return WindowGroup {
                CueFileHelperView()
            }
            .windowStyle(.hiddenTitleBar)
        }
    }
}
