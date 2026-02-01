import SwiftUI

struct LocationMappingView: View {
    @ObservedObject var viewModel: HeatMapViewModel
    @Environment(\.dismiss) var dismiss

    @State private var draggedLocation: String?
    @State private var canvasSize: CGSize = .zero
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Map Measurement Locations")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Drag pins to their physical positions on the floor")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    viewModel.saveCoordinateMapping()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Main canvas
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    GridPattern()

                    // Location pins
                    ForEach(allLocationNames(), id: \.self) { locationName in
                        DraggablePinView(
                            locationName: locationName,
                            coordinate: coordinateBinding(for: locationName),
                            canvasSize: geometry.size,
                            isUnmapped: viewModel.unmappedLocations.contains(locationName)
                        )
                    }
                }
                .onAppear {
                    canvasSize = geometry.size
                }
            }

            Divider()

            // Footer with actions
            HStack {
                // Unmapped locations warning
                if !viewModel.unmappedLocations.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.unmappedLocations.count) unmapped location\(viewModel.unmappedLocations.count == 1 ? "" : "s")")
                            .font(.subheadline)
                    }
                }

                Spacer()

                Button("Auto-Arrange") {
                    autoArrangeLocations()
                }

                Button("Reset All") {
                    showingResetConfirmation = true
                }

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 800, height: 600)
        .alert("Reset All Coordinates", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                viewModel.resetCoordinates()
            }
        } message: {
            Text("Are you sure you want to reset all location coordinates? You will need to reposition all pins.")
        }
    }

    private func allLocationNames() -> [String] {
        let allMeasurements = PersistenceService.shared.load()
        return Array(Set(allMeasurements.map(\.locationName))).sorted()
    }

    private func coordinateBinding(for locationName: String) -> Binding<LocationCoordinate> {
        Binding(
            get: {
                LocationMappingService.shared.coordinate(for: locationName) ?? LocationCoordinate(x: 0.5, y: 0.5)
            },
            set: { newCoordinate in
                LocationMappingService.shared.setCoordinate(newCoordinate, for: locationName)
            }
        )
    }

    private func autoArrangeLocations() {
        let locationNames = allLocationNames()
        LocationMappingService.shared.applyGridLayout(for: locationNames)
        viewModel.loadMeasurements()
    }
}

struct DraggablePinView: View {
    let locationName: String
    @Binding var coordinate: LocationCoordinate
    let canvasSize: CGSize
    let isUnmapped: Bool

    @State private var isDragging: Bool = false

    var body: some View {
        let position = coordinate.toCGPoint(in: canvasSize)

        VStack(spacing: 2) {
            // Pin icon
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(isUnmapped ? .orange : .blue)
                .shadow(color: .black.opacity(0.3), radius: 2)

            // Location label
            Text(locationName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.2), radius: 1)
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newCoordinate = LocationCoordinate.from(point: value.location, in: canvasSize)
                    coordinate = newCoordinate
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .opacity(isDragging ? 0.8 : 1.0)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}

struct GridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 40
                let width = geometry.size.width
                let height = geometry.size.height

                // Vertical lines
                for x in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }

                // Horizontal lines
                for y in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        }
    }
}

#Preview {
    LocationMappingView(viewModel: HeatMapViewModel())
}
