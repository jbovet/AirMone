//
//  WiFiAnalyzerApp.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Application entry point. Configures the main window with a hidden title bar.
@main
struct WiFiAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button("AirMone Help") {
                    if let url = URL(string: "https://github.com/jbovet/AirMone/") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
