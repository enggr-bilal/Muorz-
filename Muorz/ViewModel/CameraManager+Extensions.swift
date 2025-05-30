import UIKit
import SwiftUI

extension CameraManager {
    
    // MARK: - Image Processing
    
    /// Combines multiple captured images into a single image for OCR processing
    func combineImagesForOCR() -> UIImage? {
        guard !capturedImages.isEmpty else { return nil }
        
        // If only one image, return it directly
        if capturedImages.count == 1 {
            return capturedImages.first
        }
        
        // Combine multiple images vertically
        return combineImagesVertically(capturedImages)
    }
    
    /// Combines an array of images vertically
    private func combineImagesVertically(_ images: [UIImage]) -> UIImage? {
        guard !images.isEmpty else { return nil }
        
        // Calculate total height and max width
        let totalHeight = images.reduce(0) { $0 + $1.size.height }
        let maxWidth = images.map { $0.size.width }.max() ?? 0
        
        let size = CGSize(width: maxWidth, height: totalHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        var currentY: CGFloat = 0
        
        for image in images {
            let x = (maxWidth - image.size.width) / 2 // Center horizontally
            image.draw(at: CGPoint(x: x, y: currentY))
            currentY += image.size.height
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Image Quality Enhancement
    
    /// Enhances image quality for better OCR results
    func enhanceImageForOCR(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        // Check if image is already at good size for OCR
        let currentSize = image.size
        let maxDimension = max(currentSize.width, currentSize.height)
        
        // If image is already in optimal range, return as is
        if maxDimension >= 1024 && maxDimension <= 2048 {
            return image
        }
        
        // Calculate optimal scale factor
        let targetMaxDimension: CGFloat = 1536 // Sweet spot for OCR
        let scale = targetMaxDimension / maxDimension
        
        let newSize = CGSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0) // Force scale to 1.0
        defer { UIGraphicsEndImageContext() }
        
        // Draw the image with optimal resolution
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    // MARK: - Image Validation
    
    /// Validates if an image is suitable for OCR processing
    func validateImageForOCR(_ image: UIImage) -> ImageValidationResult {
        let size = image.size
        let minSize: CGFloat = 640 // Apple recommended minimum
        let maxSize: CGFloat = 4096 // Apple recommended maximum
        
        // Check size constraints based on Apple Vision documentation
        if size.width < minSize || size.height < minSize {
            return .tooSmall
        }
        
        if size.width > maxSize || size.height > maxSize {
            return .tooLarge
        }
        
        // Check aspect ratio (very wide or very tall images might be problematic)
        let aspectRatio = max(size.width, size.height) / min(size.width, size.height)
        if aspectRatio > 8 { // More permissive aspect ratio
            return .badAspectRatio
        }
        
        return .valid
    }
    
    // MARK: - Storage Management
    
    /// Gets the estimated memory usage of captured images
    var estimatedMemoryUsage: String {
        let totalPixels = capturedImages.reduce(0) { total, image in
            total + Int(image.size.width * image.size.height)
        }
        
        // Estimate 4 bytes per pixel (RGBA)
        let bytesUsed = totalPixels * 4
        let mbUsed = Double(bytesUsed) / (1024 * 1024)
        
        return String(format: "%.1f MB", mbUsed)
    }
    
    /// Compresses images if memory usage is too high
    func optimizeImagesIfNeeded() {
        let maxMemoryMB: Double = 30.0 // Reduced memory limit for better performance
        let currentUsageMB = Double(capturedImages.reduce(0) { total, image in
            total + Int(image.size.width * image.size.height * 4)
        }) / (1024 * 1024)
        
        if currentUsageMB > maxMemoryMB {
            capturedImages = capturedImages.compactMap { image in
                return compressImage(image, quality: 0.8) // Higher quality compression
            }
        }
    }
    
    /// Compresses a single image
    private func compressImage(_ image: UIImage, quality: CGFloat) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: quality),
              let compressedImage = UIImage(data: data) else {
            return image
        }
        return compressedImage
    }
}

// MARK: - Supporting Enums

enum ImageValidationResult {
    case valid
    case tooSmall
    case tooLarge
    case badAspectRatio
    
    var message: String {
        switch self {
        case .valid:
            return "Image is valid for processing"
        case .tooSmall:
            return "Image is too small. Please capture a clearer photo."
        case .tooLarge:
            return "Image is too large. Please try a smaller photo."
        case .badAspectRatio:
            return "Image aspect ratio is not suitable. Please capture a more balanced photo."
        }
    }
}

// MARK: - UI Haptics Extension

extension CameraManager {
    
    /// Provides haptic feedback for various camera actions
    func performHapticFeedback(for action: CameraAction) {
        let impactFeedback = UIImpactFeedbackGenerator()
        let notificationFeedback = UINotificationFeedbackGenerator()
        
        switch action {
        case .capture:
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        case .flashToggle:
            impactFeedback.prepare()
            impactFeedback.impactOccurred(intensity: 0.5)
        case .success:
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.success)
        case .error:
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.error)
        case .warning:
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
}

enum CameraAction {
    case capture
    case flashToggle
    case success
    case error
    case warning
} 