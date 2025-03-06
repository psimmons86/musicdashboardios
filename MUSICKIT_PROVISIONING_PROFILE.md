# Updating Provisioning Profile for MusicKit

You're seeing the error:

```
Provisioning profile "iOS Team Provisioning Profile: com.musicdashboard.MusicDashboard" doesn't include the com.apple.developer.musickit entitlement.
```

This is because we added the MusicKit entitlement to your app's entitlements file, but your provisioning profile doesn't include this entitlement. Here's how to fix it:

## Option 1: Update Provisioning Profile in Apple Developer Portal

1. Go to the [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list)
2. Sign in with your Apple Developer account
3. Navigate to "Certificates, Identifiers & Profiles"
4. Select "Identifiers" from the sidebar
5. Find and select your app identifier (com.musicdashboard.MusicDashboard)
6. Scroll down to the "App Services" section
7. Check the box for "MusicKit"
8. Click "Save"
9. Go back to "Profiles" in the sidebar
10. Find your provisioning profile for this app
11. Click the "Edit" button
12. Click "Generate" to regenerate the profile with the new entitlement
13. Download the new provisioning profile
14. Double-click the downloaded file to install it in Xcode

## Option 2: Use Automatic Signing in Xcode

If you're using automatic signing in Xcode, you can try this simpler approach:

1. Open your project in Xcode
2. Select your project in the Project Navigator
3. Select your app target
4. Go to the "Signing & Capabilities" tab
5. Make sure "Automatically manage signing" is checked
6. Click the "+" button in the Capabilities section
7. Search for "MusicKit" and add it
8. Xcode should automatically update your provisioning profile

## Option 3: Temporarily Disable MusicKit for Testing

If you want to test other aspects of the app without MusicKit for now:

1. Open Sources/MusicDashboard.entitlements
2. Comment out or remove the MusicKit entitlement:
   ```xml
   <!-- <key>com.apple.developer.musickit</key>
   <true/> -->
   ```
3. Update the AppleMusicService.swift to handle the case when MusicKit is not available

## Next Steps

After updating your provisioning profile, try building and running the app again. The MusicKit entitlement should now be included in your provisioning profile, and the error should be resolved.

If you continue to have issues, you may need to:

1. Clean your build folder (Product > Clean Build Folder in Xcode)
2. Restart Xcode
3. Delete the app from your device/simulator before installing again
