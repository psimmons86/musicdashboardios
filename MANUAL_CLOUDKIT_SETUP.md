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

## 3. CloudKit Schema Setup

The schema setup script (setup-cloudkit-schema.swift) will automatically create:

1. Track Record Type with fields:
   - id (String)
   - title (String)
   - artist (String)
   - albumTitle (String)
   - artworkURL (String)
   - playCount (Number)
   - lastPlayed (Date/Time)

2. ListeningSession Record Type with fields:
   - startTime (Date/Time)
   - duration (Number)
   - trackIds (String - comma-separated list)

To run the script:
```bash
# Build the script
swiftc -sdk $(xcrun --show-sdk-path --sdk macosx) setup-cloudkit-schema.swift

# Run it
./setup-cloudkit-schema
```

The script will:
- Connect to your CloudKit container
- Create both record types with proper fields
- Set up sample records to establish the schema
- Print progress as it runs

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
CloudKit support is enabled by checking "Include CloudKit support" under the iCloud capability. The interface shows this as a radio button option under iCloud, not as a separate capability or service to configure.

## Troubleshooting Schema Setup

If the schema setup script fails:
1. Ensure you're signed into iCloud on your Mac
2. Check that the container ID matches exactly
3. Verify you have proper entitlements
4. Try running the script with sudo if needed
5. Check Console.app for any CloudKit-related errors
