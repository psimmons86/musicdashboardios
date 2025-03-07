# Step-by-Step Guide: Regenerating and Installing Your Provisioning Profile

After enabling the MusicKit entitlement for your App ID, you need to regenerate your provisioning profile to include this new entitlement. This guide walks you through the process.

## Step 1: Navigate to Provisioning Profiles in Apple Developer Portal

1. Log in to [developer.apple.com](https://developer.apple.com)
2. Click on "Certificates, Identifiers & Profiles" in the left sidebar
3. In the left sidebar, under "Provisioning Profiles", click on "Profiles"

## Step 2: Find Your Existing Provisioning Profile

1. You'll see a list of all your provisioning profiles
2. Find the profile associated with your app (com.musicdashboard.MusicDashboard)
   - It might be named something like "iOS Team Provisioning Profile: com.musicdashboard.MusicDashboard"
   - Or "Music Dashboard"

## Step 3: Regenerate the Provisioning Profile

1. Click on the profile to view its details
2. Click the "Edit" button at the top-right of the page
3. You don't need to change any settings - the new MusicKit entitlement will be automatically included
4. Click "Generate" at the bottom of the page

## Step 4: Download the New Provisioning Profile

1. After generation completes, you'll be prompted to download the new profile
2. Click the "Download" button
3. The file will be saved to your Downloads folder with a .mobileprovision extension
   - For example: `Music_Dashboard.mobileprovision`

## Step 5: Install the Provisioning Profile

### Option A: Manual Installation

1. Locate the downloaded .mobileprovision file in your Downloads folder
2. Double-click the file to install it
3. Xcode will automatically install the profile in the correct location

### Option B: Using the Provided Script

We've already created a script to help you install the provisioning profile:

1. Move the downloaded .mobileprovision file to your Downloads folder (if it's not already there)
2. Rename it to `Music_Dashboard.mobileprovision` if it has a different name
3. Open Terminal
4. Navigate to your project directory:
   ```bash
   cd /Users/admin/code/firebaseappversions/musicdashboard
   ```
5. Run the installation script:
   ```bash
   ./install-provisioning-profile.sh
   ```
6. The script will copy the provisioning profile to the correct location

## Step 6: Verify Installation

To verify that the provisioning profile was installed correctly:

1. Open Terminal
2. Run the following command to list all installed provisioning profiles:
   ```bash
   ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
   ```
3. You should see your newly installed profile in the list

## Step 7: Check Entitlements in the Provisioning Profile

To verify that the MusicKit entitlement is included in your provisioning profile:

1. Open Terminal
2. Run the following command (replace PROFILE_NAME with your actual profile filename):
   ```bash
   security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/PROFILE_NAME.mobileprovision | grep -A 10 Entitlements
   ```
3. Look for the MusicKit entitlement in the output:
   ```xml
   <key>com.apple.developer.musickit</key>
   <true/>
   ```

## Step 8: Clean and Rebuild Your Project

1. Open your project in Xcode
2. Select Product > Clean Build Folder
3. Build and run your app

## Troubleshooting

### Profile Not Showing Up in Xcode

If your new provisioning profile isn't showing up in Xcode:

1. Restart Xcode
2. In Xcode, go to Xcode > Preferences > Accounts
3. Select your Apple ID
4. Click "Download Manual Profiles" or "Refresh"

### Wrong Profile Being Used

If Xcode is using the wrong provisioning profile:

1. In Xcode, select your project in the Project Navigator
2. Select your app target
3. Go to the "Signing & Capabilities" tab
4. If using automatic signing, toggle it off and on again
5. If using manual signing, select the correct provisioning profile from the dropdown

### Build Errors

If you still get build errors related to entitlements:

1. Make sure the bundle ID in your project.yml file matches exactly with the one in your provisioning profile
2. Verify that the MusicKit entitlement is enabled in both your App ID and entitlements file
3. Try deleting derived data: Xcode > Preferences > Locations > Derived Data > Click arrow > Delete
