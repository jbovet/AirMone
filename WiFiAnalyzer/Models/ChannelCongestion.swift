import Foundation

struct ChannelCongestion: Identifiable {
    let channel: Int
    let band: String
    let networkCount: Int
    let overlappingCount: Int   // Networks on overlapping channels (2.4 GHz only)
    let totalCount: Int         // networkCount + overlappingCount
    let averageRSSI: Int
    let strongestRSSI: Int

    var id: Int { channel }

    var congestionLevel: CongestionLevel {
        if totalCount == 0 { return .free }
        if totalCount <= 1 { return .low }
        if totalCount <= 3 { return .moderate }
        if totalCount <= 5 { return .high }
        return .veryHigh
    }
}

enum CongestionLevel: String {
    case free = "Free"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
}

struct ChannelRecommendation: Identifiable {
    let channel: Int
    let band: String
    let reason: String
    let congestionLevel: CongestionLevel

    var id: String { "\(band)_\(channel)" }
}

enum ChannelAnalyzer {

    // Standard 2.4 GHz non-overlapping channels
    private static let recommended2_4Channels = [1, 6, 11]

    // All standard 5 GHz channels
    private static let standard5GHzChannels = [36, 40, 44, 48, 52, 56, 60, 64,
                                                100, 104, 108, 112, 116, 120, 124, 128,
                                                132, 136, 140, 144, 149, 153, 157, 161, 165]

    /// Analyze channel congestion from a list of nearby networks
    static func analyze(networks: [NearbyNetwork]) -> [ChannelCongestion] {
        let byChannel = Dictionary(grouping: networks, by: { $0.channel })

        // Build congestion for each observed channel
        var congestions: [ChannelCongestion] = []

        let allChannels = Set(networks.map { $0.channel })
        for channel in allChannels.sorted() {
            let directNetworks = byChannel[channel] ?? []
            let band = directNetworks.first?.band ?? bandForChannel(channel)

            // Count overlapping networks (2.4 GHz channels overlap +/- 4 channels)
            let overlapping: [NearbyNetwork]
            if band == "2.4 GHz" {
                overlapping = networks.filter { network in
                    network.channel != channel
                    && network.band == "2.4 GHz"
                    && abs(network.channel - channel) < 5
                }
            } else {
                overlapping = []
            }

            let allAffecting = directNetworks + overlapping
            let avgRSSI = allAffecting.isEmpty ? -100 : allAffecting.map(\.rssi).reduce(0, +) / allAffecting.count
            let strongestRSSI = allAffecting.map(\.rssi).max() ?? -100

            congestions.append(ChannelCongestion(
                channel: channel,
                band: band,
                networkCount: directNetworks.count,
                overlappingCount: overlapping.count,
                totalCount: allAffecting.count,
                averageRSSI: avgRSSI,
                strongestRSSI: strongestRSSI
            ))
        }

        return congestions.sorted { $0.channel < $1.channel }
    }

    /// Recommend the best channels per band
    static func recommend(networks: [NearbyNetwork]) -> [ChannelRecommendation] {
        var recommendations: [ChannelRecommendation] = []

        let bands = Set(networks.map { $0.band })

        if bands.contains("2.4 GHz") || networks.isEmpty {
            if let rec = recommendFor2_4GHz(networks: networks) {
                recommendations.append(rec)
            }
        }

        if bands.contains("5 GHz") || networks.isEmpty {
            if let rec = recommendFor5GHz(networks: networks) {
                recommendations.append(rec)
            }
        }

        return recommendations
    }

    private static func recommendFor2_4GHz(networks: [NearbyNetwork]) -> ChannelRecommendation? {
        let networks2_4 = networks.filter { $0.band == "2.4 GHz" }

        // Evaluate only the non-overlapping channels (1, 6, 11)
        var bestChannel = 1
        var bestScore = Int.max

        for channel in recommended2_4Channels {
            // Count networks on this channel and overlapping ones
            let directCount = networks2_4.filter { $0.channel == channel }.count
            let overlappingCount = networks2_4.filter {
                $0.channel != channel && abs($0.channel - channel) < 5
            }.count

            // Score: direct networks weigh more than overlapping
            let score = directCount * 3 + overlappingCount
            if score < bestScore {
                bestScore = score
                bestChannel = channel
            }
        }

        let level: CongestionLevel
        if bestScore == 0 { level = .free }
        else if bestScore <= 2 { level = .low }
        else if bestScore <= 5 { level = .moderate }
        else { level = .high }

        let directOnBest = networks2_4.filter { $0.channel == bestChannel }.count
        let reason: String
        if directOnBest == 0 {
            reason = "No networks on channel \(bestChannel)"
        } else {
            let totalOnBest = directOnBest + networks2_4.filter {
                $0.channel != bestChannel && abs($0.channel - bestChannel) < 5
            }.count
            reason = "\(directOnBest) network\(directOnBest == 1 ? "" : "s") (\(totalOnBest) including overlap)"
        }

        return ChannelRecommendation(
            channel: bestChannel,
            band: "2.4 GHz",
            reason: reason,
            congestionLevel: level
        )
    }

    private static func recommendFor5GHz(networks: [NearbyNetwork]) -> ChannelRecommendation? {
        let networks5 = networks.filter { $0.band == "5 GHz" }
        let usedChannels = Set(networks5.map { $0.channel })

        // Find a free channel first
        for channel in standard5GHzChannels where !usedChannels.contains(channel) {
            return ChannelRecommendation(
                channel: channel,
                band: "5 GHz",
                reason: "No networks on this channel",
                congestionLevel: .free
            )
        }

        // If all channels have networks, pick the least congested
        let byChannel = Dictionary(grouping: networks5, by: { $0.channel })
        if let (bestCh, nets) = byChannel.min(by: { $0.value.count < $1.value.count }) {
            let level: CongestionLevel
            if nets.count <= 1 { level = .low }
            else if nets.count <= 3 { level = .moderate }
            else { level = .high }

            return ChannelRecommendation(
                channel: bestCh,
                band: "5 GHz",
                reason: "\(nets.count) network\(nets.count == 1 ? "" : "s") on this channel",
                congestionLevel: level
            )
        }

        return nil
    }

    private static func bandForChannel(_ channel: Int) -> String {
        if channel >= 1 && channel <= 14 { return "2.4 GHz" }
        if channel >= 36 && channel <= 165 { return "5 GHz" }
        if channel > 165 { return "6 GHz" }
        return "Unknown"
    }
}
