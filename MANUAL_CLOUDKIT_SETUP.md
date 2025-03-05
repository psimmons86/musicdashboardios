# Manual CloudKit Setup Guide

## 1. Apple Developer Portal Setup

1. Go to https://developer.apple.com/account/
2. Select "Certificates, Identifiers & Profiles"
3. Under "Identifiers", find or create your app ID (com.musicdashboard.app)
4. Enable the following capabilities:
   - iCloud
   - CloudKit
5. Click "Configure" next to CloudKit and:
   - Create a new iCloud Container with ID: iCloud.com.musicdashboard.stats
   - Select "Development" environment
   - Save the changes

## 2. Xcode Setup

1. Open Xcode (not VS Code)
2. Create a new project or open existing one
3. Select your target
4. Go to "Signing & Capabilities" tab
5. Click "+" button to add capabilities
6. Add:
   - iCloud
   - CloudKit
7. Under iCloud:
   - Check "CloudKit"
   - Add container: iCloud.com.musicdashboard.stats
8. Save changes

## 3. CloudKit Dashboard Setup

1. Go to https://icloud.developer.apple.com/dashboard/
2. Select your container: iCloud.com.musicdashboard.stats
3. Go to "Schema" section
4. Add Record Types:
   - Track
     - id (String)
     - title (String)
     - artist (String)
     - albumTitle (String)
     - artworkURL (String)
     - playCount (Number)
     - lastPlayed (Date/Time)
   - ListeningSession
     - startTime (Date/Time)
     - duration (Number)
     - trackIds (List of Strings)

## 4. Testing

1. After manual setup, open project in VS Code
2. Build and run
3. If issues persist:
   - Clean build folder
   - Delete derived data
   - Reset package caches
   - Re-run build

## Note
The manual setup creates proper entitlements and provisioning profiles that our project.yml and Package.swift configurations will use.
