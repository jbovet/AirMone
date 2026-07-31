//
//  WiFiAnalyzerApp.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Application entry point. Configures the main window with a hidden title bar
/// and a menu bar item showing the live WiFi signal.
@main
struct WiFiAnalyzerApp: App {
    /// Dedicated scanner for the menu bar item. Owned by the app so it keeps
    /// updating regardless of which window/tab is visible. Polls at a slower
    /// cadence than the dashboard to keep the redundant work minimal.
    @StateObject private var menuBarViewModel = WiFiScannerViewModel(scanInterval: 5.0)

    var body: some Scene {
        // A single-instance `Window` (not `WindowGroup`) so "Open WiFi Analyzer"
        // from the menu bar fronts the existing window instead of spawning a
        // duplicate.
        Window("WiFi Analyzer", id: MenuBarContentView.mainWindowID) {
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

        MenuBarExtra {
            MenuBarContentView(viewModel: menuBarViewModel)
        } label: {
            // Custom signal-bars glyph (distinct from the system Wi‑Fi icon).
            Image(nsImage: MenuBarSignalIcon.menuBarTemplateImage(activeBars: menuBarActiveBars))
                // The label renders in the menu bar at launch, so this starts the
                // live scan up front — the icon reflects signal before the dropdown
                // is ever opened. startLiveScanning() guards against double-start.
                .task { menuBarViewModel.startLiveScanning() }
        }
        .menuBarExtraStyle(.window)
    }

    /// Number of filled bars (0...4) for the menu bar icon. 0 when disconnected;
    /// otherwise at least 1, scaled by signal quality.
    private var menuBarActiveBars: Int {
        guard let rssi = menuBarViewModel.currentNetwork?.rssi else { return 0 }
        let percent = min(max(2 * (rssi + 100), 0), 100)
        let bars = Int((Double(percent) / 100.0 * Double(MenuBarSignalIcon.barCount)).rounded())
        return min(max(bars, 1), MenuBarSignalIcon.barCount)
    }
}
