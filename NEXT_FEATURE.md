# Image Recognition Tool

## Overview
Build a tool that integrates Apple's Vision framework with Foundation Models to provide AI-powered image analysis capabilities. The tool will identify text, people/faces, objects, and other visual features in images.

## Core Capabilities

### 1. Text Recognition (OCR)
- Extract text from images using `VNRecognizeTextRequest`
- Support for multiple languages
- Confidence scoring for extracted text
- Return structured text with bounding boxes

### 2. Face Detection & Analysis
- Detect face bounding boxes using `VNDetectFaceRectanglesRequest`
- Extract face landmarks (eyes, nose, mouth) using `VNDetectFaceLandmarksRequest`
- Face quality analysis using `VNDetectFaceCaptureQualityRequest`
- Note: Age/gender/emotion estimation not available in Vision framework

### 3. Object & Scene Classification
- Classify objects using `VNClassifyImageRequest`
- Scene recognition (indoor/outdoor, location type)
- Confidence scores for classifications
- Support for custom CoreML models

### 4. Image Features
- Saliency detection using `VNGenerateAttentionBasedSaliencyImageRequest`
- Barcode/QR code detection using `VNDetectBarcodesRequest`
- Horizon detection
- Image aesthetics analysis

## Architecture

### Tool Structure
```
Foundation Lab/Vision/
├── Tools/
│   └── VisionTool.swift (main Tool protocol implementation)
├── Services/
│   ├── VisionAnalyzer.swift (Vision framework wrapper)
│   └── ImagePreprocessor.swift (image resizing/optimization)
├── Models/
│   ├── VisionAnalysisResult.swift (@Generable for AI responses)
│   ├── VisionAnalysisType.swift (enum for analysis types)
│   └── ImageFeatures.swift (result data structures)
├── ViewModels/
│   └── VisionExampleViewModel.swift (@Observable ViewModel)
└── Views/
    ├── VisionExampleView.swift (main demo interface)
    └── Components/
        ├── ImagePickerView.swift (image selection)
        ├── AnalysisResultView.swift (results display)
        └── ImageOverlayView.swift (bounding boxes overlay)
```

### Tool Protocol Implementation
**Name**: `vision_analyze_image`

**Description**: "Analyzes images using Apple Vision framework to extract text, detect faces, classify objects, and identify visual features"

**Input Schema**:
```swift
@Generable
struct Arguments {
    @Guide(description: "File path or URL to the image to analyze")
    var imagePath: String

    @Guide(description: "Types of analysis to perform: text, faces, objects, scenes, barcodes")
    var analysisTypes: [String]

    @Guide(description: "Whether to include confidence scores in results")
    var includeConfidence: Bool?
}
```

**Output**: Formatted text response that the LLM can interpret and present to users (not JSON strings)

### Integration Points

1. **Chat Integration**: Add to ChatViewModel's available tools
2. **Voice Integration**: "Analyze this image" voice command
3. **Health Integration**: Analyze food photos for nutritional coaching
4. **Examples Tab**: Standalone demo showing all capabilities

## User Experience

### Example Use Cases
- "What does this sign say?" (OCR)
- "How many people are in this photo?" (Face detection)
- "What objects do you see?" (Object classification)
- "Read the text from this receipt" (OCR + structured extraction)
- "Analyze this food photo" (Health coaching context)

### UI Components
- Image picker (Photos library or camera)
- Preview with analysis overlay (bounding boxes)
- Results panel with extracted information
- Confidence visualization

## Implementation Steps

### Phase 1: Core Vision Analysis & Services
1. Create `Services/VisionAnalyzer.swift` service class
2. Create `Services/ImagePreprocessor.swift` for image resizing/optimization
3. Implement text recognition using `VNRecognizeTextRequest`
4. Implement face detection using `VNDetectFaceRectanglesRequest`
5. Implement face landmarks using `VNDetectFaceLandmarksRequest`
6. Implement object classification using `VNClassifyImageRequest`
7. Implement barcode detection using `VNDetectBarcodesRequest`
8. Implement saliency detection using `VNGenerateAttentionBasedSaliencyImageRequest`
9. Add error handling for Vision framework errors (invalid image, unsupported format, request failures)
10. Add memory management for large images

### Phase 2: Tool Implementation
1. Create `Tools/VisionTool.swift` conforming to Tool protocol
2. Define `@Generable Arguments` struct with `@Guide` descriptions
3. Implement file path-based image handling (not base64)
4. Add formatted text response generation for LLM consumption
5. Integrate with VisionAnalyzer service
6. Handle temporary file cleanup

### Phase 3: Models & Data Structures
1. Create `Models/VisionAnalysisResult.swift` (@Generable for AI responses)
2. Create `Models/VisionAnalysisType.swift` (enum: .text, .faces, .objects, .scenes, .barcodes, .saliency)
3. Create `Models/ImageFeatures.swift` (data structures for results)
4. Add confidence scoring utilities
5. Implement result aggregation logic

### Phase 4: UI Development
1. Create `ViewModels/VisionExampleViewModel.swift` using @Observable macro
2. Create `Views/VisionExampleView.swift` for Examples tab
3. Create `Views/Components/ImagePickerView.swift` for image selection
4. Create `Views/Components/AnalysisResultView.swift` for displaying results
5. Create `Views/Components/ImageOverlayView.swift` for bounding boxes overlay
6. Add confidence score visualization
7. Integrate ViewModel with View using @State (not @StateObject)

### Phase 5: Integration
1. Register VisionTool in ChatViewModel's available tools
2. Add VisionExampleView to Examples tab navigation
3. Optional: Add to Voice interface commands
4. Optional: Create Health integration for food analysis
5. Add localization strings to Localizable.xcstrings
6. Update Info.plist with privacy descriptions:
   - NSPhotoLibraryUsageDescription
   - NSCameraUsageDescription

### Phase 6: Testing & Polish
1. Test with various image types
2. Handle edge cases (no faces, no text, etc.)
3. Optimize performance for large images
4. Add accessibility features

## Technical Considerations

### Privacy & Permissions
- Vision framework analysis requires no permissions (operates on image data)
- UI components require Info.plist entries:
  - `NSPhotoLibraryUsageDescription`: "Foundation Lab needs access to analyze images with on-device AI"
  - `NSCameraUsageDescription`: "Foundation Lab needs camera access to capture and analyze images"
- All analysis happens on-device (no network calls)
- Images passed to tool via file paths, not base64 encoding

### Performance
- Image preprocessing via `ImagePreprocessor` service:
  - Resize images larger than 4096px to prevent memory issues
  - Use CoreImage or vImage for efficient resizing
- Asynchronous Vision requests using `VNImageRequestHandler.perform()`
- Batch multiple analysis types in single handler when possible
- Consider image quality vs. speed tradeoffs based on use case

### Error Handling
- Invalid image data or file path
- Unsupported image formats (return user-friendly error message)
- Vision framework errors (VNRequest errors, NSError handling)
- Memory constraints with large images (catch and handle gracefully)
- Missing file at path
- File I/O errors when reading image data

### Compatibility
- iOS 26.0+ (matches app minimum)
- macOS 26.0+ (Vision framework available on both)
- Apple Silicon recommended for performance

## API Design

### VisionTool Interface
```swift
// Tool is called from LLM with:
// - Image file path (saved to temp location by UI)
// - Analysis types to perform
// - Optional confidence flag

// Example implementation:
struct VisionTool: Tool {
    let name = "vision_analyze_image"
    let description = "Analyzes images using Apple Vision framework..."

    @Generable
    struct Arguments {
        @Guide(description: "File path or URL to the image to analyze")
        var imagePath: String

        @Guide(description: "Types of analysis: text, faces, objects, scenes, barcodes")
        var analysisTypes: [String]

        @Guide(description: "Whether to include confidence scores")
        var includeConfidence: Bool?
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        // Analyze image using VisionAnalyzer service
        // Return formatted text response (not JSON)
        return "Image Analysis Results:\n\nText found: ...\nDetected 2 faces\nObjects: dog (95% confidence), tree (88%)"
    }
}
```

### Example LLM Interaction
```
User: "What's in this image?" [selects photo from library]
UI: Saves image to temporary file, passes path to chat
LLM: [calls vision_analyze_image with file path and analysis types]
Tool: [analyzes image, returns formatted text]
Tool Response: "Image Analysis Results:
  Text found: 'Welcome to the Park'
  Detected 2 faces
  Objects: dog (95% confidence), bench (82% confidence), tree (88% confidence)
  Scene: outdoor (92% confidence)"
LLM: "I can see 2 people in an outdoor setting. There's a dog in the foreground,
      and I can read text on a sign that says 'Welcome to the Park'."
```

## Future Enhancements
- Custom CoreML model support
- Image comparison ("are these the same person?")
- Video frame analysis
- Live camera feed analysis
- Integration with Photos app memories
- Accessibility descriptions for visually impaired users

## Key Architectural Decisions

### Directory Structure
- **Pattern**: Self-contained feature module following Health module pattern
- **Location**: `Foundation Lab/Vision/` with Tools/, Services/, Models/, ViewModels/, Views/
- **Rationale**: Keeps all Vision-related code organized and maintainable

### Image Data Handling
- **Decision**: Use file paths instead of base64 encoding
- **Rationale**: Foundation Models tools work better with file references; avoids encoding overhead
- **Implementation**: UI saves selected images to temp directory, passes file path to tool

### Tool Return Format
- **Decision**: Return formatted text strings, not JSON in properties
- **Rationale**: Follows established pattern from VoiceRemindersTool and HealthDataTool
- **Example**: `"Image Analysis Results:\n\nText found: ...\nDetected 2 faces"`

### Vision Framework APIs
- **Corrected Capabilities**:
  - Face detection: Bounding boxes + landmarks (separate requests)
  - NO age/gender/emotion estimation (not available in Vision framework)
  - Barcode detection with `VNDetectBarcodesRequest`
  - Saliency with `VNGenerateAttentionBasedSaliencyImageRequest`

### SwiftUI Best Practices
- **Observable Macro**: ViewModels use `@Observable` (not `ObservableObject`)
- **State Management**: Views use `@State` (not `@StateObject`)
- **Components Organization**: Subviews in `Views/Components/` subfolder

### Services Layer
- **VisionAnalyzer**: Wraps Vision framework requests
- **ImagePreprocessor**: Handles image resizing (4096px max) and optimization
- **Rationale**: Separates framework integration from business logic, following Voice module pattern