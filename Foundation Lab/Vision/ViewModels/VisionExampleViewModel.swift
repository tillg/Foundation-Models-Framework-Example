//
//  VisionExampleViewModel.swift
//  Foundation Lab
//
//  ViewModel for Vision example interface
//

import Foundation
import SwiftUI
import PhotosUI
import FoundationModels

@Observable
final class VisionExampleViewModel {

    // MARK: - Published State

    var selectedImage: PlatformImage?
    var selectedImageURL: URL?
    var selectedImageOrientation: CGImagePropertyOrientation = .up
    var analysisResults: ImageFeatures?
    var isAnalyzing = false
    var errorMessage: String?
    var selectedAnalysisTypes: Set<VisionAnalysisType> = [.text, .faces, .objectsAndScenes]
    var includeConfidence = true

    // MARK: - Services

    private let analyzer = VisionAnalyzer()
    private let preprocessor = ImagePreprocessor()

    // MARK: - Image Selection

    func loadImage(from item: PhotosPickerItem) async {
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = PlatformImage(data: data) else {
                errorMessage = "Failed to load image"
                return
            }

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")

            guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
                errorMessage = "Failed to process image"
                return
            }

            try jpegData.write(to: tempURL)

            selectedImage = image
            selectedImageURL = tempURL
            #if canImport(UIKit)
            selectedImageOrientation = CGImagePropertyOrientation(image.imageOrientation)
            #else
            selectedImageOrientation = .up
            #endif
            analysisResults = nil

        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }

    func loadImage(from url: URL) {
        errorMessage = nil

        do {
            let data = try Data(contentsOf: url)
            guard let image = PlatformImage(data: data) else {
                errorMessage = "Failed to load image from file"
                return
            }

            selectedImage = image
            selectedImageURL = url
            analysisResults = nil

        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }

    // MARK: - Analysis

    func analyzeImage() async {
        guard let imageURL = selectedImageURL else {
            errorMessage = "No image selected"
            return
        }

        guard !selectedAnalysisTypes.isEmpty else {
            errorMessage = "Select at least one analysis type"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisResults = nil

        do {
            // Preprocess image
            let preprocessedURL = try await preprocessor.preprocess(imagePath: imageURL.path())

            // Convert analysis types
            let analysisTypes = selectedAnalysisTypes.compactMap { type -> VisionAnalyzer.AnalysisType? in
                VisionAnalyzer.AnalysisType(rawValue: type.rawValue)
            }

            // Perform analysis
            let results = try await analyzer.analyze(
                imagePath: preprocessedURL.path(),
                analysisTypes: analysisTypes,
                includeConfidence: includeConfidence,
                orientation: selectedImageOrientation
            )

            // Convert to ImageFeatures
            analysisResults = convertToImageFeatures(results)

            // Clean up temp file ONLY if it's different from the original
            // (preprocessor created a resized version)
            if preprocessedURL != imageURL {
                preprocessor.cleanupTemporaryFile(at: preprocessedURL)
            }

        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    // MARK: - Helper Methods

    private func convertToImageFeatures(_ results: VisionAnalyzer.AnalysisResults) -> ImageFeatures {
        var features = ImageFeatures()

        // Convert text results
        features.textFeatures = results.textResults.map { result in
            TextFeature(
                text: result.text,
                confidence: result.confidence,
                boundingBox: result.boundingBox
            )
        }

        // Convert face results
        features.faceFeatures = results.faceResults.map { result in
            let landmarks = result.landmarks.map { visionLandmarks in
                FaceLandmarkPoints(
                    leftEye: visionLandmarks.leftEye,
                    rightEye: visionLandmarks.rightEye,
                    nose: visionLandmarks.nose,
                    mouth: visionLandmarks.mouth
                )
            }

            return FaceFeature(
                boundingBox: result.boundingBox,
                landmarks: landmarks,
                captureQuality: result.captureQuality
            )
        }

        // Convert object results
        features.objectFeatures = results.objectResults.map { result in
            ObjectFeature(
                identifier: result.identifier,
                confidence: result.confidence
            )
        }

        // Convert barcode results
        features.barcodeFeatures = results.barcodeResults.map { result in
            BarcodeFeature(
                payload: result.payload,
                symbology: result.symbology,
                boundingBox: result.boundingBox
            )
        }

        // Convert saliency results
        features.saliencyFeatures = results.saliencyResults.map { result in
            SaliencyFeature(boundingBoxes: result.boundingBoxes)
        }

        return features
    }

    func clearImage() {
        if let url = selectedImageURL {
            preprocessor.cleanupTemporaryFile(at: url)
        }

        selectedImage = nil
        selectedImageURL = nil
        analysisResults = nil
        errorMessage = nil
    }

    func toggleAnalysisType(_ type: VisionAnalysisType) {
        if selectedAnalysisTypes.contains(type) {
            selectedAnalysisTypes.remove(type)
        } else {
            selectedAnalysisTypes.insert(type)
        }
    }
}
