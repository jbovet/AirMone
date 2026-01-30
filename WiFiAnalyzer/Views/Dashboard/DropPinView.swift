import SwiftUI

struct DropPinView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var locationName: String
    let network: WiFiNetwork
    let onSave: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Drop Pin")
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
