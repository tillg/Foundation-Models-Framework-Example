//
//  PlatformImage.swift
//  Foundation Lab
//
//  Cross-platform image type alias and extensions
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Platform Extensions

#if canImport(AppKit)
extension NSImage {
    /// Provides jpegData method for macOS compatibility with iOS UIImage
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapImage.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}
#endif
