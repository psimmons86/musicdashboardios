# Step-by-Step Guide: Adding MusicKit Entitlement to Your App ID

This guide provides detailed instructions with visual examples for adding the MusicKit entitlement to your App ID in the Apple Developer Portal.

## Step 1: Log in to the Apple Developer Portal

1. Go to [developer.apple.com](https://developer.apple.com)
2. Click "Account" in the top-right corner
3. Sign in with your Apple Developer account credentials

## Step 2: Navigate to Certificates, Identifiers & Profiles

1. Once logged in, click on "Certificates, Identifiers & Profiles" in the left sidebar
   
   ![Certificates, Identifiers & Profiles](https://developer.apple.com/assets/elements/icons/certificates/certificates-128x128.png)

## Step 3: Select Identifiers

1. In the left sidebar, click on "Identifiers" under the "Identifiers" section
   
   ![Identifiers Section](https://developer.apple.com/account/resources/identifiers/list)

## Step 4: Find Your App ID

1. You'll see a list of all your App IDs
2. Find the App ID for "com.musicdashboard.MusicDashboard"
3. Click on it to edit

## Step 5: Enable MusicKit Capability

1. Scroll down to the "App Services" or "Capabilities" section
2. Find "MusicKit" in the list of capabilities
   
   ![MusicKit Capability](https://developer.apple.com/musickit/images/musickit-icon.svg)

3. Check the box next to "MusicKit"
4. If there are any configuration options, fill them out as needed

## Step 6: Save Your Changes

1. Scroll to the bottom of the page
2. Click the "Save" or "Continue" button
3. Confirm any prompts that appear

## Step 7: Verify MusicKit is Enabled

1. After saving, you'll be returned to the App ID details page
2. Scroll down to the "App Services" or "Capabilities" section
3. Verify that "MusicKit" is now listed as "Enabled" or has a checkmark

## Visual Guide

Here's what the process looks like:

1. **Identifiers Page**:
   
   ![Identifiers Page](https://developer.apple.com/account/resources/identifiers/list)

2. **App ID Details**:
   
   You'll see your App ID details similar to this:
   
   ```
   Platform: iOS, iPadOS, macOS, tvOS, watchOS, visionOS
   App ID Prefix: 4Y39R5M676 (Team ID)
   Bundle ID: com.musicdashboard.MusicDashboard (explicit)
   ```

3. **Capabilities Section**:
   
   Scroll down to find the "Capabilities" or "App Services" section:
   
   ```
   [ ] Access WiFi Information
   [ ] App Groups
   [ ] Apple Pay
   ...
   [ ] Maps
   [ ] Multipath
   [ ] MusicKit  <-- Check this box
   ...
   ```

4. **Save Button**:
   
   At the bottom of the page:
   
   ```
   [Cancel]    [Save]
   ```

## Next Steps After Enabling MusicKit

After enabling MusicKit for your App ID, you need to:

1. Regenerate your provisioning profile
2. Download and install the new provisioning profile
3. Rebuild your app

These steps are covered in the `PROVISIONING_PROFILE_TROUBLESHOOTING.md` file.

## Troubleshooting

If you don't see MusicKit in the list of capabilities:

1. Make sure you're looking at the right App ID
2. Ensure your Apple Developer Program membership is active
3. Try refreshing the page or logging out and back in
4. Contact Apple Developer Support if the issue persists
