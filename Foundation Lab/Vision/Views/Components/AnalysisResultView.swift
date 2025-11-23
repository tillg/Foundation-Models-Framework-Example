//
//  AnalysisResultView.swift
//  Foundation Lab
//
//  Displays Vision analysis results
//

import SwiftUI

struct AnalysisResultView: View {
    let results: ImageFeatures
    let includeConfidence: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary Card
                SummaryCard(results: results)

                // Text Results
                if !results.textFeatures.isEmpty {
                    ResultSection(
                        title: "Text Recognition",
                        icon: "doc.text.viewfinder",
                        count: results.textFeatures.count
                    ) {
                        ForEach(results.textFeatures) { feature in
                            TextResultRow(feature: feature, showConfidence: includeConfidence)
                        }
                    }
                }

                // Face Results
                if !results.faceFeatures.isEmpty {
                    ResultSection(
                        title: "Face Detection",
                        icon: "face.smiling",
                        count: results.faceFeatures.count
                    ) {
                        ForEach(results.faceFeatures) { feature in
                            FaceResultRow(feature: feature, showConfidence: includeConfidence)
                        }
                    }
                }

                // Object Results
                if !results.objectFeatures.isEmpty {
                    ResultSection(
                        title: "Object & Scene Classification",
                        icon: "cube.box",
                        count: results.objectFeatures.count
                    ) {
                        ForEach(results.objectFeatures.prefix(10)) { feature in
                            ObjectResultRow(feature: feature, showConfidence: includeConfidence)
                        }
                    }
                }

                // Barcode Results
                if !results.barcodeFeatures.isEmpty {
                    ResultSection(
                        title: "Barcode Detection",
                        icon: "barcode.viewfinder",
                        count: results.barcodeFeatures.count
                    ) {
                        ForEach(results.barcodeFeatures) { feature in
                            BarcodeResultRow(feature: feature)
                        }
                    }
                }

                // Saliency Results
                if !results.saliencyFeatures.isEmpty {
                    ResultSection(
                        title: "Saliency Analysis",
                        icon: "eye",
                        count: results.saliencyFeatures.reduce(0) { $0 + $1.regionCount }
                    ) {
                        ForEach(results.saliencyFeatures) { feature in
                            SaliencyResultRow(feature: feature)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let results: ImageFeatures

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Complete")
                .font(.headline)

            Text("Found \(results.resultCount) item(s) across \(activeCategories) categor\(activeCategories == 1 ? "y" : "ies")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var activeCategories: Int {
        var count = 0
        if !results.textFeatures.isEmpty { count += 1 }
        if !results.faceFeatures.isEmpty { count += 1 }
        if !results.objectFeatures.isEmpty { count += 1 }
        if !results.barcodeFeatures.isEmpty { count += 1 }
        if !results.saliencyFeatures.isEmpty { count += 1 }
        return count
    }
}

struct ResultSection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TextResultRow: View {
    let feature: TextFeature
    let showConfidence: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\"\(feature.text)\"")
                    .font(.body)

                Spacer()

                if let priority = feature.priority {
                    Text("P\(priority)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(for: priority))
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 12) {
                if let pointSize = feature.estimatedPointSize {
                    Text("~\(Int(pointSize))pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if showConfidence {
                    Text("\(feature.confidencePercent)% confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .blue
        default: return .gray
        }
    }
}

struct FaceResultRow: View {
    let feature: FaceFeature
    let showConfidence: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Face detected")
                .font(.body)

            if let landmarks = feature.landmarks {
                let parts = [
                    landmarks.leftEye != nil ? "left eye" : nil,
                    landmarks.rightEye != nil ? "right eye" : nil,
                    landmarks.nose != nil ? "nose" : nil,
                    landmarks.mouth != nil ? "mouth" : nil
                ].compactMap { $0 }

                if !parts.isEmpty {
                    Text("Landmarks: \(parts.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if showConfidence, let qualityPercent = feature.qualityPercent {
                Text("Quality: \(qualityPercent)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ObjectResultRow: View {
    let feature: ObjectFeature
    let showConfidence: Bool

    var body: some View {
        HStack {
            Text(feature.displayName)
                .font(.body)

            Spacer()

            if showConfidence {
                Text("\(feature.confidencePercent)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct BarcodeResultRow: View {
    let feature: BarcodeFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(feature.payload)
                .font(.body)
                .monospaced()

            Text(feature.symbologyDisplayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SaliencyResultRow: View {
    let feature: SaliencyFeature

    var body: some View {
        Text("Detected \(feature.regionCount) prominent region(s)")
            .font(.body)
    }
}
