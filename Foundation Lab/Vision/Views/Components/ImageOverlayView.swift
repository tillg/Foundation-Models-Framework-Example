//
//  ImageOverlayView.swift
//  Foundation Lab
//
//  Overlay view for displaying bounding boxes on images
//

import SwiftUI
import Vision

struct ImageOverlayView: View {
    let image: PlatformImage
    let results: ImageFeatures

    var body: some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(alignment: .topLeading) {
                Canvas { context, size in
                    drawOverlays(context: context, size: size)
                }
                .allowsHitTesting(false)
            }
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(alignment: .topLeading) {
                Canvas { context, size in
                    drawOverlays(context: context, size: size)
                }
                .allowsHitTesting(false)
            }
        #endif
    }

    private func drawOverlays(context: GraphicsContext, size: CGSize) {
        // Draw text bounding boxes
        for textFeature in results.textFeatures {
            drawBoundingBox(
                context: context,
                normalizedBox: textFeature.boundingBox,
                color: .blue,
                canvasSize: size
            )
        }

        // Draw face bounding boxes and landmarks
        for faceFeature in results.faceFeatures {
            drawBoundingBox(
                context: context,
                normalizedBox: faceFeature.boundingBox,
                color: .green,
                canvasSize: size
            )

            // Draw facial landmarks if present
            if let landmarks = faceFeature.landmarks {
                drawLandmarks(
                    context: context,
                    landmarks: landmarks,
                    faceBoundingBox: faceFeature.boundingBox,
                    canvasSize: size
                )
            }
        }

        // Draw barcode bounding boxes
        for barcodeFeature in results.barcodeFeatures {
            drawBoundingBox(
                context: context,
                normalizedBox: barcodeFeature.boundingBox,
                color: .purple,
                canvasSize: size
            )
        }

        // Draw saliency bounding boxes
        for saliencyFeature in results.saliencyFeatures {
            for box in saliencyFeature.boundingBoxes {
                drawBoundingBox(
                    context: context,
                    normalizedBox: box,
                    color: .orange,
                    canvasSize: size
                )
            }
        }
    }

    private func drawBoundingBox(
        context: GraphicsContext,
        normalizedBox: CGRect,
        color: Color,
        canvasSize: CGSize
    ) {
        // Vision returns normalized CGRect with:
        // - origin: bottom-left corner
        // - range: 0.0 to 1.0
        // - coordinate system: (0,0) is bottom-left, (1,1) is top-right

        // Canvas uses:
        // - origin: top-left corner
        // - coordinate system: (0,0) is top-left

        // Convert: multiply by canvas size and flip Y axis
        let x = normalizedBox.origin.x * canvasSize.width
        let width = normalizedBox.width * canvasSize.width
        let height = normalizedBox.height * canvasSize.height

        // Flip Y: Vision's bottom-left to SwiftUI's top-left
        // Vision Y is distance from bottom, SwiftUI Y is distance from top
        let y = canvasSize.height - (normalizedBox.origin.y + normalizedBox.height) * canvasSize.height

        let rect = CGRect(x: x, y: y, width: width, height: height)

        var path = Path()
        path.addRect(rect)

        context.stroke(
            path,
            with: .color(color),
            lineWidth: 3
        )
    }

    private func drawLandmarks(
        context: GraphicsContext,
        landmarks: FaceLandmarkPoints,
        faceBoundingBox: CGRect,
        canvasSize: CGSize
    ) {
        // Landmarks are given in face bounding box coordinates (0-1 relative to the face box)
        // We need to transform them to image coordinates first, then to canvas coordinates

        // Draw yellow crosses at each landmark position
        if let leftEye = landmarks.leftEye {
            drawLandmarkCross(
                context: context,
                landmarkPoint: leftEye,
                faceBoundingBox: faceBoundingBox,
                canvasSize: canvasSize
            )
        }

        if let rightEye = landmarks.rightEye {
            drawLandmarkCross(
                context: context,
                landmarkPoint: rightEye,
                faceBoundingBox: faceBoundingBox,
                canvasSize: canvasSize
            )
        }

        if let nose = landmarks.nose {
            drawLandmarkCross(
                context: context,
                landmarkPoint: nose,
                faceBoundingBox: faceBoundingBox,
                canvasSize: canvasSize
            )
        }

        if let mouth = landmarks.mouth {
            drawLandmarkCross(
                context: context,
                landmarkPoint: mouth,
                faceBoundingBox: faceBoundingBox,
                canvasSize: canvasSize
            )
        }
    }

    private func drawLandmarkCross(
        context: GraphicsContext,
        landmarkPoint: CGPoint,
        faceBoundingBox: CGRect,
        canvasSize: CGSize
    ) {
        // Landmark point is relative to the face bounding box (0-1 coordinates within the box)
        // Convert to image coordinates (0-1 normalized to entire image)
        let imageX = faceBoundingBox.origin.x + landmarkPoint.x * faceBoundingBox.width
        let imageY = faceBoundingBox.origin.y + landmarkPoint.y * faceBoundingBox.height

        // Now convert from image coordinates (normalized, bottom-left) to canvas (pixels, top-left)
        let canvasX = imageX * canvasSize.width
        let canvasY = canvasSize.height - imageY * canvasSize.height

        let point = CGPoint(x: canvasX, y: canvasY)

        // Draw yellow X cross
        let crossSize: CGFloat = 10
        let lineWidth: CGFloat = 2

        var path = Path()

        // Diagonal line from top-left to bottom-right
        path.move(to: CGPoint(x: point.x - crossSize/2, y: point.y - crossSize/2))
        path.addLine(to: CGPoint(x: point.x + crossSize/2, y: point.y + crossSize/2))

        // Diagonal line from top-right to bottom-left
        path.move(to: CGPoint(x: point.x + crossSize/2, y: point.y - crossSize/2))
        path.addLine(to: CGPoint(x: point.x - crossSize/2, y: point.y + crossSize/2))

        context.stroke(
            path,
            with: .color(.yellow),
            lineWidth: lineWidth
        )
    }

}
