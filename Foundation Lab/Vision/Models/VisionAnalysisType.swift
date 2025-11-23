//
//  VisionAnalysisType.swift
//  Foundation Lab
//
//  Enum defining all available Vision analysis types
//

import Foundation

/// Types of analysis that can be performed on images
enum VisionAnalysisType: String, CaseIterable, Codable {
    case text = "text"
    case faces = "faces"
    case objectsAndScenes = "objects"
    case barcodes = "barcodes"
    case saliency = "saliency"

    var displayName: String {
        switch self {
        case .text:
            return "Text Recognition"
        case .faces:
            return "Face Detection"
        case .objectsAndScenes:
            return "Objects & Scenes"
        case .barcodes:
            return "Barcode Detection"
        case .saliency:
            return "Saliency Detection"
        }
    }

    var description: String {
        switch self {
        case .text:
            return "Extract text from images (OCR)"
        case .faces:
            return "Detect faces and facial landmarks"
        case .objectsAndScenes:
            return "Classify objects and scene types"
        case .barcodes:
            return "Detect and read barcodes/QR codes"
        case .saliency:
            return "Identify visually prominent areas"
        }
    }

    var icon: String {
        switch self {
        case .text:
            return "doc.text.viewfinder"
        case .faces:
            return "face.smiling"
        case .objectsAndScenes:
            return "cube.box.fill"
        case .barcodes:
            return "barcode.viewfinder"
        case .saliency:
            return "eye"
        }
    }
}
