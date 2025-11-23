# Info.plist Requirements for Vision Feature

The Vision feature requires the following privacy descriptions to be added to the app's Info.plist:

## Required Keys

### NSPhotoLibraryUsageDescription
**Value:** "Foundation Lab needs access to analyze images with on-device AI"

**Purpose:** Required when users select photos from their Photo Library using PhotosPicker.

### NSCameraUsageDescription
**Value:** "Foundation Lab needs camera access to capture and analyze images"

**Purpose:** Required if camera capture functionality is added in the future.

## How to Add (Xcode 26.0+)

1. Open FoundationLab.xcodeproj in Xcode
2. Select the "Foundation Lab" target
3. Go to the "Info" tab
4. Click "+" to add a new key
5. Add each key with its corresponding value

## Alternative: Info.plist File

If the project uses a separate Info.plist file, add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Foundation Lab needs access to analyze images with on-device AI</string>
<key>NSCameraUsageDescription</key>
<string>Foundation Lab needs camera access to capture and analyze images</string>
```

## Note

These descriptions are shown to users when the app requests permissions. The Vision framework itself does not require permissions - these are only needed for UI components (PhotosPicker, Camera).
