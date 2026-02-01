import SwiftUI

enum NavigationItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case nearbyNetworks = "Nearby Networks"
    case measurements = "Measurements"
    case statistics = "Statistics"
    case heatMap = "Heat Map"

    var icon: String {
        switch self {
        case .dashboard:
            return "wifi"
        case .nearbyNetworks:
            return "antenna.radiowaves.left.and.right"
        case .measurements:
            return "mappin.and.ellipse"
        case .statistics:
            return "chart.bar.fill"
        case .heatMap:
            return "map.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard

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
                case .dashboard:
                    DashboardView()
                case .nearbyNetworks:
                    NearbyNetworksView()
                case .measurements:
                    MeasurementsListView()
                case .statistics:
                    StatisticsView()
                case .heatMap:
                    HeatMapView()
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
