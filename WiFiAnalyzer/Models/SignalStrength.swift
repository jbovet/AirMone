import SwiftUI

enum SignalStrength: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case weak = "Weak"
    case poor = "Poor"
    case unusable = "Unusable"

    static func from(rssi: Int) -> SignalStrength {
        switch rssi {
        case -50...0:
            return .excellent
        case -60 ..< -50:
            return .good
        case -70 ..< -60:
            return .fair
        case -80 ..< -70:
            return .weak
        case -90 ..< -80:
            return .poor
        default:
            return .unusable
        }
    }

    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return Color(red: 0.5, green: 0.8, blue: 0.0) // Lime
        case .fair:
            return .yellow
        case .weak:
            return .orange
        case .poor:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Red-orange
        case .unusable:
            return .red
        }
    }

    var percentage: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.83
        case .fair: return 0.66
        case .weak: return 0.5
        case .poor: return 0.33
        case .unusable: return 0.16
        }
    }

    var rangeDescription: String {
        switch self {
        case .excellent:
            return "-50 to -30"
        case .good:
            return "-60 to -50"
        case .fair:
            return "-70 to -60"
        case .weak:
            return "-80 to -70"
        case .poor:
            return "-90 to -80"
        case .unusable:
            return "< -90"
        }
    }
}
