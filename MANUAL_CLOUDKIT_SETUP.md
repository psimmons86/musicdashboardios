# Manual CloudKit Setup Guide

## 1. Apple Developer Portal Setup

1. Go to https://developer.apple.com/account/
2. Select "Certificates, Identifiers & Profiles"
3. Under "Identifiers", find or create your app ID (com.musicdashboard.app)
4. Enable the iCloud capability:
   - Click the checkbox next to iCloud
   - Under iCloud services, select "CloudKit"
   - Click "Configure" next to iCloud
   - Create a new iCloud Container with ID: iCloud.com.musicdashboard.stats
   - Select "Development" environment
   - Save the changes

## 2. Xcode Setup

1. Open Xcode (not VS Code)
2. Create a new project or open existing one
3. Select your target
4. Go to "Signing & Capabilities" tab
5. Click "+" button to add capability
6. Add "iCloud" capability:
   - In the iCloud section that appears:
     - Check "CloudKit"
     - Click "+" under Containers
     - Add container: iCloud.com.musicdashboard.stats
7. Save changes

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

## 4. Verify Setup

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

## 5. Testing

1. After manual setup, open project in VS Code
2. Build and run
3. If issues persist:
   - Clean build folder
   - Delete derived data
   - Reset package caches
   - Re-run build

## Note
CloudKit is enabled through the iCloud capability - there is no separate CloudKit capability to add. The iCloud capability with CloudKit service selected will set up all the necessary entitlements and configurations.
