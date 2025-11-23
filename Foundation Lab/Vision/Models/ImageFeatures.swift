//
//  ImageFeatures.swift
//  Foundation Lab
//
//  Data structures for Vision analysis results
//

import Foundation
import CoreGraphics

/// Container for all image analysis features
struct ImageFeatures {
    var textFeatures: [TextFeature] = []
    var faceFeatures: [FaceFeature] = []
    var objectFeatures: [ObjectFeature] = []
    var barcodeFeatures: [BarcodeFeature] = []
    var saliencyFeatures: [SaliencyFeature] = []
}

/// Extracted text information
struct TextFeature: Identifiable {
    let id = UUID()
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    var confidencePercent: Int {
        Int(confidence * 100)
    }
}

/// Face detection information
struct FaceFeature: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let landmarks: FaceLandmarkPoints?
    let captureQuality: Float?

    var qualityPercent: Int? {
        guard let quality = captureQuality else { return nil }
        return Int(quality * 100)
    }
}

/// Facial landmark points
struct FaceLandmarkPoints {
    let leftEye: CGPoint?
    let rightEye: CGPoint?
    let nose: CGPoint?
    let mouth: CGPoint?
}

/// Object classification information
struct ObjectFeature: Identifiable {
    let id = UUID()
    let identifier: String
    let confidence: Float

    var confidencePercent: Int {
        Int(confidence * 100)
    }

    var displayName: String {
        // Convert identifier to readable format (e.g., "indoor_scene" -> "Indoor Scene")
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

/// Barcode/QR code information
struct BarcodeFeature: Identifiable {
    let id = UUID()
    let payload: String
    let symbology: String
    let boundingBox: CGRect

    var symbologyDisplayName: String {
        // Convert symbology to readable format
        symbology
            .replacingOccurrences(of: "VNBarcodeSymbology", with: "")
            .replacingOccurrences(of: "Code", with: " Code ")
            .trimmingCharacters(in: .whitespaces)
    }
}

/// Saliency (visual attention) information
struct SaliencyFeature: Identifiable {
    let id = UUID()
    let boundingBoxes: [CGRect]
    let regionCount: Int

    init(boundingBoxes: [CGRect]) {
        self.boundingBoxes = boundingBoxes
        self.regionCount = boundingBoxes.count
    }
}

// MARK: - Helper Extensions

extension ImageFeatures {
    var hasAnyResults: Bool {
        !textFeatures.isEmpty ||
        !faceFeatures.isEmpty ||
        !objectFeatures.isEmpty ||
        !barcodeFeatures.isEmpty ||
        !saliencyFeatures.isEmpty
    }

    var resultCount: Int {
        textFeatures.count +
        faceFeatures.count +
        objectFeatures.count +
        barcodeFeatures.count +
        saliencyFeatures.count
    }
}
