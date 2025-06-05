//
//  OCRViewModel.swift
//  Muorz'
//
//  Created by Muhammad Bilal on 12/05/25.
//

import Vision
import SwiftUI
import Foundation

@MainActor
class OCRViewModel: ObservableObject {
    @Published var ocrResults: [OCRResult] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var extractedText = ""
    @Published var processedMenu: MenuResponse?
    
    // MARK: - Multi-Photo Support
    @Published var capturedImages: [UIImage] = []
    @Published var combinedOCRText = ""
    @Published var currentProcessingIndex = 0
    @Published var individualOCRResults: [String] = []
    
    private let menuService: MenuServiceProtocol
    
    init(menuService: MenuServiceProtocol? = nil) {
        self.menuService = menuService ?? APIConfiguration.createMenuService()
    }

    // MARK: - Legacy Single Image Processing (Deprecated - use addImage + processAllImages instead)
    
    func processImage(_ image: UIImage) {
        print("⚠️ Using deprecated processImage method - consider using addImage + processAllImages")
        print("🔍 OCRViewModel.processImage called")
        print("   Current state: isProcessing=\(isProcessing), hasError=\(errorMessage != nil)")
        
        // For backwards compatibility, add image and process immediately
        addImage(image)
        processAllImages()
    }
    
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
    
    func retryProcessing() {
        guard !extractedText.isEmpty else { return }
        
        Task {
            await processExtractedText(extractedText)
        }
    }
    
    // MARK: - Multi-Photo Methods
    
    func addImage(_ image: UIImage) {
        capturedImages.append(image)
        print("📸 Added image \(capturedImages.count). Total images: \(capturedImages.count)")
    }
    
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
            
            // CRITICAL: Use revision 3 for maximum language support
            request.revision = VNRecognizeTextRequestRevision3
            
            // CRITICAL: Use accurate mode for non-Latin scripts (Chinese, Japanese, Korean, Arabic)
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // CRITICAL: Enable automatic language detection for unknown scripts
            request.automaticallyDetectsLanguage = true
            
            // Prioritized language list - order matters for ambiguous cases
            // First language determines which ML model is used in accurate mode
            request.recognitionLanguages = [
                // Asian scripts (require accurate mode + revision 3)
                "ja", "zh-Hans", "zh-Hant", "ko",
                // European languages
                "en", "fr", "es", "it", "de", "pt", "nl", 
                // Other scripts
                "ar", "he", "th", "vi", "tr", "el", "ru",
                // Nordic & Eastern European
                "sv", "da", "no", "fi", "cs", "hu", "pl"
            ]
            
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
