//
//  WiFiScannerService.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation
import CoreWLAN
import CoreLocation
import SystemConfiguration
import os

/// Errors that can occur when accessing the WiFi interface.
enum WiFiError: LocalizedError {
    case noInterface
    case permissionDenied
    case notConnected

    var errorDescription: String? {
        switch self {
        case .noInterface:
            return "No WiFi interface found. Please ensure WiFi is enabled."
        case .permissionDenied:
            return "Location permission is required to access WiFi information. Please grant permission in System Settings > Privacy & Security > Location Services."
        case .notConnected:
            return "Not connected to any WiFi network."
        }
    }
}

/// Service responsible for scanning WiFi networks using CoreWLAN.
///
/// Provides methods to retrieve the currently connected network (``getCurrentNetwork()``)
/// and to scan for nearby access points (``scanForNearbyNetworks()``).
/// Requires Location Services authorization on macOS for WiFi scanning capabilities.
class WiFiScannerService: NSObject, CLLocationManagerDelegate {
    private let wifiClient: CWWiFiClient
    private let locationManager: CLLocationManager

    override init() {
        self.wifiClient = CWWiFiClient.shared()
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        requestLocationAuthorization()
    }

    private func requestLocationAuthorization() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            // Request location authorization - this should trigger the system dialog
            locationManager.requestAlwaysAuthorization()
            AppLogger.location.info("Requesting location authorization...")
        case .denied, .restricted:
            AppLogger.location.warning("Location access denied or restricted - WiFi scanning may not work")
        case .authorizedAlways:
            AppLogger.location.info("Location access authorized - WiFi scanning enabled")
        @unknown default:
            AppLogger.location.warning("Unknown authorization status")
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        AppLogger.location.debug("Location authorization status changed: \(status.rawValue, privacy: .public)")
    }

    func getCurrentNetwork() throws -> WiFiNetwork {
        guard let interface = wifiClient.interface() else {
            throw WiFiError.noInterface
        }

        guard let ssid = interface.ssid(),
              let bssid = interface.bssid() else {
            throw WiFiError.notConnected
        }

        let rssi = interface.rssiValue()
        let noise = interface.noiseMeasurement()
        let channel = interface.wlanChannel()?.channelNumber ?? 0
        let channelWidth = interface.wlanChannel()?.channelWidth
        let transmitRate = interface.transmitRate()

        // Get IP information
        let ipInfo = getIPAddressInfo()

        // Determine frequency band based on channel
        let band = getBand(for: channel)

        // Get PHY mode (802.11 standard)
        let phyMode = getPhyMode(from: interface)

        // Get security type
        let security = getSecurity(from: interface)

        return WiFiNetwork(
            ssid: ssid,
            bssid: bssid,
            channel: channel,
            rssi: rssi,
            ipAddress: ipInfo.ipAddress,
            routerAddress: ipInfo.routerAddress,
            band: band,
            phyMode: phyMode,
            security: security,
            channelWidth: channelWidth.map { getChannelWidthValue($0) },
            transmitRate: transmitRate,
            noise: noise
        )
    }

    func scanForNearbyNetworks() throws -> [NearbyNetwork] {
        guard let interface = wifiClient.interface() else {
            throw WiFiError.noInterface
        }

        let networks = try interface.scanForNetworks(withSSID: nil)

        let allNetworks = networks.compactMap { cwNetwork -> NearbyNetwork? in
            // Skip hidden networks (no SSID)
            guard let ssid = cwNetwork.ssid, !ssid.isEmpty else { return nil }
            let bssid = cwNetwork.bssid ?? "unknown"
            let channel = cwNetwork.wlanChannel?.channelNumber ?? 0
            let band = getBand(for: channel)
            let channelWidth: Int? = cwNetwork.wlanChannel.map { getChannelWidthValue($0.channelWidth) }

            return NearbyNetwork(
                id: "\(ssid)_\(bssid)",
                ssid: ssid,
                bssid: bssid,
                rssi: cwNetwork.rssiValue,
                noise: cwNetwork.noiseMeasurement,
                channel: channel,
                band: band,
                channelWidth: channelWidth,
                security: getSecurityFromCWNetwork(cwNetwork),
                countryCode: cwNetwork.countryCode,
                isIBSS: cwNetwork.ibss,
                beaconInterval: cwNetwork.beaconInterval,
                timestamp: Date()
            )
        }

        // Deduplicate by id, keeping the entry with the strongest signal
        var bestByID: [String: NearbyNetwork] = [:]
        for network in allNetworks {
            if let existing = bestByID[network.id] {
                if network.rssi > existing.rssi {
                    bestByID[network.id] = network
                }
            } else {
                bestByID[network.id] = network
            }
        }

        return bestByID.values.sorted { $0.rssi > $1.rssi }
    }

    private func getBand(for channel: Int) -> String {
        // 2.4 GHz: Channels 1-14
        // 5 GHz: Channels 36-165
        // 6 GHz: Channels > 165
        if channel >= 1 && channel <= 14 {
            return "2.4 GHz"
        } else if channel >= 36 && channel <= 165 {
            return "5 GHz"
        } else if channel > 165 {
            return "6 GHz"
        }
        return "Unknown"
    }

    private func getPhyMode(from interface: CWInterface) -> String {
        let phyMode = interface.activePHYMode()

        switch phyMode {
        case .mode11a:
            return "802.11a"
        case .mode11b:
            return "802.11b"
        case .mode11g:
            return "802.11g"
        case .mode11n:
            return "802.11n (WiFi 4)"
        case .mode11ac:
            return "802.11ac (WiFi 5)"
        case .mode11ax:
            return "802.11ax (WiFi 6)"
        case .modeNone:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }

    private func getSecurity(from interface: CWInterface) -> String {
        let security = interface.security()

        switch security {
        case .none:
            return "Open (No Security)"
        case .WEP:
            return "WEP (Weak)"
        case .wpaPersonal:
            return "WPA Personal"
        case .wpaPersonalMixed:
            return "WPA/WPA2 Personal"
        case .wpa2Personal:
            return "WPA2 Personal"
        case .personal:
            return "WPA2/WPA3 Personal"
        case .dynamicWEP:
            return "Dynamic WEP"
        case .wpaEnterprise:
            return "WPA Enterprise"
        case .wpaEnterpriseMixed:
            return "WPA/WPA2 Enterprise"
        case .wpa2Enterprise:
            return "WPA2 Enterprise"
        case .enterprise:
            return "WPA2/WPA3 Enterprise"
        case .wpa3Personal:
            return "WPA3 Personal"
        case .wpa3Enterprise:
            return "WPA3 Enterprise"
        case .wpa3Transition:
            return "WPA3 Transition"
        @unknown default:
            return "Unknown"
        }
    }

    private func getChannelWidthValue(_ width: CWChannelWidth) -> Int {
        switch width {
        case .width20MHz:
            return 20
        case .width40MHz:
            return 40
        case .width80MHz:
            return 80
        case .width160MHz:
            return 160
        @unknown default:
            return 0
        }
    }

    private func getIPAddressInfo() -> (ipAddress: String?, routerAddress: String?) {
        var ipAddress: String?
        var routerAddress: String?

        // Get WiFi interface addresses
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return (nil, nil)
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            // Check for WiFi interface (en0 or en1 typically)
            if let name = interface?.ifa_name,
               String(cString: name).starts(with: "en"),
               addrFamily == UInt8(AF_INET) {

                var addr = interface?.ifa_addr.pointee
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                if getnameinfo(&addr!, socklen_t(interface!.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, 0, NI_NUMERICHOST) == 0 {
                    let address = String(cString: hostname)

                    // Store the first valid IP address
                    if ipAddress == nil && !address.isEmpty {
                        ipAddress = address
                    }
                }
            }
        }

        // Get router address (default gateway)
        if let routerIP = getDefaultGateway() {
            routerAddress = routerIP
        }

        return (ipAddress, routerAddress)
    }

    private func getDefaultGateway() -> String? {
        let dynamicStore = SCDynamicStoreCreate(nil, "WiFiAnalyzer" as CFString, nil, nil)
        guard let store = dynamicStore else { return nil }

        let key = SCDynamicStoreKeyCreateNetworkGlobalEntity(nil, kSCDynamicStoreDomainState, kSCEntNetIPv4)
        guard let globalIPv4 = SCDynamicStoreCopyValue(store, key) as? [String: Any],
              let primaryService = globalIPv4[kSCDynamicStorePropNetPrimaryService as String] as? String else {
            return nil
        }

        let serviceKey = SCDynamicStoreKeyCreateNetworkServiceEntity(
            nil,
            kSCDynamicStoreDomainState,
            primaryService as CFString,
            kSCEntNetIPv4
        )

        guard let serviceDict = SCDynamicStoreCopyValue(store, serviceKey) as? [String: Any],
              let router = serviceDict["Router"] as? String else {
            return nil
        }

        return router
    }

    private func getSecurityFromCWNetwork(_ network: CWNetwork) -> String {
        // Check security types from strongest to weakest
        if network.supportsSecurity(.wpa3Personal) || network.supportsSecurity(.wpa3Enterprise) {
            if network.supportsSecurity(.wpa3Enterprise) {
                return "WPA3 Enterprise"
            }
            return "WPA3 Personal"
        }
        if network.supportsSecurity(.wpa2Personal) || network.supportsSecurity(.wpa2Enterprise) {
            if network.supportsSecurity(.wpa2Enterprise) {
                return "WPA2 Enterprise"
            }
            return "WPA2 Personal"
        }
        if network.supportsSecurity(.wpaPersonal) || network.supportsSecurity(.wpaEnterprise) {
            if network.supportsSecurity(.wpaEnterprise) {
                return "WPA Enterprise"
            }
            return "WPA Personal"
        }
        if network.supportsSecurity(.WEP) {
            return "WEP"
        }
        if network.supportsSecurity(.none) {
            return "Open"
        }
        return "Unknown"
    }

    func isWiFiAvailable() -> Bool {
        return wifiClient.interface() != nil
    }
}
