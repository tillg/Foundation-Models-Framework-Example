# Temporary File Cleanup Fix

## Problem
After running an image analysis once, subsequent analyses on the same image would fail with "Analysis failed: Invalid image data". The issue occurred because the original image file was being deleted after the first analysis.

## Root Cause

### The Problem Flow
1. User selects image from Photo Library
2. Image is saved to temporary directory: `/var/mobile/.../temp123.jpg`
3. `selectedImageURL` stores this temp file path
4. First analysis runs successfully
5. **Cleanup deletes the temp file** ❌
6. Second analysis tries to read from `selectedImageURL`
7. File no longer exists → "Invalid image data" error

### Why It Happened
The code was blindly cleaning up any temp file after analysis, without distinguishing between:
- The **original selected image** (should be kept for re-analysis)
- A **resized copy** created during preprocessing (should be deleted)

## Solution Applied

### Logic Change
Only delete temp files that were **created during preprocessing** (resized images), not the original selected image file.

### Implementation

#### 1. VisionExampleViewModel.swift (Example UI)
**Before:**
```swift
// Clean up temp file if created
preprocessor.cleanupTemporaryFile(at: preprocessedURL)
```

**After:**
```swift
// Clean up temp file ONLY if it's different from the original
// (preprocessor created a resized version)
if preprocessedURL != imageURL {
    preprocessor.cleanupTemporaryFile(at: preprocessedURL)
}
```

#### 2. VisionTool.swift (Chat Integration)
**Before:**
```swift
// Clean up temp file if it was created
preprocessor.cleanupTemporaryFile(at: preprocessedURL)
```

**After:**
```swift
// Convert input path to URL for comparison
let originalURL = /* URL from arguments.imagePath */

// Only cleanup if preprocessing created a NEW file
if preprocessedURL != originalURL {
    preprocessor.cleanupTemporaryFile(at: preprocessedURL)
}
```

Also fixed deprecated `.path` property to `.path()` method.

## How Preprocessing Works

The `ImagePreprocessor.preprocess()` method has two possible outcomes:

### Case 1: Image Is Small Enough (≤4096px)
```swift
if maxCurrentDimension <= Self.maxDimension {
    // No preprocessing needed
    return sourceURL  // Returns SAME URL
}
```
**Result:** `preprocessedURL == originalURL` → No cleanup needed

### Case 2: Image Is Too Large (>4096px)
```swift
// Resize image
let resizedImage = try resizeImage(ciImage, to: newSize)

// Save to NEW temporary file
let tempURL = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
    .appendingPathExtension("jpg")

try saveImage(resizedImage, to: tempURL)
return tempURL  // Returns NEW URL
```
**Result:** `preprocessedURL != originalURL` → Cleanup the resized copy

## When Cleanup Happens

### Selected Image File (Kept)
- Created when user picks from Photo Library
- Stored at: `/var/mobile/Containers/.../tmp/[UUID].jpg`
- Referenced by: `selectedImageURL` in ViewModel
- **Kept until**: User clears image or selects a new one

### Resized Image File (Deleted)
- Created only for images >4096px
- Stored at: `/var/mobile/Containers/.../tmp/[UUID].jpg` (different UUID)
- Used for: Single analysis operation
- **Deleted after**: Analysis completes (success or error)

## Cleanup Locations

### 1. After Successful Analysis
```swift
if preprocessedURL != imageURL {
    preprocessor.cleanupTemporaryFile(at: preprocessedURL)
}
```

### 2. After Analysis Error
```swift
catch {
    if preprocessedURL != originalURL {
        preprocessor.cleanupTemporaryFile(at: preprocessedURL)
    }
    return error
}
```

### 3. When User Clears Image
```swift
func clearImage() {
    if let url = selectedImageURL {
        preprocessor.cleanupTemporaryFile(at: url)  // NOW delete original
    }
    selectedImage = nil
    selectedImageURL = nil
}
```

## Benefits of This Fix

✅ **Multiple analyses work** - Same image can be analyzed repeatedly
✅ **Memory efficient** - Resized copies are still cleaned up
✅ **No file leaks** - Original is cleaned when user clears/changes image
✅ **Works in both contexts** - Example UI and Chat tool

## Testing Scenarios

### Scenario 1: Multiple Analyses (Same Types)
1. Select image
2. Choose analysis types (text, faces, objects)
3. Click "Analyze Image" → ✅ Works
4. Click "Analyze Image" again → ✅ Works (previously failed)
5. Click "Analyze Image" again → ✅ Works

### Scenario 2: Multiple Analyses (Different Types)
1. Select image
2. Analyze with [text] → ✅ Works
3. Change to [faces, objects] → ✅ Works (previously failed)
4. Change to [barcodes] → ✅ Works

### Scenario 3: Large Image (Requires Resizing)
1. Select 6000x4000px image
2. First analysis → Creates resized copy → Analyzes → Deletes resized copy → ✅ Works
3. Second analysis → Creates NEW resized copy → Analyzes → Deletes NEW copy → ✅ Works
4. Original image preserved for re-analysis

### Scenario 4: Chat Integration
1. Use chat: "Analyze this image: /path/to/image.jpg"
2. VisionTool analyzes → ✅ Works
3. Use chat again: "Analyze it again with faces only"
4. VisionTool analyzes same image → ✅ Works (previously failed)

## Files Modified
1. `Foundation Lab/Vision/ViewModels/VisionExampleViewModel.swift`
   - Line 121-123: Added URL comparison before cleanup

2. `Foundation Lab/Vision/Tools/VisionTool.swift`
   - Line 48-61: Added originalURL tracking
   - Line 72: Changed `.path` to `.path()`
   - Line 78-80: Conditional cleanup on error
   - Line 85-87: Conditional cleanup on success

## Build Status
✅ **BUILD SUCCEEDED** - No errors or warnings

## Additional Fix
Also updated deprecated `.path` property to modern `.path()` method throughout the codebase for consistency with latest Swift/Foundation APIs.
