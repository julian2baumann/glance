# Glance

A native iOS app that lets health-active adults enter, retrieve, and visualize their health markers faster than any existing workaround. Look up any health number in under 10 seconds.

**Core loop:** Enter health data after appointments → review trends and AI-generated doctor questions before the next appointment.

## Features

- **Markers tab** — Track up to 30+ predefined health markers (cholesterol, glucose, A1C, vitamins, thyroid, and more), plus custom markers
- **Trend charts** — Time-series charts with reference range bands, out-of-range highlighting, and trend arrows
- **Quick Add & Batch Entry** — Log a single value in seconds or enter a full lab panel at once
- **Visits tab** — Log doctor visits with date, doctor name, visit type, and notes
- **Next Visit Prep** — AI-generated (deterministic) discussion prompts for markers that are out of range or trending toward a boundary
- **Search** — Find any marker by name or alias ("good cholesterol" → HDL)
- **Export** — JSON and CSV export via iOS share sheet
- **Biometric lock** — Optional Face ID / Touch ID app lock
- **Privacy-first** — All data stays on device. No backend, no cloud, no analytics.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Platform | iOS 17+ |
| UI | SwiftUI |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Auth | LocalAuthentication |
| Dependencies | None — zero external packages |

## Requirements

- Xcode 15+ (Xcode 16 recommended)
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

## Build & Run

```bash
# 1. Install XcodeGen (if not already installed)
brew install xcodegen

# 2. Generate the Xcode project
cd /path/to/glance
xcodegen generate --spec project.yml

# 3. Open in Xcode
open Glance.xcodeproj

# 4. Select a simulator and run (⌘R)
```

## Project Structure

```
Glance/
├── App/
│   └── GlanceApp.swift               # Entry point, SwiftData container setup
├── Models/
│   ├── Profile.swift                 # Silent default profile (future multi-profile)
│   ├── MarkerCategory.swift          # Category grouping (Heart, Metabolic, etc.)
│   ├── MarkerDefinition.swift        # ~30 predefined + custom markers
│   ├── UserMarker.swift              # "I track this marker"
│   ├── MarkerEntry.swift             # Every recorded health value
│   ├── Visit.swift                   # Doctor visit records
│   └── VisitPrepInsight.swift        # Computed visit prep suggestions (not persisted)
├── Repositories/
│   ├── DataRepository.swift          # Protocol
│   └── LocalDataRepository.swift    # SwiftData implementation
├── Services/
│   ├── InsightsEngine.swift          # Status + trend calculation, visit prep insights
│   ├── SearchService.swift           # Alias-aware marker search
│   └── MarkerLibrary.swift           # JSON seeding service
├── ViewModels/                       # @Observable view models (one per screen)
├── Views/
│   ├── Onboarding/                   # First-launch marker selection
│   ├── Home/                         # Markers tab
│   ├── MarkerDetail/                 # Detail view + trend chart + entry list
│   ├── Entry/                        # Quick Add and Batch Entry flows
│   ├── Visits/                       # Visits tab + Add/Edit visit
│   ├── Settings/                     # Marker management, export, biometric lock
│   └── Components/                   # Shared components (MarkerRow, TrendChart, etc.)
├── Resources/
│   ├── Assets.xcassets               # Colors, icons
│   ├── MarkerData.json               # Predefined marker definitions
│   └── PrivacyPolicy.md              # Privacy policy (displayed in Settings)
└── Extensions/
    └── PreviewHelpers.swift          # SwiftData preview containers
```

## Running Tests

### Unit Tests

```bash
xcodebuild test \
  -project Glance.xcodeproj \
  -scheme GlanceTests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Expected: 103+ tests, 0 failures.

### UI Tests

```bash
xcodebuild test \
  -project Glance.xcodeproj \
  -scheme GlanceUITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

UI tests cover: tab navigation, onboarding flow, quick-add, batch entry, visit logging, and search.

## Privacy

All health data is stored locally in the iOS app container using SwiftData. No data is transmitted to any server. No third-party analytics or SDKs are used.

See [Glance/Resources/PrivacyPolicy.md](Glance/Resources/PrivacyPolicy.md) for full details.
