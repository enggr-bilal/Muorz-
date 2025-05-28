//
//  MenuService.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import Combine

// MARK: - Menu Service Protocol

protocol MenuServiceProtocol {
    func processOCRText(_ text: String) async throws -> MenuResponse
    func loadSampleMenu() -> [MenuItem]
}

// MARK: - Menu Service Implementation

class MenuService: MenuServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    
    // MARK: - Initialization
    
    init(apiKey: String = "", baseURL: String = "", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - API Methods
    
    /// Process OCR text through API to get structured menu data
    func processOCRText(_ text: String) async throws -> MenuResponse {
        // TODO: Implement actual API call when ready
        // For now, return sample data for development
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return sample data wrapped in MenuResponse
        return MenuResponse(
            menuItems: MenuItem.sampleData,
            restaurantInfo: RestaurantInfo(
                name: "Sample Restaurant",
                cuisine: "Italian",
                location: "Sample Location"
            )
        )
    }
    
    /// Load sample menu data for development/testing
    func loadSampleMenu() -> [MenuItem] {
        return MenuItem.sampleData
    }
    
    // MARK: - Private API Methods (for future implementation)
    
    private func buildAPIRequest(for ocrText: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/process-menu") else {
            throw MenuServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = APIRequest(ocrText: ocrText)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return request
    }
    
    private func performAPICall(_ request: URLRequest) async throws -> MenuResponse {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MenuServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw MenuServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(MenuResponse.self, from: data)
        } catch {
            throw MenuServiceError.decodingError(error)
        }
    }
}

// MARK: - API Request/Response Models

private struct APIRequest: Codable {
    let ocrText: String
    let language: String = "fr" // Default to French
    let outputLanguage: String = "en" // Default to English output
    
    enum CodingKeys: String, CodingKey {
        case ocrText = "ocr_text"
        case language
        case outputLanguage = "output_language"
    }
}

// MARK: - Error Handling

enum MenuServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Service for Development

class MockMenuService: MenuServiceProtocol {
    func processOCRText(_ text: String) async throws -> MenuResponse {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return MenuResponse(
            menuItems: MenuItem.sampleData,
            restaurantInfo: RestaurantInfo(
                name: "Mock Restaurant",
                cuisine: "Italian",
                location: "Mock Location"
            )
        )
    }
    
    func loadSampleMenu() -> [MenuItem] {
        return MenuItem.sampleData
    }
} 