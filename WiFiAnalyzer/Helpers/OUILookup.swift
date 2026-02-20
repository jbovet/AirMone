//
//  OUILookup.swift
//  WiFiAnalyzer
//
//  Created by Jose Bovet Derpich on 2025.
//  jose.bovet@gmail.com
//  MIT License
//

import Foundation

/// Resolves MAC address OUI (Organizationally Unique Identifier) prefixes to vendor names.
///
/// Loads the full IEEE MA-L registry (~38K entries) from a bundled `oui_compact.csv` file
/// on first access. Friendly name overrides simplify verbose IEEE organization names
/// (e.g. "Apple, Inc." → "Apple").
enum OUILookup {

    /// Returns the vendor name for a given BSSID, or `nil` if unknown.
    /// - Parameter bssid: A MAC address string in `xx:xx:xx:xx:xx:xx` format.
    static func vendor(for bssid: String) -> String? {
        let prefix = oui(from: bssid)
        // Check friendly overrides first, then the IEEE database
        if let friendly = friendlyOverrides[prefix] {
            return friendly
        }
        guard let ieeeName = database[prefix] else { return nil }
        // Apply keyword-based simplification for names not in overrides
        return simplify(ieeeName)
    }

    /// Extracts the OUI prefix (first 3 octets, uppercased) from a BSSID.
    static func oui(from bssid: String) -> String {
        let components = bssid.uppercased().split(separator: ":")
        guard components.count >= 3 else { return "" }
        return components.prefix(3).joined(separator: ":")
    }

    // MARK: - IEEE Database (lazy-loaded from bundled CSV)

    /// The full IEEE OUI database, parsed once from `oui_compact.csv`.
    /// Format per line: `XX:XX:XX,Organization Name`
    private static let database: [String: String] = {
        guard let url = Bundle.main.url(forResource: "oui_compact", withExtension: "csv"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            print("OUILookup: Failed to load oui_compact.csv from bundle")
            return [:]
        }

        var dict = [String: String](minimumCapacity: 40000)
        for line in contents.split(separator: "\n") {
            guard let commaIndex = line.firstIndex(of: ",") else { continue }
            let prefix = String(line[line.startIndex..<commaIndex])
            let name = String(line[line.index(after: commaIndex)...])
            guard !prefix.isEmpty, !name.isEmpty else { continue }
            dict[prefix] = name
        }
        return dict
    }()

    // MARK: - Friendly Name Overrides

    /// Manual overrides for specific OUIs where the IEEE name is misleading
    /// or where we want a more user-friendly label.
    private static let friendlyOverrides: [String: String] = [
        // Eero (IEEE lists as "eero inc." or "Amazon Technologies Inc.")
        "40:49:7C": "Eero",
        "F0:27:2D": "Eero",
        "F0:F0:A4": "Eero",

        // Google Nest (IEEE lists as "Google, Inc.")
        "18:B4:30": "Google Nest",
        "64:16:66": "Google Nest",

        // Amazon Eero alternate OUIs
        "F0:72:EA": "Eero",
    ]

    // MARK: - Name Simplification

    /// Cache for already-simplified organization names to avoid repeated string processing.
    private static var simplifyCache = [String: String]()

    /// Simplifies verbose IEEE organization names to shorter, recognizable vendor names.
    /// Falls through to the original name if no rule matches.
    /// Results are cached so each unique organization name is processed only once.
    private static func simplify(_ name: String) -> String {
        if let cached = simplifyCache[name] {
            return cached
        }
        let result = _simplify(name)
        simplifyCache[name] = result
        return result
    }

    /// Core simplification logic, called once per unique organization name.
    private static func _simplify(_ name: String) -> String {
        let lowered = name.lowercased()

        // Exact prefix matches (order matters: more specific first)
        let prefixRules: [(prefix: String, result: String)] = [
            ("cisco meraki", "Cisco Meraki"),
            ("cisco-linksys", "Linksys"),
            ("cisco systems", "Cisco"),
            ("cisco", "Cisco"),
            ("ubiquiti", "Ubiquiti"),
            ("aruba", "Aruba Networks"),
            ("ruckus", "Ruckus"),
            ("hewlett packard enterprise", "HPE"),
            ("hewlett packard", "HP"),
            ("tp-link", "TP-Link"),
            ("netgear", "Netgear"),
            ("linksys", "Linksys"),
            ("asus", "ASUS"),
            ("asustek", "ASUS"),
            ("apple", "Apple"),
            ("samsung", "Samsung"),
            ("huawei", "Huawei"),
            ("d-link", "D-Link"),
            ("google", "Google"),
            ("amazon", "Amazon"),
            ("intel", "Intel"),
            ("qualcomm", "Qualcomm"),
            ("broadcom", "Broadcom"),
            ("realtek", "Realtek"),
            ("mediatek", "MediaTek"),
            ("microsoft", "Microsoft"),
            ("dell", "Dell"),
            ("juniper", "Juniper"),
            ("extreme networks", "Extreme Networks"),
            ("fortinet", "Fortinet"),
            ("mikrotik", "MikroTik"),
            ("routerboard", "MikroTik"),
            ("zte", "ZTE"),
            ("motorola", "Motorola"),
            ("sonos", "Sonos"),
            ("synology", "Synology"),
            ("xiaomi", "Xiaomi"),
            ("engenius", "EnGenius"),
            ("cambium", "Cambium"),
            ("sophos", "Sophos"),
            ("watchguard", "WatchGuard"),
            ("peplink", "Peplink"),
            ("pepwave", "Peplink"),
            ("zyxel", "Zyxel"),
            ("technicolor", "Technicolor"),
            ("sagemcom", "Sagemcom"),
            ("calix", "Calix"),
            ("arris", "Arris"),
            ("commscope", "CommScope"),
            ("belkin", "Belkin"),
            ("brocade", "Brocade"),
            ("nokia", "Nokia"),
            ("ericsson", "Ericsson"),
            ("eero", "Eero"),
            ("sony", "Sony"),
            ("lg electronics", "LG"),
            ("lg innotek", "LG"),
            ("lenovo", "Lenovo"),
            ("hon hai", "Foxconn"),
            ("foxconn", "Foxconn"),
            ("murata", "Murata"),
            ("espressif", "Espressif"),
            ("texas instruments", "TI"),
            ("raspberry pi", "Raspberry Pi"),
        ]

        for rule in prefixRules {
            if lowered.hasPrefix(rule.prefix) || lowered.contains(rule.prefix) {
                return rule.result
            }
        }

        // Strip common suffixes for cleaner display
        var cleaned = name
        let suffixes = [
            ", Inc.", ", Inc", " Inc.", " Inc",
            ", Ltd.", ", Ltd", " Ltd.", " Ltd",
            ", LLC", " LLC",
            " Co.", " Co",
            " Corp.", " Corp",
            " Corporation",
            " Technologies",
            " Technology",
            " Headquarters",
            " International",
            " Communications",
            " Electronics",
            " Semiconductor",
        ]
        for suffix in suffixes {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
                break
            }
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }
}
