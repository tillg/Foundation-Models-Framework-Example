# Image Fullscreen View

## Overview
Add the ability to tap on the analyzed image to view it in fullscreen mode, preserving all overlays (bounding boxes and facial landmarks) for detailed inspection.

## Current Behavior
- Image displayed at fixed max height of 300px in VisionExampleView
- Overlays (green boxes, yellow landmark crosses) visible on the image
- No way to zoom in or view the image larger
- Analysis details shown below in scrollable results

## Requested Enhancement
When user taps on the image (with or without overlay):
- Present image in **fullscreen/maximized view**
- Preserve all overlays (bounding boxes and landmarks)
- Allow pinch-to-zoom for detailed inspection
- Dismiss with tap, swipe, or close button

## Implementation Plan

### Phase 1: Create Fullscreen Image View
**New File:** `Foundation Lab/Vision/Views/Components/FullscreenImageView.swift`

**Purpose:** Dedicated view for fullscreen image display with overlays

**Features:**
1. Fullscreen presentation (edge-to-edge)
2. ImageOverlayView integration (reuse existing overlay component)
3. Pinch-to-zoom and pan gestures
4. Dismiss gesture (tap outside or swipe down)
5. Close button in top-right corner

**Implementation:**
```swift
struct FullscreenImageView: View {
    let image: PlatformImage
    let results: ImageFeatures
    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Dark background
            #if os(iOS)
            Color.black.ignoresSafeArea()
            #elseif os(macOS)
            Color.black
            #endif

            // Image with overlays (zoomable)
            ImageOverlayView(image: image, results: results)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .gesture(dragGesture)
                .onTapGesture(count: 2) {
                    // Double-tap to reset zoom
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        lastScale = 1.0
                        lastOffset = .zero
                    }
                }

            // Close button (iOS only, macOS uses sheet dismiss)
            #if os(iOS)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
            #endif
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #endif
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, 1.0), 5.0)  // Clamp to 1.0-5.0x
            }
            .onEnded { value in
                lastScale = scale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                lastOffset = offset
            }
    }
}
```

### Phase 2: Add Fullscreen State to VisionExampleView
**File:** `Foundation Lab/Vision/Views/VisionExampleView.swift`

**Changes:**
1. Add state variable for fullscreen presentation
2. Add tap gesture to image
3. Present fullscreen view (platform-specific: fullScreenCover on iOS, sheet on macOS)

**Implementation:**
```swift
struct VisionExampleView: View {
    @State private var viewModel = VisionExampleViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingOverlay = false
    @State private var showingFullscreen = false  // NEW

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ... existing header code ...

                // Selected Image Preview (MODIFIED)
                VStack(spacing: 12) {
                    if let image = viewModel.selectedImage {
                        if showingOverlay, let results = viewModel.analysisResults {
                            ImageOverlayView(image: image, results: results)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .onTapGesture {  // NEW
                                    showingFullscreen = true
                                }
                        } else {
                            #if canImport(UIKit)
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .onTapGesture {  // NEW
                                    if viewModel.analysisResults != nil {
                                        showingFullscreen = true
                                    }
                                }
                            #elseif canImport(AppKit)
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .onTapGesture {  // NEW
                                    if viewModel.analysisResults != nil {
                                        showingFullscreen = true
                                    }
                                }
                            #endif
                        }
                    }

                    // ... existing buttons ...
                }
            }
        }
        // PLATFORM-SPECIFIC PRESENTATION
        #if os(iOS)
        .fullScreenCover(isPresented: $showingFullscreen) {
            if let image = viewModel.selectedImage,
               let results = viewModel.analysisResults {
                FullscreenImageView(image: image, results: results)
            }
        }
        #elseif os(macOS)
        .sheet(isPresented: $showingFullscreen) {
            if let image = viewModel.selectedImage,
               let results = viewModel.analysisResults {
                FullscreenImageView(image: image, results: results)
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
        #endif
    }
}
```

### Phase 3: Alternative - Sheet Presentation (iOS)
Instead of fullScreenCover, could use `.sheet()` for a more iOS-standard presentation:

```swift
.sheet(isPresented: $showingFullscreen) {
    if let image = viewModel.selectedImage,
       let results = viewModel.analysisResults {
        NavigationStack {
            FullscreenImageView(image: image, results: results)
                .navigationTitle("Image Analysis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingFullscreen = false
                        }
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}
```

## User Experience Flow

### Scenario 1: View Analysis with Overlay
1. User selects image
2. User runs analysis
3. Overlay auto-shows with bounding boxes and landmarks
4. **User taps on image** → Fullscreen view opens
5. User can pinch-to-zoom to inspect details
6. User taps X button or swipes down → Returns to main view

### Scenario 2: View Large Image Details
1. User has analyzed image with multiple faces
2. Wants to see which landmarks were detected on each face
3. Taps image → Fullscreen view
4. Pinches to zoom in on specific face
5. Sees yellow crosses precisely positioned on eyes, nose, mouth
6. Double-taps to reset zoom

### Scenario 3: Inspect Text Recognition
1. User analyzes image with text
2. Blue bounding boxes shown around detected text
3. Taps image → Fullscreen
4. Zooms in to verify text detection accuracy
5. Sees which words were detected (blue boxes)

## UI Enhancements

### Tap Target
**Where to add tap gesture:**
- On the entire image (both overlay and non-overlay versions)
- Only active when analysis results exist
- Visual hint (optional): Subtle "tap to expand" hint on first use

### Visual Feedback
**Tap indication:**
- Brief scale animation on tap (0.98 → 1.0)
- Or subtle highlight effect
- Indicates the image is tappable

**Example:**
```swift
.scaleEffect(isTapping ? 0.98 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isTapping)
.onTapGesture {
    isTapping = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isTapping = false
        showingFullscreen = true
    }
}
```

### Zoom Controls (Optional)
Add zoom controls in fullscreen view:
- Reset button (back to 1x zoom)
- Zoom in/out buttons (+/-)
- Current zoom level indicator (e.g., "2.5x")

## Technical Considerations

### Gesture Conflicts
**Issue:** ImageOverlayView's Canvas might interfere with tap gesture

**Solution:**
- Use `.allowsHitTesting(false)` on Canvas (already implemented)
- Attach tap gesture to parent container, not overlay itself

### Overlay Preservation
**Requirement:** Overlays must be visible and interactive in fullscreen

**Solution:**
- Reuse ImageOverlayView component (already supports scaling)
- Canvas drawing automatically scales with image
- Bounding boxes and landmarks remain correctly positioned at any zoom level

### Zoom Limits
**Constraints:**
- Minimum scale: 1.0 (fit to screen)
- Maximum scale: 5.0 (prevent excessive zoom)
- Clamp offset to prevent panning out of bounds

**Implementation:**
```swift
.onChange(of: scale) { oldValue, newValue in
    scale = min(max(newValue, 1.0), 5.0)
}
```

### Presentation Style

**Options:**

1. **fullScreenCover** (Recommended for iOS)
   - True fullscreen (no sheet chrome)
   - Immersive experience
   - Best for detailed inspection
   - Dismisses with custom button or gesture

2. **sheet** (Alternative)
   - Standard iOS sheet presentation
   - Drag to dismiss built-in
   - Navigation bar available
   - More familiar to users

3. **Custom Transition** (Advanced)
   - Hero animation from thumbnail to fullscreen
   - Smooth expansion animation
   - More polished but complex

## Files to Modify

### 1. Create FullscreenImageView.swift
**Location:** `Foundation Lab/Vision/Views/Components/FullscreenImageView.swift`

**Purpose:** Dedicated fullscreen image viewer with zoom

**Size:** ~100-120 lines

### 2. Update VisionExampleView.swift
**Location:** `Foundation Lab/Vision/Views/VisionExampleView.swift`

**Changes:**
- Add `@State private var showingFullscreen = false`
- Add `.onTapGesture` to image (both overlay and plain versions)
- Add `.fullScreenCover` or `.sheet` modifier
- Only enable tap when `analysisResults != nil`

**Lines Changed:** ~15-20 lines

## Edge Cases

### No Analysis Results
- Tapping image before analysis → No action
- Only enable tap gesture when `viewModel.analysisResults != nil`

### Overlay Hidden
- User can tap image even when overlay is hidden
- Fullscreen should still show overlay (or respect current toggle state)
- Option: Always show overlay in fullscreen, or preserve toggle state

### Multiple Analyses
- User changes analysis types and re-analyzes
- Fullscreen should show latest results
- Dismiss fullscreen when new analysis starts (optional)

### Memory Management
- Fullscreen view holds reference to image and results
- Both are already in memory from main view
- No additional memory overhead
- Dismiss properly releases references

## Accessibility

### VoiceOver
- Image should have accessibility label: "Analyzed image, double-tap to view fullscreen"
- Fullscreen close button: "Close fullscreen view"
- Zoom level announcement: "Zoomed to 2.5x"

### Dynamic Type
- Close button should scale with Dynamic Type
- Zoom controls (if added) should scale

## Testing Scenarios

### Basic Functionality
1. Analyze image → Tap image → Fullscreen opens ✓
2. Pinch to zoom → Image and overlays scale together ✓
3. Pan around zoomed image → Smooth panning ✓
4. Double-tap → Zoom resets to 1.0 ✓
5. Tap X button → Dismisses to main view ✓

### Overlay Preservation
1. Green face boxes visible in fullscreen ✓
2. Yellow landmark crosses visible in fullscreen ✓
3. All overlays scale correctly with zoom ✓
4. Overlays remain aligned after zoom/pan ✓

### Edge Cases
1. Tap before analysis → Nothing happens ✓
2. Hide overlay, tap image → Fullscreen behavior (show or hide?) ✓
3. Dismiss fullscreen, run new analysis → Works correctly ✓
4. Rapid tap while zooming → No crashes ✓

## Design Decisions

### Presentation Style
**Recommendation:** Use `.fullScreenCover` on iOS for immersive inspection experience

**Rationale:**
- Maximizes screen real estate for detailed analysis
- No sheet chrome to distract from image
- Clear close button for dismissal
- Consistent with photo viewing apps

### Overlay Toggle in Fullscreen
**Decision:** Always show overlay in fullscreen (ignore main view toggle state)

**Rationale:**
- User tapped specifically to inspect analysis results
- Showing overlay is the expected behavior
- User can dismiss if they want to see just the image

**Alternative:** Preserve toggle state and add toggle button in fullscreen

### Zoom Behavior
**Decision:** Support pinch-to-zoom with 1.0-5.0x range

**Rationale:**
- Essential for inspecting small landmarks or text
- 5x max prevents pixelation while allowing detail inspection
- Double-tap to reset is intuitive

## Success Criteria

✅ Tapping analyzed image opens fullscreen view
✅ Fullscreen shows image with all overlays (boxes + landmarks)
✅ Pinch-to-zoom works (1.0x to 5.0x)
✅ Pan gesture works when zoomed
✅ Double-tap resets zoom to 1.0x
✅ Close button dismisses to main view
✅ Overlays remain correctly positioned at all zoom levels
✅ Smooth animations and transitions
✅ No gesture conflicts
✅ Works on both iPhone and iPad

## Future Enhancements (Optional)

### Zoom Controls
- Zoom in/out buttons
- Zoom level indicator ("2.5x")
- Fit to screen button

### Overlay Toggle in Fullscreen
- Toggle button to show/hide overlays
- Useful for comparing analyzed vs original image

### Share Function
- Share button to export image with overlays
- Save to Photos with overlays rendered
- Share analysis results as text

### Image Comparison
- Side-by-side view: original vs analyzed
- Slider to reveal overlays

### Rotation Support
- Rotate image in fullscreen
- Overlays rotate with image

## Platform Considerations

### iOS / iPadOS
**Presentation:**
- ✅ Use `.fullScreenCover` (available iOS 14.0+)
- Edge-to-edge fullscreen presentation
- Custom close button (X in top-right corner)

**Gestures:**
- ✅ `MagnificationGesture()` for pinch-to-zoom (works with touch)
- ✅ `DragGesture()` for pan when zoomed
- ✅ Double-tap to reset zoom
- Support both portrait and landscape orientations

**UI:**
- Dark background with `.ignoresSafeArea()`
- Floating close button over image
- No navigation bar (immersive experience)

### macOS
**Presentation:**
- ⚠️ `.fullScreenCover` NOT available on native macOS (only Mac Catalyst)
- ✅ Use `.sheet` instead (standard macOS modal)
- Window-based presentation with title bar
- Built-in close button (standard sheet behavior)

**Gestures:**
- ✅ `MagnificationGesture()` works with trackpad pinch (2-finger pinch)
- ✅ `DragGesture()` works with trackpad drag
- ✅ Double-click to reset zoom (not double-tap)
- Mouse scroll wheel zoom could be added (optional)

**UI:**
- Sheet presentation with `.frame(minWidth:minHeight:)` for sizing
- Toolbar with "Done" button (standard macOS pattern)
- Dark background without ignoring safe area
- Resizable sheet window

**Keyboard Shortcuts (macOS-specific):**
```swift
.onKeyPress(.escape) {
    dismiss()
    return .handled
}
.onKeyPress(.init("+")) {
    scale = min(scale + 0.2, 5.0)
    return .handled
}
.onKeyPress(.init("-")) {
    scale = max(scale - 0.2, 1.0)
    return .handled
}
```

### Platform Differences Summary

| Feature | iOS/iPadOS | macOS |
|---------|-----------|--------|
| Presentation | `.fullScreenCover` | `.sheet` |
| Background | `.ignoresSafeArea()` | Normal bounds |
| Close Button | Custom (X icon) | Toolbar ("Done") |
| Zoom Gesture | Touch pinch | Trackpad pinch |
| Pan Gesture | Touch drag | Trackpad drag |
| Reset Zoom | Double-tap | Double-click |
| Keyboard Shortcuts | N/A | Esc, +, - |

## Dependencies

- No new dependencies required
- Reuses existing ImageOverlayView component
- Uses standard SwiftUI gestures (MagnificationGesture, DragGesture)
- Uses standard presentation modifiers (.fullScreenCover or .sheet)

## Estimated Effort

- **FullscreenImageView creation:** 45-60 minutes
- **VisionExampleView integration:** 15-20 minutes
- **Testing and polish:** 20-30 minutes
- **Total:** ~1.5-2 hours

## Example Code Structure

### File Structure After Implementation
```
Foundation Lab/Vision/Views/
├── VisionExampleView.swift (modified)
└── Components/
    ├── ImagePickerView.swift
    ├── AnalysisResultView.swift
    ├── ImageOverlayView.swift
    └── FullscreenImageView.swift (NEW)
```

### Integration in VisionExampleView
```swift
// Add state
@State private var showingFullscreen = false

// Modify image display
ImageOverlayView(image: image, results: results)
    .frame(maxHeight: 300)
    .cornerRadius(12)
    .onTapGesture {
        showingFullscreen = true
    }

// Add presentation
.fullScreenCover(isPresented: $showingFullscreen) {
    if let image = viewModel.selectedImage,
       let results = viewModel.analysisResults {
        FullscreenImageView(image: image, results: results)
    }
}
```

## Implementation Notes

### Gesture Handling
- MagnificationGesture for zoom (pinch)
- DragGesture for pan (when zoomed)
- TapGesture for dismiss (single tap on background)
- TapGesture(count: 2) for reset zoom (double-tap)

### State Management
- `scale`: Current zoom level (1.0 = fit to screen)
- `lastScale`: Previous zoom level (for gesture continuation)
- `offset`: Current pan offset
- `lastOffset`: Previous pan offset (for gesture continuation)

### Animation
- Use `.animation(.interactiveSpring())` for smooth zoom/pan
- No animation on gesture updates (feels more responsive)
- Animate on reset zoom (double-tap)

## Alternative Approach: Photo Viewer Library

If more advanced features needed, could integrate third-party library:
- Supports advanced gestures
- Image gallery/carousel support
- Built-in zoom controls
- More polished UX

However, custom implementation is recommended for:
- Full control over overlay rendering
- Consistent with app architecture
- No external dependencies
- Simpler maintenance 