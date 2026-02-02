# Contributing to AirMone

Thank you for your interest in contributing to AirMone! This document provides guidelines and information to help you get started.

## Code of Conduct

By participating in this project you agree to treat all contributors with respect and foster an open, welcoming environment. Harassment and exclusionary behavior are not tolerated.

## How to Contribute

### Reporting Bugs

1. **Search existing issues** — Check [GitHub Issues](https://github.com/jbovet/AirMone/issues) to see if the problem has already been reported.
2. **Open a new issue** with a clear title and description. Include:
   - macOS version
   - Steps to reproduce the issue
   - Expected vs. actual behavior
   - Screenshots or logs if applicable

### Suggesting Features

Open a [GitHub Issue](https://github.com/jbovet/AirMone/issues/new) with the label `enhancement`. Describe:
- The problem your feature would solve
- A proposed solution or approach
- Any alternatives you considered

### Submitting a Pull Request

1. **Fork** the repository and create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Make your changes** following the coding standards below.
3. **Add or update tests** for any new functionality.
4. **Run the full test suite** and ensure it passes:
   ```bash
   xcodebuild test -project WiFiAnalyzer.xcodeproj \
     -scheme WiFiAnalyzer \
     -destination 'platform=macOS'
   ```
5. **Build successfully** with no warnings:
   ```bash
   xcodebuild -scheme WiFiAnalyzer -destination 'platform=macOS' build
   ```
6. **Commit** with a clear, descriptive message (see [Commit Messages](#commit-messages)).
7. **Push** your branch and open a Pull Request against `main`.

## Development Setup

### Prerequisites

| Tool | Version |
|---|---|
| macOS | 14.0+ (Sonoma) |
| Xcode | 15.0+ |
| Swift | 5.10+ |

### Getting Started

```bash
git clone https://github.com/jbovet/AirMone.git
cd AirMone
open WiFiAnalyzer.xcodeproj
```

Select the **WiFiAnalyzer** scheme and press **Cmd + R** to build and run.

> **Note:** WiFi scanning requires Location Services. Grant permission when prompted during development.

## Coding Standards

### Architecture

AirMone follows **MVVM** (Model-View-ViewModel). When adding new features:

- **Models** go in `WiFiAnalyzer/Models/` — Plain data structures, enums, and value types.
- **ViewModels** go in `WiFiAnalyzer/ViewModels/` — `ObservableObject` classes annotated with `@MainActor`.
- **Views** go in `WiFiAnalyzer/Views/<Feature>/` — SwiftUI views grouped by feature module.
- **Services** go in `WiFiAnalyzer/Services/` — Business logic, system integrations, and data access.

### Swift Style

- Use Swift naming conventions (camelCase for properties/methods, PascalCase for types).
- Prefer `let` over `var` whenever possible.
- Use `guard` for early returns.
- Keep functions focused — one responsibility per function.

### Documentation

Every new public `struct`, `class`, `enum`, and non-trivial method should include a Swift DocC comment (`///`).

All source files must include the standard file header:

```swift
//
//  FileName.swift
//  WiFiAnalyzer
//
//  Created by Your Name on YYYY.
//  your.email@example.com
//  MIT License
//
```

### SwiftUI Views

- Keep views small and composable — extract subviews when a `body` exceeds ~50 lines.
- Use `#Preview` macros for all views.
- Prefer `Color(nsColor:)` for macOS system colors.
- Use SF Symbols for icons.

### Testing

- Write unit tests for all models, view models, and services.
- Test files live in `WiFiAnalyzerTests/` and follow the naming convention `<TypeName>Tests.swift`.
- Use descriptive test method names: `testExcellentSignalLowerBound()`, not `test1()`.
- Test boundary conditions and edge cases.

## Commit Messages

Use clear, conventional commit messages:

```
<type>: <short summary>

<optional body with more detail>
```

**Types:**
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation only
- `refactor` — Code restructuring without behavior change
- `test` — Adding or updating tests
- `chore` — Build, CI, tooling changes

**Examples:**
```
feat: add band filtering to nearby networks view
fix: resolve crash when WiFi interface is unavailable
docs: update README with architecture diagram
test: add boundary tests for signal strength mapping
```

## Branch Naming

Use descriptive branch names with a prefix:

- `feature/` — New features (e.g., `feature/channel-overlap-detection`)
- `fix/` — Bug fixes (e.g., `fix/scan-timer-leak`)
- `docs/` — Documentation (e.g., `docs/update-readme`)
- `refactor/` — Refactoring (e.g., `refactor/extract-gauge-drawing`)

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR.
- Fill in the PR description with a summary of changes and a test plan.
- Link any related GitHub issues.
- Ensure CI passes before requesting review.
- Be responsive to review feedback.

## Project Structure

```
WiFiAnalyzer/
├── Models/              # Data models
├── ViewModels/          # State management (ObservableObject)
├── Views/               # SwiftUI views by feature
│   ├── Dashboard/
│   ├── NearbyNetworks/
│   ├── Measurements/
│   ├── HeatMap/
│   └── Statistics/
├── Services/            # Business logic & system integration
└── Helpers/             # Shared utilities

WiFiAnalyzerTests/       # Unit tests
scripts/                 # Build and release scripts
.github/workflows/       # CI/CD pipelines
```

## License

By contributing to AirMone, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for helping make AirMone better!
