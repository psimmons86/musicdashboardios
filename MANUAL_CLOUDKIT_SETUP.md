# Manual CloudKit Setup Guide

## 1. Apple Developer Portal Setup

1. Go to https://developer.apple.com/account/
2. Select "Certificates, Identifiers & Profiles"
3. Under "Identifiers", find or create your app ID (com.musicdashboard.app)
4. Enable iCloud:
   - Check the box next to iCloud
   - Select "Include CloudKit support (requires Xcode 6)"
   - Click "Edit"
   - You should see "iCloud Container Assignment"
   - Select "iCloud.com.musicdashboard.stats"
   - Click Continue and save changes

## 2. Create iCloud Container (if not exists)

1. In Apple Developer Portal
2. Go to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" from the left sidebar
4. Click the "+" button to register a new identifier
5. Choose "iCloud Containers"
6. Enter description and identifier:
   - Description: Music Dashboard Stats
   - Identifier: iCloud.com.musicdashboard.stats
7. Click Continue and register

## 3. Xcode Setup

1. Open Xcode (not VS Code)
2. Create a new project or open existing one
3. Select your target
4. Go to "Signing & Capabilities" tab
5. Click "+" button to add capability
6. Add "iCloud" capability
7. In the iCloud section:
   - Check "Include CloudKit support"
   - Click "+" under Containers
   - Select "iCloud.com.musicdashboard.stats"
8. Save changes

## 4. CloudKit Dashboard Setup

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

## 5. Verify Setup

1. Check entitlements file contains:
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.musicdashboard.stats</string>
   </array>
   <key>com.apple.developer.icloud-services</key>
   <array>
       <string>CloudKit</string>
   </array>
   ```

2. Check project.yml has:
   ```yaml
   PRODUCT_BUNDLE_CAPABILITIES:
     - com.apple.developer.icloud-services
     - com.apple.developer.icloud-container-identifiers
   ```

## 6. Testing

1. After manual setup, open project in VS Code
2. Build and run
3. If issues persist:
   - Clean build folder
   - Delete derived data
   - Reset package caches
   - Re-run build

## Note
CloudKit support is enabled by checking "Include CloudKit support" under the iCloud capability. The interface shows this as a radio button option under iCloud, not as a separate capability or service to configure.
