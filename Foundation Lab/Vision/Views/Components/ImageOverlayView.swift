//
//  ImageOverlayView.swift
//  Foundation Lab
//
//  Overlay view for displaying bounding boxes on images
//

import SwiftUI

struct ImageOverlayView: View {
    let image: PlatformImage
    let results: ImageFeatures

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #endif

                // Bounding boxes overlay
                Canvas { context, size in
                    let imageSize = image.size
                    let scale = min(size.width / imageSize.width, size.height / imageSize.height)
                    let scaledWidth = imageSize.width * scale
                    let scaledHeight = imageSize.height * scale
                    let offsetX = (size.width - scaledWidth) / 2
                    let offsetY = (size.height - scaledHeight) / 2

                    // Draw text bounding boxes
                    for textFeature in results.textFeatures {
                        drawBoundingBox(
                            context: context,
                            box: textFeature.boundingBox,
                            color: .blue,
                            imageSize: imageSize,
                            scaledWidth: scaledWidth,
                            scaledHeight: scaledHeight,
                            offsetX: offsetX,
                            offsetY: offsetY
                        )
                    }

                    // Draw face bounding boxes
                    for faceFeature in results.faceFeatures {
                        drawBoundingBox(
                            context: context,
                            box: faceFeature.boundingBox,
                            color: .green,
                            imageSize: imageSize,
                            scaledWidth: scaledWidth,
                            scaledHeight: scaledHeight,
                            offsetX: offsetX,
                            offsetY: offsetY
                        )
                    }

                    // Draw barcode bounding boxes
                    for barcodeFeature in results.barcodeFeatures {
                        drawBoundingBox(
                            context: context,
                            box: barcodeFeature.boundingBox,
                            color: .purple,
                            imageSize: imageSize,
                            scaledWidth: scaledWidth,
                            scaledHeight: scaledHeight,
                            offsetX: offsetX,
                            offsetY: offsetY
                        )
                    }

                    // Draw saliency bounding boxes
                    for saliencyFeature in results.saliencyFeatures {
                        for box in saliencyFeature.boundingBoxes {
                            drawBoundingBox(
                                context: context,
                                box: box,
                                color: .orange,
                                imageSize: imageSize,
                                scaledWidth: scaledWidth,
                                scaledHeight: scaledHeight,
                                offsetX: offsetX,
                                offsetY: offsetY
                            )
                        }
                    }
                }
            }
        }
    }

    private func drawBoundingBox(
        context: GraphicsContext,
        box: CGRect,
        color: Color,
        imageSize: CGSize,
        scaledWidth: CGFloat,
        scaledHeight: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) {
        // Vision uses bottom-left origin, SwiftUI uses top-left
        // Convert coordinates
        let x = box.origin.x * scaledWidth + offsetX
        let y = (1 - box.origin.y - box.height) * scaledHeight + offsetY
        let width = box.width * scaledWidth
        let height = box.height * scaledHeight

        let rect = CGRect(x: x, y: y, width: width, height: height)

        var path = Path()
        path.addRect(rect)

        context.stroke(
            path,
            with: .color(color),
            lineWidth: 2
        )
    }
}
