import Foundation
import CoreWLAN
import CoreLocation
import SystemConfiguration

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
            print("Requesting location authorization...")
        case .denied, .restricted:
            print("Location access denied or restricted - WiFi scanning may not work")
        case .authorizedAlways:
            print("Location access authorized - WiFi scanning enabled")
        @unknown default:
            print("Unknown authorization status")
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("Location authorization status changed: \(status.rawValue)")
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

    private func getBand(for channel: Int) -> String {
        // 2.4 GHz: Channels 1-14
        // 5 GHz: Channels 36-165
        if channel >= 1 && channel <= 14 {
            return "2.4 GHz"
        } else if channel >= 36 && channel <= 165 {
            return "5 GHz"
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

    func isWiFiAvailable() -> Bool {
        return wifiClient.interface() != nil
    }
}
