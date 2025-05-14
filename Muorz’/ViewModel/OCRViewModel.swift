//
//  OCRViewModel.swift
//  Muorz’
//
//  Created by Muhammad Bilal on 12/05/25.
//

import Vision
import SwiftUI

class OCRViewModel: ObservableObject {
    @Published var ocrResults: [OCRResult] = []

    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let extracted = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                self?.ocrResults = extracted.map { OCRResult(text: $0) }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            try? requestHandler.perform([request])
        }
    }
}
