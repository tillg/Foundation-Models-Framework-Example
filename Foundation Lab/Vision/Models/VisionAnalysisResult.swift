//
//  VisionAnalysisResult.swift
//  Foundation Lab
//
//  Result model for Vision analysis responses
//

import Foundation
import FoundationModels

/// Result returned from Vision analysis
@Generable
struct VisionAnalysisResult {
    @Guide(description: "Status of the analysis (success or error)")
    var status: String

    @Guide(description: "Human-readable summary of what was found in the image")
    var summary: String

    @Guide(description: "Detailed analysis results organized by type")
    var details: String

    @Guide(description: "Number of items found (total across all analysis types)")
    var itemCount: Int

    @Guide(description: "Error message if analysis failed")
    var errorMessage: String?
}

// MARK: - Result Formatting

extension VisionAnalysisResult {
    /// Creates a successful result with formatted details
    static func success(
        summary: String,
        details: String,
        itemCount: Int
    ) -> VisionAnalysisResult {
        VisionAnalysisResult(
            status: "success",
            summary: summary,
            details: details,
            itemCount: itemCount,
            errorMessage: nil
        )
    }

    /// Creates an error result
    static func error(message: String) -> VisionAnalysisResult {
        VisionAnalysisResult(
            status: "error",
            summary: "Image analysis failed",
            details: message,
            itemCount: 0,
            errorMessage: message
        )
    }
}

// MARK: - PromptRepresentable Conformance

extension VisionAnalysisResult: PromptRepresentable {
    func promptRepresentation() throws -> String {
        if status == "error" {
            return """
            Image Analysis Failed

            Error: \(errorMessage ?? "Unknown error")
            """
        }

        return """
        Image Analysis Results

        \(summary)

        \(details)

        Total items found: \(itemCount)
        """
    }
}
