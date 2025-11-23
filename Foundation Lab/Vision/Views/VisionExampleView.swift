//
//  VisionExampleView.swift
//  Foundation Lab
//
//  Main interface for Vision image analysis example
//

import SwiftUI
import PhotosUI

struct VisionExampleView: View {
    @State private var viewModel = VisionExampleViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingOverlay = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analyze images using Apple's Vision framework to detect text, faces, objects, and more")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Image Selection
                if viewModel.selectedImage == nil {
                    ImagePickerView(selectedItem: $selectedItem) { item in
                        Task {
                            await viewModel.loadImage(from: item)
                        }
                    }
                    .padding()
                } else {
                    // Selected Image Preview
                    VStack(spacing: 12) {
                        if let image = viewModel.selectedImage {
                            if showingOverlay, let results = viewModel.analysisResults {
                                ImageOverlayView(image: image, results: results)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                            } else {
                                #if canImport(UIKit)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                #elseif canImport(AppKit)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                #endif
                            }
                        }

                        HStack {
                            if viewModel.analysisResults != nil {
                                Button {
                                    showingOverlay.toggle()
                                } label: {
                                    Label(
                                        showingOverlay ? "Hide Overlay" : "Show Overlay",
                                        systemImage: showingOverlay ? "eye.slash" : "eye"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }

                            Spacer()

                            Button("Clear", systemImage: "trash") {
                                viewModel.clearImage()
                                selectedItem = nil
                                showingOverlay = false
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding()
                }

                // Analysis Type Selection
                if viewModel.selectedImage != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analysis Types")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(VisionAnalysisType.allCases, id: \.self) { type in
                                AnalysisTypeButton(
                                    type: type,
                                    isSelected: viewModel.selectedAnalysisTypes.contains(type)
                                ) {
                                    viewModel.toggleAnalysisType(type)
                                }
                            }
                        }

                        Toggle("Include Confidence Scores", isOn: $viewModel.includeConfidence)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Analyze Button
                    Button {
                        Task {
                            await viewModel.analyzeImage()
                        }
                    } label: {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Analyze Image", systemImage: "viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isAnalyzing || viewModel.selectedAnalysisTypes.isEmpty)
                    .padding(.horizontal)
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // Results
                if let results = viewModel.analysisResults {
                    AnalysisResultView(
                        results: results,
                        includeConfidence: viewModel.includeConfidence
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Image Analysis")
    }
}

// MARK: - Analysis Type Button

struct AnalysisTypeButton: View {
    let type: VisionAnalysisType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(type.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        VisionExampleView()
    }
}
