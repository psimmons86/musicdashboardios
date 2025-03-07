#!/bin/bash

# Script to help regenerate and install a provisioning profile with MusicKit entitlement
# Created by Cline on March 6, 2025

echo "===== MusicKit Provisioning Profile Helper ====="
echo ""
echo "This script will help you regenerate and install a provisioning profile"
echo "with the MusicKit entitlement for your Music Dashboard app."
echo ""
echo "IMPORTANT: Before running this script, make sure you have:"
echo "1. Enabled MusicKit in the Apple Developer Portal for your App ID"
echo "2. Generated a new provisioning profile"
echo "3. Downloaded the new profile to your Downloads folder"
echo ""

# Ask for the filename of the downloaded provisioning profile
read -p "Enter the filename of your downloaded provisioning profile (e.g., New_Music_Dashboard.mobileprovision): " PROFILE_FILENAME

# Check if the file exists
if [ ! -f "$HOME/Downloads/$PROFILE_FILENAME" ]; then
    echo "Error: File not found at $HOME/Downloads/$PROFILE_FILENAME"
    echo "Please make sure you've downloaded the provisioning profile and entered the correct filename."
    exit 1
fi

# Create the Provisioning Profiles directory if it doesn't exist
if [ ! -d "$HOME/Library/MobileDevice/Provisioning Profiles" ]; then
    echo "Creating Provisioning Profiles directory..."
    mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
fi

# Generate a unique filename based on UUID
UUID=$(uuidgen)
DEST_FILENAME="$UUID.mobileprovision"

# Copy the provisioning profile to the Provisioning Profiles directory
echo "Installing provisioning profile..."
cp "$HOME/Downloads/$PROFILE_FILENAME" "$HOME/Library/MobileDevice/Provisioning Profiles/$DEST_FILENAME"

# Check if the copy was successful
if [ -f "$HOME/Library/MobileDevice/Provisioning Profiles/$DEST_FILENAME" ]; then
    echo "Success! Provisioning profile installed at: $HOME/Library/MobileDevice/Provisioning Profiles/$DEST_FILENAME"
else
    echo "Error: Failed to install provisioning profile."
    exit 1
fi

# Check if the profile contains the MusicKit entitlement
echo "Checking for MusicKit entitlement..."
if security cms -D -i "$HOME/Library/MobileDevice/Provisioning Profiles/$DEST_FILENAME" | grep -q "com.apple.developer.musickit"; then
    echo "✅ MusicKit entitlement found in the provisioning profile!"
else
    echo "❌ MusicKit entitlement NOT found in the provisioning profile."
    echo "Please make sure you've enabled MusicKit in the Apple Developer Portal for your App ID."
    echo "Then regenerate your provisioning profile and try again."
fi

echo ""
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Clean the build folder (Product > Clean Build Folder)"
echo "3. Build and run your app"
echo ""
echo "If you still encounter issues, try restarting Xcode."
