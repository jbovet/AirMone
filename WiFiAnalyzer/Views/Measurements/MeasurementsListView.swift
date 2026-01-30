import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MeasurementsListView: View {
    @StateObject private var viewModel = MeasurementsViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var exportMessage = ""
    @State private var importMessage = ""
    @State private var isExportError = false
    @State private var isImportError = false

    var body: some View {
        Group {
            if viewModel.measurements.isEmpty {
                emptyStateView
            } else {
                measurementsList
            }
        }
        .navigationTitle("Measurements")
        .searchable(text: $viewModel.searchText, prompt: "Search by location or SSID")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !viewModel.measurements.isEmpty {
                    // Filter Menu
                    Menu {
                        Button(action: {
                            viewModel.filterQuality = nil
                        }) {
                            Label("All Signals", systemImage: viewModel.filterQuality == nil ? "checkmark" : "")
                        }

                        Divider()

                        ForEach(SignalStrength.allCases, id: \.self) { quality in
                            Button(action: {
                                viewModel.filterQuality = quality
                            }) {
                                HStack {
                                    Circle()
                                        .fill(quality.color)
                                        .frame(width: 10, height: 10)
                                    Text(quality.rawValue)
                                    if viewModel.filterQuality == quality {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    // Sort Menu
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }

                    // Export Menu
                    Menu {
                        Button(action: {
                            handleExport(format: .csv)
                        }) {
                            Label("Export as CSV", systemImage: "doc.text")
                        }

                        Button(action: {
                            handleExport(format: .json)
                        }) {
                            Label("Export as JSON", systemImage: "doc.badge.gearshape")
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    // Import Menu
                    Menu {
                        Button(action: {
                            handleImport(format: .csv)
                        }) {
                            Label("Import from CSV", systemImage: "doc.text")
                        }

                        Button(action: {
                            handleImport(format: .json)
                        }) {
                            Label("Import from JSON", systemImage: "doc.badge.gearshape")
                        }
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadMeasurements()
        }
        .alert("Clear All Measurements", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                viewModel.deleteAllMeasurements()
            }
        } message: {
            Text("Are you sure you want to delete all measurements? This action cannot be undone.")
        }
        .alert(isExportError ? "Export Failed" : "Export Successful", isPresented: $showingExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportMessage)
        }
        .alert(isImportError ? "Import Failed" : "Import Successful", isPresented: $showingImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .onChange(of: viewModel.sortOption) { _ in
            viewModel.loadMeasurements()
        }
    }

    // MARK: - Helper Methods

    private func handleExport(format: ExportFormat) {
        let result: Result<URL, Error>

        switch format {
        case .csv:
            result = viewModel.exportToCSV()
        case .json:
            result = viewModel.exportToJSON()
        }

        switch result {
        case .success(let url):
            exportMessage = "Measurements exported successfully to:\n\(url.path)"
            isExportError = false
        case .failure(let error):
            exportMessage = error.localizedDescription
            isExportError = true
        }

        showingExportAlert = true
    }

    private func handleImport(format: ExportFormat) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        switch format {
        case .csv:
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.message = "Select a CSV file to import"
        case .json:
            panel.allowedContentTypes = [.json]
            panel.message = "Select a JSON file to import"
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let result: Result<Int, Error>

        switch format {
        case .csv:
            result = viewModel.importFromCSV(url: url)
        case .json:
            result = viewModel.importFromJSON(url: url)
        }

        switch result {
        case .success(let count):
            importMessage = "Successfully imported \(count) measurement\(count == 1 ? "" : "s")"
            isImportError = false
        case .failure(let error):
            importMessage = error.localizedDescription
            isImportError = true
        }

        showingImportAlert = true
    }

    private var measurementsList: some View {
        List {
            ForEach(viewModel.filteredMeasurements) { measurement in
                MeasurementRowView(measurement: measurement)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteMeasurement(id: measurement.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Measurements Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Use the Drop Pin button on the Dashboard to save WiFi signal measurements at different locations.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        MeasurementsListView()
    }
}
