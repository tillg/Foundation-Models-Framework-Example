//
//  ImagePickerView.swift
//  Foundation Lab
//
//  Image selection component for Vision analysis
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    let onImageSelected: (PhotosPickerItem) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Select Image", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .onChange(of: selectedItem) { oldValue, newValue in
            if let item = newValue {
                onImageSelected(item)
            }
        }
    }
}
