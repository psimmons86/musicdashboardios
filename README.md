# Music Dashboard iOS App

A SwiftUI-based iOS application that allows users to manage their music library, create playlists, and view streaming statistics using a backend API for Apple Music integration.

## Features

- Apple Music Integration via Backend API
- Playlist Generation
- Streaming Statistics
- User Profile Management

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Apple Developer Account
- Backend API access (for music services)

## Setup

1. Clone the repository
2. Install XcodeGen if not already installed:
   ```bash
   brew install xcodegen
   ```
3. Generate the Xcode project:
   ```bash
   cd musicdashboard
   xcodegen generate
   ```
4. Open the generated Xcode project:
   ```bash
   xed .
   ```
5. Set up your development team in Xcode
6. Configure the backend API endpoint in AppleMusicService.swift
7. Build and run the project

## Project Structure

- `Sources/`: Main source code directory
  - `Views/`: SwiftUI views
  - `Services/`: Business logic and services
  - `Assets.xcassets/`: App assets
  - `Info.plist`: App configuration
  - `LaunchScreen.storyboard`: Launch screen

## Development

The app is built using:
- SwiftUI for the UI
- Backend API for Apple Music integration
- Combine for reactive programming
- MVVM architecture

## License

This project is for demonstration purposes only and is not intended for distribution.
