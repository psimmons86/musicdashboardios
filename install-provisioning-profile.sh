#!/bin/bash

# This script installs the provisioning profile from the Downloads folder to the Xcode provisioning profiles directory

# Define paths
DOWNLOADS_DIR="$HOME/Downloads"
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
PROFILE_FILENAME="Music_Dashboard.mobileprovision"

# Create Provisioning Profiles directory if it doesn't exist
if [ ! -d "$PROFILES_DIR" ]; then
    echo "Creating Provisioning Profiles directory..."
    mkdir -p "$PROFILES_DIR"
fi

# Check if the provisioning profile exists in Downloads
if [ ! -f "$DOWNLOADS_DIR/$PROFILE_FILENAME" ]; then
    echo "Error: Provisioning profile file not found in Downloads folder."
    echo "Expected path: $DOWNLOADS_DIR/$PROFILE_FILENAME"
    exit 1
fi

# Copy the provisioning profile to the Provisioning Profiles directory
echo "Copying provisioning profile to Xcode's Provisioning Profiles directory..."
cp "$DOWNLOADS_DIR/$PROFILE_FILENAME" "$PROFILES_DIR/"

# Check if the copy was successful
if [ -f "$PROFILES_DIR/$PROFILE_FILENAME" ]; then
    echo "Success! Provisioning profile installed at: $PROFILES_DIR/$PROFILE_FILENAME"
    echo "You may need to restart Xcode for the changes to take effect."
else
    echo "Error: Failed to copy provisioning profile."
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Go to the Signing & Capabilities tab"
echo "3. Make sure the correct provisioning profile is selected"
echo "4. Clean and rebuild your project"

echo ""
echo "Done!"
