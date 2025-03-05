# Music Dashboard iOS

A native iOS app that provides a beautiful interface for managing and exploring your Apple Music library.

## Features

- View streaming statistics and listening history
- Generate personalized playlists
- Browse music news and updates
- Track your favorite artists and songs
- View detailed music analytics

## Requirements

- iOS 17.0+
- Xcode 14.0+
- Apple Music subscription
- Apple Developer account

## Installation

1. Clone the repository:
```bash
git clone https://github.com/psimmons86/musicdashboardios.git
```

2. Open the project:
```bash
cd musicdashboardios
xed .
```

3. Build and run the project in Xcode.

## Configuration

The app requires the following capabilities and entitlements:
- MusicKit
- Background Audio
- Apple Music Library Access

These are already configured in the project settings and entitlements file.

## Architecture

The app follows a clean architecture pattern with:
- SwiftUI views for the UI layer
- Service layer for business logic
- Model layer for data structures
- Native MusicKit integration

## License

This project is licensed under the MIT License - see the LICENSE file for details.
