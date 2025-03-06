# Apple Music Integration Setup

This guide explains how to set up Apple Music integration for the Music Dashboard app.

## Prerequisites

- An Apple Developer Program membership
- Access to the [Apple Developer Portal](https://developer.apple.com/account/)
- Your app's bundle identifier

## What's Been Done

The following steps have already been completed:

1. Registered a media identifier in the Apple Developer Portal
2. Created a private key with MusicKit service enabled
3. Obtained the Team ID (4Y39R5M676) and Key ID (97K5H5UANT)
4. Created a script to copy the private key from the Downloads folder to the project's Resources directory
5. Updated the AppleMusicService.swift file to load the private key from the app bundle and generate a JWT token

## How to Use

### 1. Run the Copy Script

The `copy-private-key.sh` script has been created to copy your private key from the Downloads folder to the project's Resources directory. The script has already been run, and the private key has been copied to:

```
/Users/admin/code/firebaseappversions/musicdashboard/Resources/AuthKey_97K5H5UANT.p8
```

### 2. Add the Private Key to Your Xcode Project

To make the private key available in your app bundle, you need to add it to your Xcode project:

1. Open your Xcode project
2. Right-click on the Resources group in the Project Navigator (or create one if it doesn't exist)
3. Select "Add Files to [Your Project]..."
4. Navigate to the Resources directory and select the AuthKey_97K5H5UANT.p8 file
5. Make sure "Copy items if needed" is checked
6. Click "Add"

### 3. Update Your Info.plist

Make sure your Info.plist includes the necessary entries for MusicKit:

```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your Apple Music library to provide personalized recommendations and playlists.</string>
```

### 4. Test the Integration

The AppleMusicService.swift file has been updated to:

- Load the private key from the app bundle
- Generate a JWT token for Apple Music API requests
- Handle authentication with Apple Music
- Provide methods for accessing Apple Music features

To test the integration:

1. Build and run the app
2. The app will request authorization to access Apple Music
3. Once authorized, you should be able to access Apple Music features

## Troubleshooting

If you encounter issues with the Apple Music integration:

### Private Key Not Found

If you see the error "Private key file not found in app bundle", make sure:

1. The private key file has been added to your Xcode project
2. The file is included in the app bundle (check the "Target Membership" in the File Inspector)
3. The filename in the code matches the actual filename (currently set to "AuthKey_97K5H5UANT.p8")

### Failed to Generate Developer Token

If you see the error "Failed to generate developer token", check:

1. The Team ID and Key ID are correct in the AppleMusicService.swift file
2. The private key file is valid and properly formatted
3. The app has the necessary entitlements for MusicKit

### Not Authorized to Access Apple Music

If you see the error "Not authorized to access Apple Music", the user may have denied permission. You can:

1. Ask the user to grant permission in the Settings app
2. Call `requestAuthorization()` again to prompt the user

## Additional Resources

- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [Apple Music API Documentation](https://developer.apple.com/documentation/applemusicapi)
- [JWT Specification](https://datatracker.ietf.org/doc/html/rfc7519)
