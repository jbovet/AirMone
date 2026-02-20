//
//  DropPinView.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import SwiftUI

/// Modal sheet for saving a WiFi measurement at a named location.
struct DropPinView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var locationName: String
    var recentLocations: [String] = []
    let network: WiFiNetwork
    let onSave: () -> Void
    var existingCount: Int = 0

    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Validation Constants

    private static let maxLocationNameLength = 50
    private static let disallowedCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")

    var body: some View {
        VStack(spacing: 20) {
            Text("Mark Location")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("Location Name")
                    .font(.headline)
                    .foregroundColor(.secondary)

                TextField("e.g., Kitchen, Living Room", text: $locationName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onChange(of: locationName) { _, newValue in
                        // Enforce max length
                        if newValue.count > Self.maxLocationNameLength {
                            locationName = String(newValue.prefix(Self.maxLocationNameLength))
                        }
                    }
                    .onSubmit {
                        if canSave {
                            saveAndDismiss()
                        }
                    }

                // Validation feedback
                HStack {
                    if let error = validationError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Text("\(locationName.count)/\(Self.maxLocationNameLength)")
                        .font(.caption2)
                        .foregroundColor(locationName.count >= Self.maxLocationNameLength ? .orange : .secondary)
                }

                if !recentLocations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentLocations, id: \.self) { location in
                                Button(location) {
                                    locationName = location
                                    saveAndDismiss()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }

                if existingCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("\(existingCount) existing measurement\(existingCount == 1 ? "" : "s") at this location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Signal")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    Circle()
                        .fill(network.signalStrength.color)
                        .frame(width: 12, height: 12)

                    Text(network.ssid)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(network.rssi) dBm")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(width: 350)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private var canSave: Bool {
        validationError == nil && !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns a user-facing validation error, or `nil` if the input is valid.
    private var validationError: String? {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !locationName.isEmpty && trimmed.isEmpty {
            return "Name cannot be only whitespace."
        }

        if trimmed.unicodeScalars.contains(where: { Self.disallowedCharacters.contains($0) }) {
            return "Name cannot contain / \\ : * ? \" < > | characters."
        }

        if locationName.count >= Self.maxLocationNameLength {
            return "Maximum \(Self.maxLocationNameLength) characters reached."
        }

        return nil
    }

    private func saveAndDismiss() {
        onSave()
        dismiss()
    }
}

#Preview {
    DropPinView(
        locationName: .constant(""),
        network: WiFiNetwork(
            ssid: "MyWiFi",
            bssid: "00:11:22:33:44:55",
            channel: 6,
            rssi: -55
        ),
        onSave: {}
    )
}
