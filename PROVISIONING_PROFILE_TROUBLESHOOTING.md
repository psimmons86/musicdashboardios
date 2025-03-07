# Provisioning Profile Troubleshooting Guide

## Understanding the Issue

You're encountering two related issues with your provisioning profile:

1. **Bundle ID Mismatch**: 
   - Your project configuration (project.yml) uses: `com.musicdashboard.app`
   - Your provisioning profile is for: `com.musicdashboard.MusicDashboard`

2. **Missing MusicKit Entitlement**:
   - Your app's entitlements file includes the MusicKit entitlement
   - Your provisioning profile doesn't include this entitlement

## Solution Options

### Option 1: Update Bundle ID in Project Configuration (Recommended)

This approach aligns your project with your existing provisioning profile:

1. Edit `project.yml` to change the bundle ID:

```yaml
# Change this line in the MusicDashboard target section
PRODUCT_BUNDLE_IDENTIFIER: com.musicdashboard.MusicDashboard
```

2. Regenerate the Xcode project:

```bash
xcodegen generate
```

3. Open the project in Xcode and update the MusicKit entitlement in your Apple Developer account:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
   - Select your App ID (`com.musicdashboard.MusicDashboard`)
   - Enable the MusicKit capability
   - Save changes

4. Regenerate your provisioning profile:
   - Go to [Profiles section](https://developer.apple.com/account/resources/profiles/list)
   - Find your profile for `com.musicdashboard.MusicDashboard`
   - Click "Edit" and then "Generate"
   - Download the new profile
   - Double-click to install it

### Option 2: Create a New Provisioning Profile for Your Current Bundle ID

This approach creates a new profile matching your current project configuration:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Create a new App ID with bundle identifier `com.musicdashboard.app`
3. Enable the MusicKit capability for this App ID
4. Create a new provisioning profile for this App ID
5. Download and install the new profile
6. Update your Xcode project to use this new profile

### Option 3: Temporarily Disable MusicKit (Quick Workaround)

If you need to build and test other features while resolving the provisioning issues:

1. Comment out the MusicKit entitlement in `Sources/MusicDashboard.entitlements`:

```xml
<!-- <key>com.apple.developer.musickit</key>
<true/> -->
```

2. Build and run the app - it will use mock data for music features

## Detailed Steps for Option 1 (Recommended)

### 1. Update Bundle ID in project.yml

Edit the project.yml file and change the bundle ID for the MusicDashboard target:

```bash
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER: com.musicdashboard.app/PRODUCT_BUNDLE_IDENTIFIER: com.musicdashboard.MusicDashboard/' project.yml
```

### 2. Regenerate Xcode Project

If you have XcodeGen installed:

```bash
xcodegen generate
```

If not, install it first:

```bash
brew install xcodegen
xcodegen generate
```

### 3. Update App ID in Apple Developer Portal

1. Go to [Identifiers section](https://developer.apple.com/account/resources/identifiers/list)
2. Select your App ID (`com.musicdashboard.MusicDashboard`)
3. Scroll down to "App Services" section
4. Check the box for "MusicKit"
5. Click "Save"

### 4. Regenerate Provisioning Profile

1. Go to [Profiles section](https://developer.apple.com/account/resources/profiles/list)
2. Find your profile for `com.musicdashboard.MusicDashboard`
3. Click "Edit"
4. Click "Generate"
5. Download the new profile
6. Double-click to install it (or use the install-provisioning-profile.sh script)

### 5. Clean and Rebuild

1. Open your project in Xcode
2. Select Product > Clean Build Folder
3. Build and run the app

## Checking Provisioning Profile Status

To verify your provisioning profile has the correct entitlements:

```bash
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/your_profile.mobileprovision
```

Look for the `Entitlements` dictionary in the output and check for:

```xml
<key>com.apple.developer.musickit</key>
<true/>
```

## Additional Resources

- [Apple Developer Documentation: Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Apple Developer Documentation: Provisioning Profiles](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)
- [MusicKit Documentation](https://developer.apple.com/documentation/musickit)
