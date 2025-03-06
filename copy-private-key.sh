#!/bin/bash

# This script copies the Apple Music private key from the Downloads folder to the project

# Define paths
DOWNLOADS_DIR="$HOME/Downloads"
PROJECT_DIR="$(pwd)"
RESOURCES_DIR="$PROJECT_DIR/Resources"
KEY_FILENAME="AuthKey_97K5H5UANT.p8"

# Create Resources directory if it doesn't exist
if [ ! -d "$RESOURCES_DIR" ]; then
    echo "Creating Resources directory..."
    mkdir -p "$RESOURCES_DIR"
fi

# Check if the key file exists in Downloads
if [ ! -f "$DOWNLOADS_DIR/$KEY_FILENAME" ]; then
    echo "Error: Private key file not found in Downloads folder."
    echo "Expected path: $DOWNLOADS_DIR/$KEY_FILENAME"
    exit 1
fi

# Copy the key file to the Resources directory
echo "Copying private key file to Resources directory..."
cp "$DOWNLOADS_DIR/$KEY_FILENAME" "$RESOURCES_DIR/"

# Check if the copy was successful
if [ -f "$RESOURCES_DIR/$KEY_FILENAME" ]; then
    echo "Success! Private key file copied to: $RESOURCES_DIR/$KEY_FILENAME"
    echo "You may need to add this file to your Xcode project."
else
    echo "Error: Failed to copy private key file."
    exit 1
fi

# Update the AppleMusicService.swift file to load the key from the Resources directory
echo "To load the key from the Resources directory, update the loadPrivateKey() method in AppleMusicService.swift:"
echo ""
echo "private func loadPrivateKey() {"
echo "    if let keyPath = Bundle.main.path(forResource: \"AuthKey_97K5H5UANT\", ofType: \"p8\") {"
echo "        do {"
echo "            let keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))"
echo "            // Rest of the method remains the same"
echo "        } catch {"
echo "            print(\"Error loading private key: \(error)\")"
echo "        }"
echo "    } else {"
echo "        print(\"Private key file not found in app bundle\")"
echo "    }"
echo "}"

echo ""
echo "Done!"
