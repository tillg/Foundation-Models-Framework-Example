# Identify Font Size in Image Text

## Goal
When analyzing text in images, measure the "importance" or prominence of different text elements to better understand the visual hierarchy and prioritize content.

## Research: Apple Vision Framework Capabilities

### VNRecognizedText Properties
The Vision framework's `VNRecognizeTextRequest` returns `VNRecognizedText` objects with:
- `boundingBox`: Normalized coordinates (0-1) of text region
- `topCandidates(_:)`: Array of `VNRecognizedTextObservation` with confidence scores
- Character-level bounding boxes via `boundingBox(for:)` method

**Key Finding**: Vision framework does NOT directly provide font size information. It provides spatial coordinates only.

### Available Metrics from Vision Framework
1. **Bounding Box Dimensions**: Height and width in normalized coordinates
2. **Character Bounding Boxes**: Individual character positions
3. **Confidence Scores**: Recognition accuracy (not related to size)
4. **Text Baseline**: Orientation and alignment information

## Implementation Approaches

### Approach 1: Height-Based Estimation (Recommended)
Calculate apparent font size using bounding box height relative to image dimensions.

```swift
// Pseudo-code
let imageHeight = image.size.height
let textHeight = observation.boundingBox.height * imageHeight

// Approximate point size (72 points per inch, typical screen DPI ~144-220)
let estimatedPointSize = textHeight * 0.75 // Heuristic conversion factor
```

**Pros**:
- Simple and fast
- Works for horizontal text
- Good relative measure for importance ranking

**Cons**:
- Doesn't account for font families (different x-heights)
- Less accurate for multi-line text blocks
- Assumes standard aspect ratios

### Approach 2: Character-Level Surface Area Calculation
Calculate area per character for more accurate size estimation.

```swift
// Pseudo-code
let boundingBox = observation.boundingBox
let textArea = boundingBox.width * boundingBox.height * imageArea
let characterCount = observation.text.count
let areaPerCharacter = textArea / Double(characterCount)

// Score based on area per character
let importanceScore = sqrt(areaPerCharacter) // Normalizes to linear dimension
```

**Pros**:
- Accounts for text length
- Better handles wide vs. tall text blocks
- More robust for varying aspect ratios

**Cons**:
- More complex calculation
- Doesn't distinguish between tight and loose kerning
- Requires character count normalization

### Approach 3: Hybrid Approach (Most Robust)
Combine height and area-per-character with weighted scoring.

```swift
// Pseudo-code
struct TextImportanceMetrics {
    let heightScore: Double        // Normalized height (0-1)
    let areaPerCharScore: Double   // Normalized area per character
    let positionScore: Double      // Y-position weight (top = higher importance)

    var combinedScore: Double {
        (heightScore * 0.5) +
        (areaPerCharScore * 0.3) +
        (positionScore * 0.2)
    }
}
```

**Additional Factors**:
- **Position**: Text at top of image often more important
- **Contrast**: Could integrate with color analysis (not from Vision)
- **Isolation**: Text surrounded by whitespace may be headers
- **Line Count**: Single-line text often more important than paragraphs

## Implementation Plan

### Phase 1: Basic Height-Based Scoring
1. Add `FontSizeAnalyzer` utility class
2. Calculate normalized height for each `VNRecognizedText`
3. Rank text elements by height
4. Return sorted array with importance scores

### Phase 2: Enhanced Area-Based Calculation
1. Implement area-per-character calculation
2. Add character-level bounding box analysis (if needed for accuracy)
3. Compare height-only vs. area-based rankings

### Phase 3: Contextual Importance Scoring
1. Integrate position weighting (top vs. bottom)
2. Consider text density (isolated vs. grouped)
3. Add configurable scoring weights

## Data Structure

```swift
struct TextElement {
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    // Font size estimation
    let estimatedPointSize: CGFloat
    let heightInPixels: CGFloat
    let areaPerCharacter: CGFloat

    // Importance scoring
    let importanceScore: Double
    let rank: Int  // 1 = most important
}
```

## Integration Points

### Existing Vision Lab Code
- Modify `VisionLabViewModel` to include importance analysis
- Add scoring display in `ImageAnalysisDetailView`
- Visualize text importance with color coding or size indicators
- Sort analyzed text by importance in UI

### Testing Strategy
- Test with various image types: posters, documents, UI screenshots, signs
- Validate against human judgment of text importance
- Compare different scoring approaches
- Handle edge cases: rotated text, vertical text, overlapping text

## Open Questions

1. Should we use device screen DPI for point size conversion or assume standard 72 DPI? 
   * Whatever is simpler.
2. How to handle non-Latin scripts (CJK characters have different proportions)?
   * Don't bother, we treat all characters simply the same way.
3. Should importance scoring be image-specific or normalized across multiple images?
   * We only do a scoring / ordering within 1 image
4. Do we want to expose raw metrics or just final importance ranking?
   * Only the final ranking, i.e. priority. 1 being the highest. And there can be multiple texts with the same priority.

## References

- [Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- `VNRecognizeTextRequest`: Text detection API
- `VNRecognizedText`: Text observation with bounding boxes
- Typography metrics: x-height, cap height, baseline
