import SwiftUI

enum NavigationItem: String, CaseIterable {
    case signalMonitor = "Signal Monitor"
    case nearbyNetworks = "Nearby Networks"
    case markedLocations = "Marked Locations"
    case statistics = "Statistics"
    case heatMap = "Heat Map"
    case support = "Support"

    var icon: String {
        switch self {
        case .signalMonitor:
            return "wifi"
        case .nearbyNetworks:
            return "antenna.radiowaves.left.and.right"
        case .markedLocations:
            return "mappin.and.ellipse"
        case .statistics:
            return "chart.bar.fill"
        case .heatMap:
            return "map.fill"
        case .support:
            return "heart.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .signalMonitor

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, id: \.self, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .navigationTitle("WiFi Analyzer")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .signalMonitor:
                    DashboardView()
                case .nearbyNetworks:
                    NearbyNetworksView()
                case .markedLocations:
                    MeasurementsListView()
                case .statistics:
                    StatisticsView()
                case .heatMap:
                    HeatMapView()
                case .support:
                    SupportView()
                }
            } else {
                Text("Select an item")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
