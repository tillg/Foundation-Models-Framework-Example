# Image Analysis Service - Copy to Another Project

A standalone Swift service for analyzing images using Apple's Vision framework. Copy it to any iOS or macOS project for instant text recognition, face detection, and object classification.

## What You Get

✅ **Text Recognition** with importance/priority scoring (P1, P2, P3...)
✅ **Face Detection** with landmarks and quality scores
✅ **Object Classification** with confidence levels
✅ **@Observable** integration for reactive SwiftUI
✅ **async/await** for non-blocking analysis
✅ **Cross-platform** - works on iOS and macOS
✅ **Visualization** - SwiftUI overlay view included

## Requirements

- iOS 17.0+ or macOS 14.0+
- Xcode 16.0+
- Swift 6.0+

## Installation

### Copy to Your Project

1. Copy the entire `ImageAnalysis` folder to your project:

   ```
   Foundation Lab/Services/ImageAnalysis/
   ```

2. In Xcode, right-click your project navigator and select "Add Files to [Your Project]..."

3. Navigate to the copied folder, select it, and ensure:
   - ✅ "Copy items if needed" is checked
   - ✅ "Create groups" is selected
   - ✅ Your app target is selected

4. The following files will be added:
   ```
   ImageAnalysis/
   ├── ImageAnalysisService.swift
   ├── Models/
   │   ├── AnalyzedImage.swift
   │   ├── TextRecognitionResult.swift
   │   ├── FaceRecognitionResult.swift
   │   ├── ObjectRecognitionResult.swift
   │   └── PlatformImage.swift
   ├── Internal/
   │   ├── VisionAnalyzer.swift
   │   ├── FontSizeAnalyzer.swift
   │   ├── ImagePreprocessor.swift
   │   └── InternalModels.swift
   └── Views/
       └── ImageOverlayView.swift
   ```

### Framework Dependencies

The service requires these frameworks (automatically linked):
- **Vision** - Image analysis
- **SwiftUI** - UI components
- **CoreImage** - Image processing
- **CoreGraphics** - Graphics primitives

### Set Deployment Target

Update your project's minimum deployment target:
1. Select your project in Xcode
2. Go to "General" or "Build Settings"
3. Set "iOS Deployment Target" to **17.0** (or "macOS Deployment Target" to **14.0**)

## Usage

### Basic Example

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var service = ImageAnalysisService()
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack {
            // Image picker
            PhotosPicker("Select Image", selection: $photoItem)
                .buttonStyle(.borderedProminent)

            // Analysis status
            if service.isAnalyzing {
                ProgressView("Analyzing image...")
            }

            // Display results
            if let analyzed = service.analyzedImage {
                // Show image with overlays
                ImageOverlayView(analyzedImage: analyzed)
                    .frame(height: 300)
                    .border(Color.gray.opacity(0.3))

                // Show text results
                List(analyzed.textResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.text)
                            .font(.headline)
                        HStack {
                            Text("Priority: \(result.priority)")
                            Spacer()
                            Text("Confidence: \(result.confidencePercent)%")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            // Error display
            if let error = service.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(.red)
                    .padding()
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

### API Reference

#### ImageAnalysisService

The main service class for analyzing images.

```swift
@Observable
public final class ImageAnalysisService {
    // Current analysis result
    public private(set) var analyzedImage: AnalyzedImage?

    // Analysis status
    public private(set) var isAnalyzing: Bool

    // Most recent error
    public private(set) var error: Error?

    public init()

    // Analyze an image
    public func analyze(image: PlatformImage) async

    // Clear results
    public func clear()
}
```

**Usage:**

```swift
@State private var service = ImageAnalysisService()

// Analyze an image
await service.analyze(image: myImage)

// Access results
if let results = service.analyzedImage {
    print("Found \(results.textResults.count) text items")
}

// Clear when done
service.clear()
```

#### AnalyzedImage

Container for all analysis results.

```swift
public struct AnalyzedImage {
    public let originalImage: PlatformImage
    public let textResults: [TextRecognitionResult]
    public let faceResults: [FaceRecognitionResult]
    public let objectResults: [ObjectRecognitionResult]
    public let imageSize: CGSize

    // Convenience properties
    public var hasResults: Bool
    public var totalResultCount: Int
    public var textResultsByPriority: [TextRecognitionResult]
}
```

#### TextRecognitionResult

Represents recognized text with importance metadata.

```swift
public struct TextRecognitionResult: Identifiable {
    public let id: UUID
    public let text: String                        // Recognized text
    public let confidence: Float                   // 0.0-1.0
    public let priority: Int                       // 1 = highest
    public let boundingBox: CGRect                 // Normalized (0-1)
    public let estimatedPointSize: CGFloat?        // Text size estimate
    public let heightInPixels: CGFloat?

    // Convenience
    public var confidencePercent: Int              // 0-100
    public var isHighConfidence: Bool              // >= 80%
    public var priorityDescription: String         // "Highest", "High", etc.
}
```

**Example:**

```swift
for result in analyzed.textResults {
    print("\(result.text)")
    print("  Priority: \(result.priority) (\(result.priorityDescription))")
    print("  Confidence: \(result.confidencePercent)%")
    if let pointSize = result.estimatedPointSize {
        print("  Font size: ~\(Int(pointSize))pt")
    }
}
```

#### FaceRecognitionResult

Represents a detected face.

```swift
public struct FaceRecognitionResult: Identifiable {
    public let id: UUID
    public let boundingBox: CGRect
    public let landmarks: FacialLandmarks?
    public let captureQuality: Float?              // 0.0-1.0

    // Convenience
    public var qualityPercent: Int?                // 0-100
    public var isHighQuality: Bool                 // >= 80%
    public var hasLandmarks: Bool
}

public struct FacialLandmarks {
    public let leftEye: CGPoint?
    public let rightEye: CGPoint?
    public let nose: CGPoint?
    public let mouth: CGPoint?
}
```

#### ObjectRecognitionResult

Represents a classified object or scene.

```swift
public struct ObjectRecognitionResult: Identifiable {
    public let id: UUID
    public let identifier: String                  // e.g., "indoor_scene"
    public let confidence: Float                   // 0.0-1.0

    // Convenience
    public var confidencePercent: Int              // 0-100
    public var displayName: String                 // e.g., "Indoor Scene"
    public var isHighConfidence: Bool              // >= 50%
}
```

#### ImageOverlayView

SwiftUI view for displaying images with analysis overlays.

```swift
public struct ImageOverlayView: View {
    public init(analyzedImage: AnalyzedImage)
}
```

**Features:**
- Blue bounding boxes around text
- Green bounding boxes around faces
- Yellow crosses at facial landmarks
- Priority badges on text (P1, P2, P3...)
- Works on both iOS and macOS

**Example:**

```swift
if let analyzed = service.analyzedImage {
    ImageOverlayView(analyzedImage: analyzed)
        .frame(height: 400)
}
```

## Advanced Usage

### Filter by Priority

Get only high-priority text:

```swift
let highPriorityText = analyzed.textResults
    .filter { $0.priority <= 2 }
    .map { $0.text }
```

### Filter by Confidence

Get high-confidence results:

```swift
let reliableText = analyzed.textResults
    .filter { $0.isHighConfidence }  // >= 80%
```

### Sort by Priority

```swift
let sortedByImportance = analyzed.textResultsByPriority
```

### Access Face Details

```swift
for face in analyzed.faceResults {
    if face.isHighQuality {
        print("High quality face detected")
    }

    if let landmarks = face.landmarks {
        if let leftEye = landmarks.leftEye {
            print("Left eye at: \(leftEye)")
        }
    }
}
```

### Check Object Classifications

```swift
let highConfidenceObjects = analyzed.objectResults
    .filter { $0.isHighConfidence }  // >= 50%
    .map { $0.displayName }

print("Detected: \(highConfidenceObjects.joined(separator: ", "))")
```

## Customization

### Modify Overlay Colors

Edit `ImageOverlayView.swift`:

```swift
// Line ~51 - Text box color
drawBoundingBox(..., color: .blue, ...)  // Change to .purple, .red, etc.

// Line ~67 - Face box color
drawBoundingBox(..., color: .green, ...)

// Line ~226 - Priority badge colors
let badgeColor: Color = {
    switch priority {
    case 1: return .red
    case 2: return .orange
    case 3: return .blue
    default: return .gray
    }
}()
```

### Adjust Analysis Types

Edit `ImageAnalysisService.swift` line ~65:

```swift
// Default: analyze text, faces, and objects
analysisTypes: [.text, .faces, .objects]

// Text only:
analysisTypes: [.text]

// All available types:
analysisTypes: [.text, .faces, .objects, .barcodes, .saliency]
```

### Change Image Size Limit

Edit `ImagePreprocessor.swift` line ~17:

```swift
static let maxDimension: CGFloat = 4096  // Default

// Increase for higher quality (slower):
static let maxDimension: CGFloat = 8192

// Decrease for faster analysis:
static let maxDimension: CGFloat = 2048
```

## Platform Differences

### iOS vs macOS

The service uses `PlatformImage` which is:
- `UIImage` on iOS
- `NSImage` on macOS

The API is identical on both platforms. Platform-specific code is handled internally.

### Coordinate Systems

**Bounding boxes** use Vision's coordinate system:
- Origin: bottom-left (0, 0)
- Range: 0.0 to 1.0 (normalized)
- Top-right: (1, 1)

`ImageOverlayView` automatically converts to SwiftUI's top-left coordinate system.

## Error Handling

Errors are exposed via the `error` property:

```swift
if let error = service.error {
    switch error {
    case let analysisError as ImageAnalysisError:
        // Handle specific errors
        print(analysisError.localizedDescription)
    default:
        // Handle general errors
        print("Analysis failed: \(error)")
    }
}
```

## Performance Tips

1. **Analyze smaller images** - The service automatically resizes large images, but starting with smaller images is faster

2. **Run analysis in background** - Use `Task { await service.analyze(...) }` to avoid blocking UI

3. **Reuse service instance** - Create one `ImageAnalysisService` and reuse it

4. **Clear when done** - Call `service.clear()` to release memory after displaying results

5. **Limit analysis types** - Only analyze what you need (text vs. faces vs. objects)

## Troubleshooting

### "Cannot find type 'PlatformImage'"
- Ensure `Models/PlatformImage.swift` is included in your target
- Check file is added to the correct target in Xcode

### "Image analysis failed"
- Verify image data is valid
- Check console for specific Vision framework errors
- Ensure image isn't corrupted

### "UI not updating"
- Make sure you're using `@State` with the service (not `@StateObject`)
- Verify iOS 17+ / macOS 14+ deployment target
- Check the service is marked with `@Observable`

### Build errors about @Observable
- Update to Xcode 16+ and Swift 6+
- Set deployment target to iOS 17.0+ or macOS 14.0+

### Slow analysis
- Reduce `ImagePreprocessor.maxDimension`
- Only analyze required types (text, faces, or objects)
- Ensure running on real device, not simulator (for best performance)

## Example Projects

### Text Scanner

```swift
struct TextScannerView: View {
    @State private var service = ImageAnalysisService()
    @State private var extractedText = ""

    var body: some View {
        VStack {
            Button("Scan Text from Photo") {
                // Present image picker
            }

            if service.isAnalyzing {
                ProgressView()
            } else if !extractedText.isEmpty {
                ScrollView {
                    Text(extractedText)
                        .textSelection(.enabled)
                        .padding()
                }
            }
        }
    }

    func processImage(_ image: UIImage) async {
        await service.analyze(image: image)

        if let results = service.analyzedImage {
            // Extract all text sorted by priority
            extractedText = results.textResultsByPriority
                .map { $0.text }
                .joined(separator: "\n")
        }
    }
}
```

### Face Counter

```swift
struct FaceCounterView: View {
    @State private var service = ImageAnalysisService()

    var body: some View {
        VStack {
            if let analyzed = service.analyzedImage {
                Text("Faces detected: \(analyzed.faceResults.count)")
                    .font(.title)

                ImageOverlayView(analyzedImage: analyzed)
            }
        }
    }
}
```

## License

This code is part of the Foundation Lab project. Copy and modify freely for your own projects.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the example code in `Foundation Lab/Vision/`
3. Consult Apple's Vision framework documentation

## Version History

### 1.0.0 (2025)
- Initial release
- Text recognition with priority scoring
- Face detection with landmarks
- Object classification
- Cross-platform support (iOS/macOS)
- SwiftUI overlay view
