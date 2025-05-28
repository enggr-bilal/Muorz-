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
    
    private let menuService: MenuServiceProtocol
    
    init(menuService: MenuServiceProtocol? = nil) {
        self.menuService = menuService ?? APIConfiguration.createMenuService()
    }

    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Invalid image format"
            return
        }
        
        isProcessing = true
        errorMessage = nil

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "OCR failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.errorMessage = "No text found in image"
                    self.isProcessing = false
                }
                return
            }
            
            let extracted = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = extracted.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.ocrResults = extracted.map { OCRResult(text: $0) }
                self.extractedText = fullText
                
                // Process the extracted text through the API
                Task {
                    await self.processExtractedText(fullText)
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["fr", "en"] // Support French and English

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "OCR processing failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func processExtractedText(_ text: String) async {
        guard !text.isEmpty else {
            errorMessage = "No text extracted from image"
            isProcessing = false
            return
        }
        
        do {
            processedMenu = try await menuService.processOCRText(text)
            isProcessing = false
        } catch {
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
    }
    
    func retryProcessing() {
        guard !extractedText.isEmpty else { return }
        
        Task {
            await processExtractedText(extractedText)
        }
    }
}
