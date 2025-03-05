# CloudKit Dashboard Setup Guide

## 1. Access CloudKit Dashboard

1. Go to https://icloud.developer.apple.com/dashboard/
2. Sign in with your Apple Developer account
3. Select your container: iCloud.com.musicdashboard.stats

## 2. Create Track Record Type

1. In the left sidebar, click "Schema"
2. Click "Record Types" tab
3. Click "+ Record Type" (blue button in top-right)
4. Enter name: "Track"
5. Click "Create Record Type"
6. Under "Record Fields" section:
   - Click "+ Add Field" button
   - Enter field name (e.g., "id")
   - Choose type from dropdown
   - Click "Add Field" to save
   - Repeat for each field:
     * id (String)
     * title (String)
     * artist (String)
     * albumTitle (String)
     * artworkURL (String)
     * playCount (Int(64))
     * lastPlayed (Date/Time)

## 3. Create ListeningSession Record Type

1. Click back to Record Types list
2. Click "+ Record Type" again
3. Enter name: "ListeningSession"
4. Click "Create Record Type"
5. Under "Record Fields" section:
   - Click "+ Add Field" button
   - Add each field:
     * startTime (Date/Time)
     * duration (Int(64))
     * trackIds (String)

## Field Type Selection

When adding fields:
1. For String fields:
   - Choose "String" from type dropdown
   - Leave "Optional" unchecked
   - Click "Add Field"

2. For Number fields:
   - Choose "Int(64)" directly from type dropdown
   - Leave "Optional" unchecked
   - Click "Add Field"

3. For Date fields:
   - Choose "Date/Time" from type dropdown
   - Leave "Optional" unchecked
   - Click "Add Field"

## 4. Verify Setup

1. In Record Types tab, you should see both:
   - Track (7 fields)
   - ListeningSession (3 fields)

2. Click each to verify fields:
   - Check field names exactly match
   - Check field types are correct
   - Check nothing is marked optional

## Important Tips

1. Field Names:
   - Use exact names as shown (they match the code)
   - Use camelCase (e.g., "playCount" not "play_count")
   - Avoid spaces in field names
   - Case sensitive: "playCount" ≠ "PlayCount"

2. Field Types:
   - String: Use for text and IDs
   - Int(64): Use for all whole numbers
   - Date/Time: Use for timestamps
   - Don't use Optional types for now
   - Don't use List types yet

3. Common Issues:
   - If a field is missing, records won't save
   - Field names must match exactly
   - Wrong number type can cause silent failures

## Troubleshooting

If you can't access the dashboard:
1. Verify you're signed into your Apple Developer account
2. Verify your team has CloudKit enabled
3. Verify your container was created in Apple Developer portal first

## After Setup

1. Verify both record types appear in the list
2. Double-check all field names and types
3. Stay in Development environment for testing
4. No need to create any records manually - the app will do that

## Next Steps

After schema setup:
1. Return to Xcode/VS Code
2. Build and run the app
3. The app will create test records automatically
4. Check the dashboard to verify records are created
