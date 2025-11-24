# Image analysis as a service

We built an image analysis lab with text recognigiton. Now I would like to wrap functionality do I can easily use it in another SwiftUI project.

What our service / library should provide:

* The API allows me to set an image
* Then I can access the recognized texts including their confidence and Priority
* I can get the image including the overlays data, so I can use it on macOS as well as iPhone / iPad
* It should asynchronously with await, so it doesn't block the UI
* It should use the most up-to-date Apple observation framework.

---

## Architecture: @Observable Service Class

### Overview

We'll create a reusable `ImageAnalysisService` using the @Observable macro (iOS 17+) that wraps the existing Vision analysis functionality into a clean, easy-to-use API. This approach balances simplicity with reusability.

### Current Architecture Review

The existing Vision module has these key components that we'll reorganize:

**Services Layer:**
- `VisionAnalyzer.swift` - Core Vision framework wrapper (text, faces, objects, barcodes, saliency)
- `FontSizeAnalyzer.swift` - Calculates text importance/priority based on size
- `ImagePreprocessor.swift` - Image preparation and optimization

**Models Layer:**
- `ImageFeatures.swift` - Result containers (TextFeature, FaceFeature, ObjectFeature, etc.)
- `PlatformImage.swift` - Cross-platform UIImage/NSImage abstraction

**Views Layer:**
- `ImageOverlayView.swift` - Canvas-based bounding box rendering (cross-platform)

### New Structure

```
Foundation Lab/
└── Services/
    └── ImageAnalysis/
        ├── ImageAnalysisService.swift (@Observable)
        ├── Models/
        │   ├── AnalyzedImage.swift
        │   ├── TextRecognitionResult.swift
        │   └── PlatformImage.swift (moved from Vision/Models)
        ├── Internal/
        │   ├── VisionAnalyzer.swift (refactored from Vision/Services)
        │   ├── FontSizeAnalyzer.swift (moved from Vision/Services)
        │   └── ImagePreprocessor.swift (moved from Vision/Services)
        └── Views/
            └── ImageOverlayView.swift (refactored from Vision/Views)
```

### Public API Design

#### 1. ImageAnalysisService (@Observable)

```swift
import Foundation
import Observation

@Observable
public final class ImageAnalysisService {
    // Public state properties
    public private(set) var analyzedImage: AnalyzedImage?
    public private(set) var isAnalyzing = false
    public private(set) var error: Error?

    public init() {}

    /// Analyzes an image and updates the analyzedImage property
    public func analyze(image: PlatformImage) async {
        // Analysis implementation
    }

    /// Clears the current analysis results
    public func clear() {
        analyzedImage = nil
        error = nil
    }
}
```

#### 2. AnalyzedImage (struct)

```swift
public struct AnalyzedImage {
    public let originalImage: PlatformImage
    public let textResults: [TextRecognitionResult]
    public let faceResults: [FaceRecognitionResult]
    public let objectResults: [ObjectRecognitionResult]
    public let imageSize: CGSize
}
```

#### 3. TextRecognitionResult (struct)

```swift
public struct TextRecognitionResult: Identifiable {
    public let id: UUID
    public let text: String
    public let confidence: Float  // 0.0-1.0
    public let priority: Int      // 1 = highest importance
    public let boundingBox: CGRect
    public let estimatedPointSize: CGFloat?

    public var confidencePercent: Int {
        Int(confidence * 100)
    }
}
```

#### 4. ImageOverlayView (SwiftUI View)

```swift
public struct ImageOverlayView: View {
    let analyzedImage: AnalyzedImage

    public init(analyzedImage: AnalyzedImage) {
        self.analyzedImage = analyzedImage
    }

    public var body: some View {
        // Canvas-based overlay rendering
    }
}
```

### Usage Example

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var service = ImageAnalysisService()

    var body: some View {
        VStack {
            // Image picker
            PhotosPicker(selection: $photoItem) {
                Text("Select Image")
            }

            // Analysis results
            if service.isAnalyzing {
                ProgressView("Analyzing...")
            } else if let analyzed = service.analyzedImage {
                // Display image with overlays
                ImageOverlayView(analyzedImage: analyzed)
                    .frame(height: 300)

                // Display text results
                List(analyzed.textResults) { result in
                    VStack(alignment: .leading) {
                        Text(result.text)
                            .font(.headline)
                        HStack {
                            Text("Priority: \(result.priority)")
                            Text("Confidence: \(result.confidencePercent)%")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await service.analyze(image: image)
                }
            }
        }
    }
}
```

### Key Design Decisions

**1. @Observable for Reactive State**
- Properties automatically observable without `@Published`
- SwiftUI views update only when accessed properties change
- More efficient than ObservableObject
- Use `@State` instead of `@StateObject` in views

**2. Async/Await for Analysis**
- Single async method: `analyze(image:) async`
- Updates service properties on completion
- Error handling via error property
- No completion handlers (modern Swift concurrency)

**3. Value-Type Results**
- `AnalyzedImage` is an immutable struct
- Contains all analysis data
- Nested result types (TextRecognitionResult, etc.)
- Safe to pass between contexts

**4. Cross-Platform Support**
- `PlatformImage` typealias (UIImage on iOS, NSImage on macOS)
- Conditional compilation in extensions
- Canvas-based overlay rendering works on both platforms
- Public API identical across iOS and macOS

**5. Internal Implementation**
- Reuse existing VisionAnalyzer, FontSizeAnalyzer
- Keep as internal (not public)
- Preprocessing handled internally
- Clean separation of concerns

### Apple Best Practices

**@Observable macro (iOS 17+):**
- Replaces `ObservableObject` with compile-time observation
- No `@Published` needed - properties automatically tracked
- More granular updates - only dependent views refresh
- Reference: [Apple Documentation - Observable](/documentation/observation/observable)

**Swift Concurrency:**
- `async/await` for non-blocking operations
- `@MainActor` isolation for UI updates
- Structured concurrency with Task
- SwiftUI `.task` modifier for lifecycle management

---

## How to Copy to Another Project

### Step 1: Copy the ImageAnalysis Folder

Copy the entire service module to your new project:

**From Foundation Lab:**
```
Foundation Lab/Services/ImageAnalysis/
```

**To Your Project:**
```
YourProject/Services/ImageAnalysis/
```

Or place it at your preferred location:
```
YourProject/ImageAnalysis/
```

### Step 2: Add Files to Xcode Project

1. Open your project in Xcode
2. Right-click your project navigator
3. Select "Add Files to YourProject..."
4. Navigate to the copied `ImageAnalysis` folder
5. Check "Copy items if needed"
6. Select "Create groups"
7. Add to your app target

**Files to add:**
- `ImageAnalysisService.swift`
- `Models/AnalyzedImage.swift`
- `Models/TextRecognitionResult.swift`
- `Models/FaceRecognitionResult.swift`
- `Models/ObjectRecognitionResult.swift`
- `Models/PlatformImage.swift`
- `Internal/VisionAnalyzer.swift`
- `Internal/FontSizeAnalyzer.swift`
- `Internal/ImagePreprocessor.swift`
- `Views/ImageOverlayView.swift`

### Step 3: Verify Framework Dependencies

Ensure your project links these frameworks (should be automatic):
- **Vision.framework** - Image analysis
- **SwiftUI** - UI components
- **CoreImage** - Image processing

### Step 4: Set Minimum Deployment Target

The service requires:
- **iOS 17.0+** or **macOS 14.0+** (for @Observable macro)

Update in Xcode:
1. Select your project
2. Go to "Build Settings"
3. Set "iOS Deployment Target" to 17.0 (or macOS 14.0)

### Step 5: Import and Use

```swift
// No import needed - part of your project
import SwiftUI

struct MyView: View {
    @State private var service = ImageAnalysisService()

    var body: some View {
        // Use the service
    }
}
```

### Step 6: Customize (Optional)

You can customize the service for your needs:

**Modify overlay colors** in `ImageOverlayView.swift`:
```swift
// Line ~134
context.stroke(path, with: .color(.blue), lineWidth: 3)  // Change color
```

**Adjust priority colors** in `ImageOverlayView.swift`:
```swift
// Lines 236-242
let badgeColor: Color = {
    switch priority {
    case 1: return .red      // Highest priority
    case 2: return .orange   // Medium priority
    case 3: return .blue     // Lower priority
    default: return .gray
    }
}()
```

**Filter analysis types** in `ImageAnalysisService.swift`:
```swift
// Only analyze text (skip faces, objects)
let results = try await analyzer.analyze(
    imagePath: preprocessedURL.path(),
    analysisTypes: [.text],  // Add/remove types as needed
    includeConfidence: true
)
```

### Step 7: Test Integration

Create a simple test view:

```swift
import SwiftUI
import PhotosUI

struct TestAnalysisView: View {
    @State private var service = ImageAnalysisService()
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack {
            PhotosPicker("Select Image", selection: $photoItem)

            if service.isAnalyzing {
                ProgressView()
            }

            if let analyzed = service.analyzedImage {
                ImageOverlayView(analyzedImage: analyzed)
                Text("Found \(analyzed.textResults.count) text items")
            }

            if let error = service.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await service.analyze(image: image)
                }
            }
        }
    }
}
```

### Files Reference

All files you need to copy are in:
```
Foundation Lab/Services/ImageAnalysis/
```

**Public API files** (main interface):
- `ImageAnalysisService.swift` - Main service class
- `Models/AnalyzedImage.swift` - Results container
- `Models/TextRecognitionResult.swift` - Text analysis results
- `Views/ImageOverlayView.swift` - Visualization component

**Internal files** (implementation details):
- `Internal/VisionAnalyzer.swift` - Vision framework wrapper
- `Internal/FontSizeAnalyzer.swift` - Priority calculation
- `Internal/ImagePreprocessor.swift` - Image preparation

**Platform support**:
- `Models/PlatformImage.swift` - iOS/macOS compatibility

### Troubleshooting

**Build Error: "Cannot find type 'PlatformImage'"**
- Make sure `PlatformImage.swift` is included
- Check it's added to your target

**Runtime Error: "Image analysis failed"**
- Verify Vision.framework is linked
- Check image data is valid
- Review console for specific Vision errors

**UI Not Updating**
- Ensure you're using `@State` (not `@StateObject`) with the service
- Verify iOS 17+ / macOS 14+ deployment target
- Check the service is marked `@Observable`

---

## Implementation Checklist

- [ ] Create `Services/ImageAnalysis/` folder structure
- [ ] Implement `ImageAnalysisService` with @Observable
- [ ] Create `AnalyzedImage` and result models
- [ ] Refactor `VisionAnalyzer` as internal service
- [ ] Move/adapt `FontSizeAnalyzer` and `ImagePreprocessor`
- [ ] Create public `ImageOverlayView`
- [ ] Update `PlatformImage` for public use
- [ ] Write example integration in app
- [ ] Test on both iOS and macOS (if applicable)
- [ ] Document public API with comments

---

## Next Steps

Ready to implement? I can:
1. Create the complete service implementation
2. Refactor existing code into the new structure
3. Build an example integration in the app
4. Add unit tests for the service