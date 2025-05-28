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

// MARK: - Gemini API Service Implementation

class MenuService: MenuServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let apiKey: String
    private var session: URLSession
    
    // MARK: - Initialization
    
    init(apiKey: String = APIConfiguration.geminiAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        
        // Configure session timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.requestTimeout
        config.timeoutIntervalForResource = APIConfiguration.requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// Process OCR text through Gemini API to get structured menu data
    func processOCRText(_ text: String) async throws -> MenuResponse {
        // Check if we should use mock service
        if APIConfiguration.useMockService {
            print("🧪 Using MockMenuService (development mode)")
            let mockService = MockMenuService()
            return try await mockService.processOCRText(text)
        }
        
        guard APIConfiguration.isGeminiAPIConfigured else {
            // Return sample data if no API key is configured
            print("⚠️ No Gemini API key configured, using sample data")
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API delay
            return MenuResponse(
                menuItems: MenuItem.sampleData,
                restaurantInfo: RestaurantInfo(
                    name: "Sample Restaurant",
                    cuisine: "Italian",
                    location: "Sample Location"
                )
            )
        }
        
        var lastError: Error?
        
        // Retry logic
        for attempt in 1...APIConfiguration.maxRetries {
            do {
                print("🚀 Attempting Gemini API call (attempt \(attempt)/\(APIConfiguration.maxRetries))")
                
                let request = try buildGeminiAPIRequest(for: text)
                APIConfiguration.logAPIRequest(request)
                
                let geminiResponse = try await performGeminiAPICall(request)
                
                // Convert Gemini response to internal format
                let menuResponse = MenuResponse(from: geminiResponse)
                
                print("✅ Successfully processed menu with \(menuResponse.menuItems.count) items")
                return menuResponse
                
            } catch {
                lastError = error
                print("❌ Gemini API Error (attempt \(attempt)): \(error)")
                
                // Don't retry on certain errors
                if case MenuServiceError.geminiError = error {
                    break
                }
                
                // Wait before retrying (exponential backoff)
                if attempt < APIConfiguration.maxRetries {
                    let delay = TimeInterval(attempt * attempt) // 1s, 4s, 9s...
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? MenuServiceError.networkError(NSError(domain: "MenuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
    }
    
    /// Load sample menu data for development/testing
    func loadSampleMenu() -> [MenuItem] {
        return MenuItem.sampleData
    }
    
    // MARK: - Private Gemini API Methods
    
    private func buildGeminiAPIRequest(for ocrText: String) throws -> URLRequest {
        guard let url = URL(string: "\(APIConfiguration.geminiBaseURL)?key=\(apiKey)") else {
            throw MenuServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfiguration.requestTimeout
        
        let prompt = buildMenuParsingPrompt(ocrText: ocrText)
        let requestBody = GeminiAPIRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return request
    }
    
    private func performGeminiAPICall(_ request: URLRequest) async throws -> GeminiMenuResponse {
        let (data, response) = try await session.data(for: request)
        
        APIConfiguration.logAPIResponse(data, response, nil)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MenuServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            // Try to decode error response
            if let errorData = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw MenuServiceError.geminiError(errorData.error.message)
            }
            throw MenuServiceError.serverError(httpResponse.statusCode)
        }
        
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
            
            // Extract JSON from the text response
            guard let candidate = geminiResponse.candidates.first,
                  let part = candidate.content.parts.first else {
                throw MenuServiceError.decodingError(NSError(domain: "MenuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No content in Gemini response"]))
            }
            
            // Parse the JSON from the text response
            let jsonText = part.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove potential markdown code blocks
            let cleanedJsonText = jsonText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedJsonText.data(using: .utf8) else {
                throw MenuServiceError.decodingError(NSError(domain: "MenuService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON text from Gemini"]))
            }
            
            if APIConfiguration.enableAPILogging {
                print("📄 Parsed JSON: \(cleanedJsonText.prefix(500))...")
            }
            
            return try JSONDecoder().decode(GeminiMenuResponse.self, from: jsonData)
            
        } catch {
            print("❌ Decoding error: \(error)")
            if let data = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(data.prefix(1000))...")
            }
            throw MenuServiceError.decodingError(error)
        }
    }
    
    private func buildMenuParsingPrompt(ocrText: String) -> String {
        return """
        I will provide you with OCR text from a restaurant menu in any language.
        Parse it and return a JSON array of dish categories.
        Sort categories in a meaningful meal order (e.g. starter, main course, dessert, drinks, etc.).
        Each category object must have:
        "ctg": the category name in English
        "dsh": a list of dish objects
        Each dish object must contain:
        "nme": name in original language
        "tr_nme": name in English
        "ingr": list of 3–6 ingredients in English (inferred if needed)
        "n_scr": list of 3 integers [protein, fat, carbs] on a 0–10 scale
        "tgs": list of 4 booleans (0 or 1) in order [vegetarian, vegan, gluten_free, dairy_free]
        "prc": price as written in the original menu
        Return compact JSON only, with no extra text or explanations.
        Use consistent field order and avoid repeating field names inside arrays.

        OCR Text:
        \(ocrText)
        """
    }
}

// MARK: - Gemini API Request/Response Models

private struct GeminiAPIRequest: Codable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Codable {
    let content: GeminiContent
}

private struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

private struct GeminiError: Codable {
    let message: String
    let code: Int
}

// MARK: - Error Handling

enum MenuServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case geminiError(String)
    
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
        case .geminiError(let message):
            return "Gemini API error: \(message)"
        }
    }
}

// MARK: - Mock Service for Development

class MockMenuService: MenuServiceProtocol {
    func processOCRText(_ text: String) async throws -> MenuResponse {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Simulate API response with sample data
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
