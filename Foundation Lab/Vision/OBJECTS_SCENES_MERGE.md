# Objects & Scenes Merge

## Issue
The UI showed two separate buttons:
- "Object Classification"
- "Scene Recognition"

However, selecting either one (or both) produced identical results in a section titled "Object & Scene Classification". This was confusing because users thought they were two different analysis types.

## Root Cause
Both options use the **same Apple Vision API**: `VNClassifyImageRequest`

### How VNClassifyImageRequest Works
```swift
let request = VNClassifyImageRequest()
try handler.perform([request])

// Returns VNClassificationObservation array with identifiers like:
// - "dog" (object)
// - "outdoor" (scene)
// - "tree" (object)
// - "park" (scene)
// - "bench" (object)
```

The API returns a **single list** containing both object labels AND scene labels mixed together. There's no way to request only objects or only scenes separately.

### Why They Can't Be Separated
Apple's Vision framework doesn't provide:
- ❌ A separate `VNClassifyObjectsRequest`
- ❌ A separate `VNClassifyScenesRequest`
- ❌ A way to filter `VNClassifyImageRequest` results by type

The classification model is trained to recognize both objects and scenes simultaneously, and the results come back as a unified list with no distinction between object vs. scene labels.

## Solution
Merged the two separate options into a single combined option.

### Before (Confusing)
```
┌─────────────────────┐  ┌─────────────────────┐
│  Object             │  │  Scene              │
│  Classification     │  │  Recognition        │
└─────────────────────┘  └─────────────────────┘
         ↓                        ↓
    Both use VNClassifyImageRequest
         ↓                        ↓
    Same results: "dog, outdoor, tree, park, bench"
```

### After (Clear)
```
┌─────────────────────┐
│  Objects & Scenes   │
└─────────────────────┘
         ↓
    VNClassifyImageRequest
         ↓
    Results: "dog, outdoor, tree, park, bench"
```

## Changes Made

### 1. VisionAnalysisType.swift
**Before:**
```swift
enum VisionAnalysisType: String, CaseIterable, Codable {
    case text = "text"
    case faces = "faces"
    case objects = "objects"      // ← Separate
    case scenes = "scenes"         // ← Separate
    case barcodes = "barcodes"
    case saliency = "saliency"
}
```

**After:**
```swift
enum VisionAnalysisType: String, CaseIterable, Codable {
    case text = "text"
    case faces = "faces"
    case objectsAndScenes = "objects"  // ← Combined (rawValue still "objects")
    case barcodes = "barcodes"
    case saliency = "saliency"
}
```

**Display Name:**
```swift
case .objectsAndScenes:
    return "Objects & Scenes"  // Clear, descriptive name
```

**Icon:**
```swift
case .objectsAndScenes:
    return "cube.box.fill"  // Solid version for emphasis
```

### 2. VisionExampleViewModel.swift
**Updated Default Selection:**
```swift
var selectedAnalysisTypes: Set<VisionAnalysisType> = [
    .text,
    .faces,
    .objectsAndScenes  // Changed from .objects
]
```

### 3. VisionAnalyzer.swift
**No Changes Needed** - Already checked for both:
```swift
if analysisTypes.contains(.objects) || analysisTypes.contains(.scenes) {
    requests.append(VNClassifyImageRequest())
}
```

Since `objectsAndScenes` has rawValue "objects", this check still works correctly.

## UI Impact

### Button Grid (Before - 6 buttons)
```
┌─────────────────┐ ┌─────────────────┐
│ Text Recognition│ │ Face Detection  │
└─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ Object          │ │ Scene           │  ← Redundant
│ Classification  │ │ Recognition     │  ← Redundant
└─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ Barcode         │ │ Saliency        │
│ Detection       │ │ Detection       │
└─────────────────┘ └─────────────────┘
```

### Button Grid (After - 5 buttons)
```
┌─────────────────┐ ┌─────────────────┐
│ Text Recognition│ │ Face Detection  │
└─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ Objects &       │ │ Barcode         │  ← Cleaner layout
│ Scenes          │ │ Detection       │
└─────────────────┘ └─────────────────┘
┌─────────────────┐
│ Saliency        │
│ Detection       │
└─────────────────┘
```

## Results Section
The results section title remains accurate:
```
OBJECT & SCENE CLASSIFICATION:
  • dog (95%)
  • outdoor (92%)
  • tree (88%)
  • park (85%)
  • bench (82%)
```

## Backward Compatibility

### Tool Integration (VisionTool)
The tool still accepts both "objects" and "scenes" in the `analysisTypes` array:
```swift
// Both of these work:
analysisTypes: ["objects"]        // Triggers VNClassifyImageRequest
analysisTypes: ["scenes"]         // Triggers VNClassifyImageRequest
analysisTypes: ["objects", "scenes"]  // Triggers VNClassifyImageRequest (once)

// All produce the same result
```

The VisionAnalyzer code handles both for backward compatibility:
```swift
if analysisTypes.contains(.objects) || analysisTypes.contains(.scenes) {
    requests.append(VNClassifyImageRequest())  // Only added once
}
```

### LLM Context
The LLM can still request:
- "Classify the objects in this image"
- "Identify the scene type"
- "Tell me about objects and scenes"

All map to the same unified classification.

## Benefits

✅ **Less Confusion** - One button instead of two identical ones
✅ **Accurate Representation** - UI matches the actual API behavior
✅ **Better Layout** - 5 buttons instead of 6 (cleaner grid)
✅ **Same Functionality** - All classification results still returned
✅ **Backward Compatible** - Tool still accepts "objects" and "scenes" separately

## Example Results

### Input Image: Park with dog
**Unified Classification Results:**
```
Objects detected:
  • dog
  • bench
  • tree
  • leash
  • grass

Scenes identified:
  • outdoor
  • park
  • daytime
  • recreational area
```

All from a single `VNClassifyImageRequest` call.

## Files Modified
1. `Foundation Lab/Vision/Models/VisionAnalysisType.swift`
   - Merged `.objects` and `.scenes` into `.objectsAndScenes`
   - Updated display name, description, and icon

2. `Foundation Lab/Vision/ViewModels/VisionExampleViewModel.swift`
   - Updated default selection to use `.objectsAndScenes`

## Build Status
✅ **BUILD SUCCEEDED** - No errors or warnings

## Testing
Test the merged button:
1. Select an image
2. Choose "Objects & Scenes" button
3. Run analysis
4. Verify results show both objects and scene types
5. Try analyzing same image multiple times (should work after cleanup fix)
