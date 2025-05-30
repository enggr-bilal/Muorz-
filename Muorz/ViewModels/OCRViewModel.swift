//
//  OCRViewModel.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Vision
import SwiftUI
import Foundation

/// ViewModel responsible for managing OCR (Optical Character Recognition) operations
/// Handles text extraction from images and processing through menu service
@MainActor
class OCRViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Legacy OCR results (deprecated - use processedMenu instead)
    @Published var ocrResults: [OCRResult] = []
    
    /// Indicates if OCR processing is currently in progress
    @Published var isProcessing = false
    
    /// Error message from the last failed operation
    @Published var errorMessage: String?
    
    /// Raw extracted text from the last OCR operation
    @Published var extractedText = ""
    
    /// Processed menu data ready for display
    @Published var processedMenu: MenuResponse?
    
    // MARK: - Multi-Photo Support Properties
    
    /// Array of captured images awaiting processing
    @Published var capturedImages: [UIImage] = []
    
    /// Combined OCR text from all processed images
    @Published var combinedOCRText = ""
    
    /// Index of currently processing image (for progress tracking)
    @Published var currentProcessingIndex = 0
    
    /// Individual OCR results for each processed image
    @Published var individualOCRResults: [String] = []
    
    // MARK: - Dependencies
    
    /// Service responsible for processing OCR text into menu data
    private let menuService: MenuServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the OCR view model with optional menu service dependency injection
    /// - Parameter menuService: Optional menu service (uses default if nil)
    init(menuService: MenuServiceProtocol? = nil) {
        self.menuService = menuService ?? APIConfiguration.createMenuService()
    }

    // MARK: - Legacy Single Image Processing
    
    /// Processes a single image for OCR (deprecated method)
    /// - Parameter image: UIImage to process
    /// - Note: This method is deprecated. Use addImage() + processAllImages() instead
    func processImage(_ image: UIImage) {
        print("⚠️ Using deprecated processImage method - consider using addImage + processAllImages")
        print("🔍 OCRViewModel.processImage called")
        print("   Current state: isProcessing=\(isProcessing), hasError=\(errorMessage != nil)")
        
        // For backwards compatibility, add image and process immediately
        addImage(image)
        processAllImages()
    }
    
    // MARK: - Multi-Photo Processing Methods
    
    /// Adds an image to the processing queue
    /// - Parameter image: UIImage to add for processing
    func addImage(_ image: UIImage) {
        capturedImages.append(image)
        print("📸 Added image \(capturedImages.count). Total images: \(capturedImages.count)")
    }
    
    /// Removes an image from the processing queue
    /// - Parameter index: Index of the image to remove
    func removeImage(at index: Int) {
        guard index < capturedImages.count else { return }
        capturedImages.remove(at: index)
        
        // Also remove corresponding OCR result if it exists
        if index < individualOCRResults.count {
            individualOCRResults.remove(at: index)
        }
        
        print("🗑️ Removed image at index \(index). Remaining: \(capturedImages.count)")
        updateCombinedOCRText()
    }
    
    /// Processes all captured images sequentially
    /// Performs OCR on each image and then processes the combined text through the menu service
    func processAllImages() {
        guard !capturedImages.isEmpty else {
            errorMessage = "No images to process"
            return
        }
        
        print("🔄 Starting processing of \(capturedImages.count) images")
        isProcessing = true
        errorMessage = nil
        currentProcessingIndex = 0
        individualOCRResults = []
        
        Task {
            await processImagesSequentially()
        }
    }
    
    // MARK: - State Management
    
    /// Clears all OCR results and resets the view model state
    func clearResults() {
        ocrResults.removeAll()
        extractedText = ""
        processedMenu = nil
        errorMessage = nil
        isProcessing = false
        
        // Clear multi-photo data
        capturedImages.removeAll()
        combinedOCRText = ""
        currentProcessingIndex = 0
        individualOCRResults.removeAll()
        
        print("🧹 Cleared all OCR results and captured images")
    }
    
    /// Retries processing with the last extracted text
    func retryProcessing() {
        guard !extractedText.isEmpty else { return }
        
        Task {
            await processExtractedText(extractedText)
        }
    }
    
    // MARK: - Private Processing Methods
    
    /// Processes all images sequentially using OCR
    private func processImagesSequentially() async {
        for (index, image) in capturedImages.enumerated() {
            currentProcessingIndex = index
            print("🔍 Processing image \(index + 1)/\(capturedImages.count)")
            
            await processIndividualImage(image, at: index)
        }
        
        // Combine all OCR results
        updateCombinedOCRText()
        
        // Process combined text through API
        if !combinedOCRText.isEmpty {
            await processExtractedText(combinedOCRText)
        } else {
            errorMessage = "No text extracted from any images"
            isProcessing = false
        }
    }
    
    /// Performs OCR on a single image
    /// - Parameters:
    ///   - image: UIImage to process
    ///   - index: Index of the image in the processing queue
    private func processIndividualImage(_ image: UIImage, at index: Int) async {
        guard let cgImage = image.cgImage else {
            print("❌ Invalid image format at index \(index)")
            individualOCRResults.append("")
            return
        }
        
        return await withCheckedContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { 
                    continuation.resume()
                    return 
                }
                
                if let error = error {
                    print("❌ OCR failed for image \(index): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.individualOCRResults.append("")
                    }
                    continuation.resume()
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ No text found in image \(index)")
                    DispatchQueue.main.async {
                        self.individualOCRResults.append("")
                    }
                    continuation.resume()
                    return
                }
                
                let extracted = observations.compactMap { $0.topCandidates(1).first?.string }
                let imageText = extracted.joined(separator: "\n")
                
                DispatchQueue.main.async {
                    self.individualOCRResults.append(imageText)
                    print("✅ Extracted \(imageText.count) characters from image \(index + 1)")
                }
                continuation.resume()
            }
            
            // Configure OCR request for optimal menu text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["fr", "en"] // Support French and English
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("❌ OCR processing failed for image \(index): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.individualOCRResults.append("")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Processes extracted text through the menu service
    /// - Parameter text: Raw OCR text to process
    private func processExtractedText(_ text: String) async {
        print("🚀 OCRViewModel.processExtractedText called")
        print("   Text length: \(text.count) characters")
        print("   First 100 chars: \(text.prefix(100))...")
        
        guard !text.isEmpty else {
            print("❌ No text extracted from image")
            errorMessage = "No text extracted from image"
            isProcessing = false
            return
        }
        
        do {
            print("📡 Calling menuService.processOCRText...")
            processedMenu = try await menuService.processOCRText(text)
            print("✅ Menu processing completed successfully")
            isProcessing = false
        } catch {
            print("❌ Menu processing failed: \(error)")
            errorMessage = error.localizedDescription
            isProcessing = false
        }
    }
    
    /// Updates the combined OCR text from all individual results
    private func updateCombinedOCRText() {
        combinedOCRText = individualOCRResults
            .enumerated()
            .map { index, text in
                guard !text.isEmpty else { return "" }
                return "=== PAGE \(index + 1) ===\n\(text)\n"
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        extractedText = combinedOCRText
        print("📄 Combined OCR text: \(combinedOCRText.count) characters from \(individualOCRResults.filter { !$0.isEmpty }.count) pages")
    }
}
