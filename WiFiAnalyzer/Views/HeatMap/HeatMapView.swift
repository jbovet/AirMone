import SwiftUI

struct HeatMapView: View {
    @StateObject private var viewModel = HeatMapViewModel()
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.measurements.isEmpty && !viewModel.hasCoordinates {
                    emptyStateView
                } else {
                    heatMapContent(size: geometry.size)
                }

                // Loading overlay
                if viewModel.isGenerating {
                    VStack {
                        ProgressView("Generating heat map...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                }
            }
        }
        .navigationTitle("Heat Map")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // SSID Filter
                if !viewModel.uniqueSSIDs.isEmpty {
                    Picker("Network", selection: $viewModel.selectedSSID) {
                        Text("All Networks").tag(nil as String?)
                        Divider()
                        ForEach(viewModel.uniqueSSIDs, id: \.self) { ssid in
                            Text(ssid).tag(ssid as String?)
                        }
                    }
                    .frame(width: 150)
                }

                // Resolution Control
                Menu {
                    Picker("Grid Resolution", selection: $viewModel.gridResolution) {
                        Text("20×20 (Fast)").tag(20)
                        Text("30×30 (Balanced)").tag(30)
                        Text("50×50 (Default)").tag(50)
                        Text("75×75 (Detailed)").tag(75)
                        Text("100×100 (High Detail)").tag(100)
                    }
                } label: {
                    Label("Resolution", systemImage: "square.grid.3x3")
                }


                // Reset View
                Button(action: {
                    withAnimation {
                        zoomScale = 1.0
                        panOffset = .zero
                    }
                }) {
                    Label("Reset View", systemImage: "arrow.counterclockwise")
                }

                // Coordinate Setup
                Button(action: {
                    viewModel.showCoordinateMappingSheet = true
                }) {
                    Label("Map Locations", systemImage: "map.fill")
                }

                // Export
                Button(action: exportAsPNG) {
                    Label("Export as PNG", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            viewModel.loadMeasurements()
        }
        .onChange(of: viewModel.selectedSSID) { _ in
            viewModel.loadMeasurements()
        }
        .onChange(of: viewModel.gridResolution) { _ in
            viewModel.generateHeatMap()
        }
        .sheet(isPresented: $viewModel.showCoordinateMappingSheet) {
            LocationMappingView(viewModel: viewModel)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Heat Map Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take some measurements and map their locations to generate a heat map visualization.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showCoordinateMappingSheet = true
            }) {
                Label("Map Locations", systemImage: "map.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func heatMapContent(size: CGSize) -> some View {
        VStack(spacing: 0) {
            // Main heat map canvas
            ZStack {
                // Heat map
                Canvas { context, size in
                    drawHeatMap(context: context, size: size)
                }
                .drawingGroup() // Metal acceleration

                // Measurement point markers
                Canvas { context, size in
                    drawMeasurementPoints(context: context, size: size)
                }
            }
            .scaleEffect(zoomScale)
            .offset(panOffset)
            .gesture(magnificationGesture)
            .gesture(dragGesture)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Legend
            HeatMapLegendView()
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private func drawHeatMap(context: GraphicsContext, size: CGSize) {
        let grid = viewModel.heatMapGrid
        guard !grid.isEmpty else { return }

        let cellWidth = size.width / CGFloat(grid[0].count)
        let cellHeight = size.height / CGFloat(grid.count)

        for (row, rowData) in grid.enumerated() {
            for (col, rssi) in rowData.enumerated() {
                let rect = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )

                let color = SignalStrength.from(rssi: rssi).color
                context.fill(
                    Path(rect),
                    with: .color(color.opacity(0.6))
                )
            }
        }
    }

    private func drawMeasurementPoints(context: GraphicsContext, size: CGSize) {
        for measurement in viewModel.measurements {
            let point = measurement.coordinate.toCGPoint(in: size)

            // Draw pin marker
            let pinPath = Path { path in
                path.addEllipse(in: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
            }

            context.fill(pinPath, with: .color(.white))
            context.stroke(pinPath, with: .color(.black), lineWidth: 2)

            // Draw location label
            let text = Text(measurement.locationName)
                .font(.caption)
                .foregroundColor(.black)

            context.draw(text, at: CGPoint(x: point.x, y: point.y - 15))
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoomScale = max(0.5, min(5.0, value))
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                panOffset = value.translation
            }
    }

    private func exportAsPNG() {
        let size = CGSize(width: 2000, height: 2000)
        guard let image = renderHeatMapToImage(size: size) else {
            return
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "heatmap.png"
        panel.allowedContentTypes = [.png]

        if panel.runModal() == .OK, let url = panel.url {
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }

    private func renderHeatMapToImage(size: CGSize) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        // Draw heat map grid
        let grid = viewModel.heatMapGrid
        guard !grid.isEmpty else {
            image.unlockFocus()
            return nil
        }

        let cellWidth = size.width / CGFloat(grid[0].count)
        let cellHeight = size.height / CGFloat(grid.count)

        for (row, rowData) in grid.enumerated() {
            for (col, rssi) in rowData.enumerated() {
                let rect = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )

                let color = SignalStrength.from(rssi: rssi).color
                context.setFillColor(NSColor(color).withAlphaComponent(0.6).cgColor)
                context.fill(rect)
            }
        }

        // Draw measurement points with labels
        for measurement in viewModel.measurements {
            let point = measurement.coordinate.toCGPoint(in: size)

            // Draw pin marker circle
            let pinRect = CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
            context.setFillColor(NSColor.white.cgColor)
            context.fillEllipse(in: pinRect)
            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(3)
            context.strokeEllipse(in: pinRect)

            // Draw location name label
            let label = measurement.locationName as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: NSColor.black,
                .backgroundColor: NSColor.white.withAlphaComponent(0.9)
            ]

            let labelSize = label.size(withAttributes: attributes)
            let labelRect = CGRect(
                x: point.x - labelSize.width / 2,
                y: point.y - labelSize.height - 15,
                width: labelSize.width + 8,
                height: labelSize.height + 4
            )

            // Draw background for label
            context.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
            context.fill(labelRect)
            context.setStrokeColor(NSColor.black.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(1)
            context.stroke(labelRect)

            // Draw text
            label.draw(
                at: CGPoint(x: labelRect.origin.x + 4, y: labelRect.origin.y + 2),
                withAttributes: attributes
            )
        }

        image.unlockFocus()
        return image
    }
}

#Preview {
    NavigationStack {
        HeatMapView()
    }
}
