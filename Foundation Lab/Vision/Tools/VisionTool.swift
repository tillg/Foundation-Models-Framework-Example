//
//  VisionTool.swift
//  Foundation Lab
//
//  AI-powered image analysis tool using Apple Vision framework
//

import Foundation
import FoundationModels

/// Tool for analyzing images with Vision framework capabilities
struct VisionTool: Tool {
    let name = "vision_analyze_image"
    let description = """
        Analyzes images using Apple Vision framework to extract text, detect faces, classify objects, \
        identify scenes, read barcodes, and detect salient regions. All analysis happens on-device.
        """

    @Generable
    struct Arguments {
        @Guide(description: "File path or URL to the image to analyze")
        var imagePath: String

        @Guide(description: """
            Types of analysis to perform. Valid values: 'text', 'faces', 'objects', 'scenes', 'barcodes', 'saliency'. \
            Can specify multiple types as comma-separated or array.
            """)
        var analysisTypes: [String]

        @Guide(description: "Whether to include confidence scores in results (default: true)")
        var includeConfidence: Bool?
    }

    private let analyzer = VisionAnalyzer()
    private let preprocessor = ImagePreprocessor()

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        // Validate analysis types
        let requestedTypes = parseAnalysisTypes(arguments.analysisTypes)
        guard !requestedTypes.isEmpty else {
            return VisionAnalysisResult.error(
                message: "No valid analysis types specified. Use: text, faces, objects, scenes, barcodes, or saliency"
            )
        }

        // Preprocess image
        let preprocessedURL: URL
        let originalURL: URL
        do {
            // Convert string path to URL for comparison
            if arguments.imagePath.hasPrefix("/") || arguments.imagePath.hasPrefix("file://") {
                if arguments.imagePath.hasPrefix("file://") {
                    originalURL = URL(fileURLWithPath: String(arguments.imagePath.dropFirst("file://".count)))
                } else {
                    originalURL = URL(fileURLWithPath: arguments.imagePath)
                }
            } else if let url = URL(string: arguments.imagePath), url.scheme != nil {
                originalURL = url
            } else {
                originalURL = URL(fileURLWithPath: arguments.imagePath)
            }

            preprocessedURL = try await preprocessor.preprocess(imagePath: arguments.imagePath)
        } catch {
            return VisionAnalysisResult.error(message: "Failed to load image: \(error.localizedDescription)")
        }

        // Perform analysis
        let results: VisionAnalyzer.AnalysisResults
        do {
            results = try await analyzer.analyze(
                imagePath: preprocessedURL.path(),
                analysisTypes: requestedTypes,
                includeConfidence: arguments.includeConfidence ?? true
            )
        } catch {
            // Clean up temp file only if preprocessing created a new one
            if preprocessedURL != originalURL {
                preprocessor.cleanupTemporaryFile(at: preprocessedURL)
            }
            return VisionAnalysisResult.error(message: "Analysis failed: \(error.localizedDescription)")
        }

        // Clean up temp file only if preprocessing created a new one
        if preprocessedURL != originalURL {
            preprocessor.cleanupTemporaryFile(at: preprocessedURL)
        }

        // Format results
        let formattedResult = formatResults(
            results,
            requestedTypes: requestedTypes,
            includeConfidence: arguments.includeConfidence ?? true
        )

        return formattedResult
    }

    // MARK: - Helper Methods

    private func parseAnalysisTypes(_ types: [String]) -> [VisionAnalyzer.AnalysisType] {
        types.compactMap { typeString in
            let normalized = typeString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return VisionAnalyzer.AnalysisType(rawValue: normalized)
        }
    }

    private func formatResults(
        _ results: VisionAnalyzer.AnalysisResults,
        requestedTypes: [VisionAnalyzer.AnalysisType],
        includeConfidence: Bool
    ) -> VisionAnalysisResult {
        var detailSections: [String] = []
        var totalItems = 0

        // Text Results
        if requestedTypes.contains(.text) {
            let textSection = formatTextResults(results.textResults, includeConfidence: includeConfidence)
            if !textSection.isEmpty {
                detailSections.append("TEXT RECOGNITION:\n\(textSection)")
                totalItems += results.textResults.count
            }
        }

        // Face Results
        if requestedTypes.contains(.faces) {
            let faceSection = formatFaceResults(results.faceResults, includeConfidence: includeConfidence)
            if !faceSection.isEmpty {
                detailSections.append("FACE DETECTION:\n\(faceSection)")
                totalItems += results.faceResults.count
            }
        }

        // Object/Scene Results
        if requestedTypes.contains(.objects) || requestedTypes.contains(.scenes) {
            let objectSection = formatObjectResults(results.objectResults, includeConfidence: includeConfidence)
            if !objectSection.isEmpty {
                detailSections.append("OBJECT & SCENE CLASSIFICATION:\n\(objectSection)")
                totalItems += results.objectResults.count
            }
        }

        // Barcode Results
        if requestedTypes.contains(.barcodes) {
            let barcodeSection = formatBarcodeResults(results.barcodeResults)
            if !barcodeSection.isEmpty {
                detailSections.append("BARCODE DETECTION:\n\(barcodeSection)")
                totalItems += results.barcodeResults.count
            }
        }

        // Saliency Results
        if requestedTypes.contains(.saliency) {
            let saliencySection = formatSaliencyResults(results.saliencyResults)
            if !saliencySection.isEmpty {
                detailSections.append("SALIENCY ANALYSIS:\n\(saliencySection)")
                totalItems += results.saliencyResults.count
            }
        }

        // Generate summary
        let summary = generateSummary(results: results, requestedTypes: requestedTypes)

        return VisionAnalysisResult.success(
            summary: summary,
            details: detailSections.joined(separator: "\n\n"),
            itemCount: totalItems
        )
    }

    private func formatTextResults(_ results: [VisionAnalyzer.TextResult], includeConfidence: Bool) -> String {
        guard !results.isEmpty else { return "No text detected" }

        return results.enumerated().map { index, result in
            let confidenceText = includeConfidence ? " (\(Int(result.confidence * 100))% confidence)" : ""
            return "  \(index + 1). \"\(result.text)\"\(confidenceText)"
        }.joined(separator: "\n")
    }

    private func formatFaceResults(_ results: [VisionAnalyzer.FaceResult], includeConfidence: Bool) -> String {
        guard !results.isEmpty else { return "No faces detected" }

        return results.enumerated().map { index, result in
            var details = "  Face \(index + 1):"

            if let landmarks = result.landmarks {
                let landmarkDetails = [
                    landmarks.leftEye != nil ? "left eye" : nil,
                    landmarks.rightEye != nil ? "right eye" : nil,
                    landmarks.nose != nil ? "nose" : nil,
                    landmarks.mouth != nil ? "mouth" : nil
                ].compactMap { $0 }

                if !landmarkDetails.isEmpty {
                    details += " landmarks detected (\(landmarkDetails.joined(separator: ", ")))"
                }
            }

            if includeConfidence, let quality = result.captureQuality {
                details += " - quality: \(Int(quality * 100))%"
            }

            return details
        }.joined(separator: "\n")
    }

    private func formatObjectResults(_ results: [VisionAnalyzer.ObjectResult], includeConfidence: Bool) -> String {
        guard !results.isEmpty else { return "No objects classified" }

        // Sort by confidence
        let sorted = results.sorted { $0.confidence > $1.confidence }

        // Take top 10 results
        let topResults = sorted.prefix(10)

        return topResults.map { result in
            let confidenceText = includeConfidence ? " (\(Int(result.confidence * 100))%)" : ""
            return "  • \(result.identifier)\(confidenceText)"
        }.joined(separator: "\n")
    }

    private func formatBarcodeResults(_ results: [VisionAnalyzer.BarcodeResult]) -> String {
        guard !results.isEmpty else { return "No barcodes detected" }

        return results.enumerated().map { index, result in
            "  \(index + 1). [\(result.symbology)] \(result.payload)"
        }.joined(separator: "\n")
    }

    private func formatSaliencyResults(_ results: [VisionAnalyzer.SaliencyResult]) -> String {
        guard !results.isEmpty else { return "No salient regions detected" }

        let totalRegions = results.reduce(0) { $0 + $1.boundingBoxes.count }
        return "  Detected \(totalRegions) visually prominent region(s)"
    }

    private func generateSummary(
        results: VisionAnalyzer.AnalysisResults,
        requestedTypes: [VisionAnalyzer.AnalysisType]
    ) -> String {
        var summaryParts: [String] = []

        if requestedTypes.contains(.text) && !results.textResults.isEmpty {
            summaryParts.append("Found \(results.textResults.count) text item(s)")
        }

        if requestedTypes.contains(.faces) && !results.faceResults.isEmpty {
            summaryParts.append("Detected \(results.faceResults.count) face(s)")
        }

        if (requestedTypes.contains(.objects) || requestedTypes.contains(.scenes)) && !results.objectResults.isEmpty {
            summaryParts.append("Classified \(results.objectResults.count) object(s)/scene(s)")
        }

        if requestedTypes.contains(.barcodes) && !results.barcodeResults.isEmpty {
            summaryParts.append("Read \(results.barcodeResults.count) barcode(s)")
        }

        if requestedTypes.contains(.saliency) && !results.saliencyResults.isEmpty {
            let totalRegions = results.saliencyResults.reduce(0) { $0 + $1.boundingBoxes.count }
            summaryParts.append("Found \(totalRegions) salient region(s)")
        }

        if summaryParts.isEmpty {
            return "No features detected in image"
        }

        return summaryParts.joined(separator: ", ")
    }
}
