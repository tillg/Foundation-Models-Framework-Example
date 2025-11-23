//
//  FullscreenImageView.swift
//  Foundation Lab
//
//  Fullscreen image viewer with zoom and pan gestures
//

import SwiftUI

struct FullscreenImageView: View {
    let image: PlatformImage
    let results: ImageFeatures
    let showOverlay: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        #if os(iOS)
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // Image with gestures
            imageWithOverlay
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .gesture(dragGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        resetZoom()
                    }
                }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        #elseif os(macOS)
        VStack(spacing: 0) {
            // Image with gestures
            imageWithOverlay
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .gesture(dragGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        resetZoom()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        resetZoom()
                    }
                } label: {
                    Label("Reset Zoom", systemImage: "arrow.counterclockwise")
                }
                .disabled(scale == minScale && offset == .zero)
            }
        }
        #endif
    }

    @ViewBuilder
    private var imageWithOverlay: some View {
        if showOverlay {
            ImageOverlayView(image: image, results: results)
        } else {
            #if canImport(UIKit)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            #elseif canImport(AppKit)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
            #endif
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // Calculate new scale with bounds
                let newScale = scale * delta
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0

                // Snap back to min scale if close
                if scale < minScale * 1.1 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = minScale
                        offset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow dragging when zoomed in
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func resetZoom() {
        scale = minScale
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
}
