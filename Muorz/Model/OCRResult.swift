//
//  OCRResult.swift
//  Muorz
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

/// Represents the result of OCR text recognition from a menu image
/// Contains extracted text and metadata about the recognition process
struct OCRResult: Identifiable, Codable {
    /// Unique identifier for this OCR result
    let id = UUID()
    
    /// The extracted text content from the image
    let extractedText: String
    
    /// Confidence level of the OCR recognition (0.0 to 1.0)
    let confidence: Double
    
    /// Timestamp when the OCR was performed
    let timestamp: Date
    
    /// Optional metadata about the source image
    let imageMetadata: ImageMetadata?
    
    // MARK: - Initializers
    
    /// Standard initializer for OCR results
    /// - Parameters:
    ///   - extractedText: The text extracted from the image
    ///   - confidence: Confidence level of the recognition
    ///   - imageMetadata: Optional metadata about the source image
    init(extractedText: String, confidence: Double = 1.0, imageMetadata: ImageMetadata? = nil) {
        self.extractedText = extractedText
        self.confidence = confidence
        self.timestamp = Date()
        self.imageMetadata = imageMetadata
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the OCR result has high confidence
    var isHighConfidence: Bool {
        confidence >= 0.8
    }
    
    /// Returns true if the extracted text is not empty
    var hasText: Bool {
        !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns the word count of extracted text
    var wordCount: Int {
        extractedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

/// Metadata about the source image used for OCR
struct ImageMetadata: Codable {
    /// Width of the source image in pixels
    let width: Int
    
    /// Height of the source image in pixels
    let height: Int
    
    /// File size of the image in bytes
    let fileSize: Int?
    
    /// Image format (e.g., "JPEG", "PNG")
    let format: String?
    
    /// Computed aspect ratio of the image
    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }
}

