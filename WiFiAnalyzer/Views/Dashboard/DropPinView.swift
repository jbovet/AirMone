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
                    .onSubmit {
                        if canSave {
                            saveAndDismiss()
                        }
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
        !locationName.trimmingCharacters(in: .whitespaces).isEmpty
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
