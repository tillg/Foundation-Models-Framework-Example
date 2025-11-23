//
//  FontSizeAnalyzer.swift
//  Foundation Lab
//
//  Analyzes text elements in images to calculate importance scores
//  based on visual prominence (font size estimation)
//

import Foundation
import CoreGraphics

/// Service class that calculates text importance based on visual prominence
final class FontSizeAnalyzer {

    // MARK: - Analysis Result

    struct TextImportance {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
        let priority: Int  // 1 = highest importance
        let estimatedPointSize: CGFloat
        let heightInPixels: CGFloat
    }

    // MARK: - Analysis Methods

    /// Analyzes text features and returns them ranked by importance
    /// - Parameters:
    ///   - textFeatures: Array of text features from Vision framework
    ///   - imageSize: Size of the analyzed image in pixels
    /// - Returns: Array of text importance results, sorted by priority (1 = highest)
    func analyzeImportance(
        textFeatures: [TextFeature],
        imageSize: CGSize
    ) -> [TextImportance] {
        guard !textFeatures.isEmpty else { return [] }

        // Calculate height scores for all text elements
        let textWithScores = textFeatures.map { feature -> (feature: TextFeature, heightScore: CGFloat) in
            let heightInPixels = feature.boundingBox.height * imageSize.height
            return (feature, heightScore: heightInPixels)
        }

        // Sort by height (descending)
        let sorted = textWithScores.sorted { $0.heightScore > $1.heightScore }

        // Assign priorities (handling ties)
        var results: [TextImportance] = []
        var currentPriority = 1
        var lastScore: CGFloat = -1

        for (index, item) in sorted.enumerated() {
            // If this score is different from the last, increment priority
            if index > 0 && item.heightScore < lastScore {
                currentPriority = index + 1
            }

            let heightInPixels = item.heightScore
            // Simple heuristic: assume 72 DPI standard
            let estimatedPointSize = heightInPixels * 0.75

            results.append(TextImportance(
                text: item.feature.text,
                confidence: item.feature.confidence,
                boundingBox: item.feature.boundingBox,
                priority: currentPriority,
                estimatedPointSize: estimatedPointSize,
                heightInPixels: heightInPixels
            ))

            lastScore = item.heightScore
        }

        return results
    }

    /// Calculates area-per-character metric for a text element
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box (0-1 coordinates)
    ///   - text: The recognized text string
    ///   - imageSize: Size of the analyzed image in pixels
    /// - Returns: Area per character in square pixels
    func calculateAreaPerCharacter(
        boundingBox: CGRect,
        text: String,
        imageSize: CGSize
    ) -> CGFloat {
        let textArea = boundingBox.width * boundingBox.height * imageSize.width * imageSize.height
        let characterCount = max(1, Double(text.count))
        return textArea / characterCount
    }
}
