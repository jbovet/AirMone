# AirMone (WiFi Analyzer)

AirMone is a premium, native WiFi analysis and mapping utility for macOS. Designed with a modern SwiftUI interface, it provides deep insights into your wireless environment through visual, statistical, and even auditory feedback.

## Features

### 📡 Real-Time Dashboard
- **Signal Gauge**: High-precision visual representation of current RSSI and signal quality.
- **History Chart**: Linear tracking of signal strength over time.
- **Dynamic Radar Audio**: An immersive audio engine that provides "cinematic" feedback. Reverb and timing intensity change based on signal strength, allowing you to "hear" the WiFi quality.

### 📶 Nearby Networks Exploration
- **Advanced Filtering**: Filter networks by frequency bands (2.4 GHz, 5 GHz, 6 GHz).
- **Smart Grouping**: Automatically groups access points by SSID while allowing expansion to see individual BSSIDs.
- **Visualization**: Switch between detailed list views and graphical representations of network distribution.
- **Sorting**: Sort by signal strength, channel, or SSID.

### 📍 Location Mapping & Measurements
- **Measurement Points**: Manually drop markers to record signal strength at specific coordinates within your space.
- **Persistence**: Measurements are saved locally using a robust persistence service.
- **Data Export**: Support for exporting collected data in **CSV** and **JSON** formats for external analysis.

### 🌡️ Signal Heat Map
- **Intelligent Interpolation**: Generates a smooth heatmap based on measured signal points.
- **Visual Insights**: Quickly identify "dead zones" and areas of peak performance in your environment.

### 📊 Comprehensive Statistics
- **Distribution Analysis**: View signal quality distribution across all collected measurements.
- **Detailed Stats**: Track averages, standard deviations, and per-SSID performance metrics.

## Technical Details

- **Platform**: macOS 13.0+
- **Language**: Swift 5.10+
- **Frameworks**: SwiftUI, CoreWLAN, Charts, AVFoundation.
- **Architecture**: MVVM (Model-View-ViewModel).

## Getting Started

### Prerequisites
- A Mac running macOS 13.0 or later.
- Location permissions (required by macOS for WiFi scanning).

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/jbovet/AirMone.git
   ```
2. Open `WiFiAnalyzer.xcodeproj` in Xcode.
3. Select the `WiFiAnalyzer` scheme and a macOS destination.
4. Build and Run (`Cmd + R`).

## Development & Testing

AirMone includes a comprehensive suite of unit tests covering models, view models, and services.

To run the tests:
```bash
xcodebuild test -project WiFiAnalyzer.xcodeproj -scheme WiFiAnalyzer -destination 'platform=macOS'
```

Key test areas:
- `NearbyNetworksTests`: Logic for network grouping, filtering, and ViewModel state.
- `SignalStrengthTests`: Accurate conversion of RSSI to human-readable quality metrics.
- `PersistenceServiceTests`: Reliability of data storage and retrieval.
- `HeatMapInterpolatorTests`: Correctness of interpolation algorithms.

## License

[Add License Information Here - e.g., MIT]
