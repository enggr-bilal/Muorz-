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
        // Debug logging
        print("🔍 MenuService.processOCRText called")
        print("   API Key configured: \(APIConfiguration.isGeminiAPIConfigured)")
        print("   Use Mock Service: \(APIConfiguration.useMockService)")
        print("   API Key length: \(apiKey.count) characters")
        print("   API Key starts with: \(apiKey.prefix(10))...")
        
        // Mock service is disabled in production
        if APIConfiguration.useMockService {
            print("⚠️ Mock service is enabled - throwing noAPIKey error")
            throw MenuServiceError.noAPIKey
        }
        
        guard APIConfiguration.isGeminiAPIConfigured else {
            // Throw error instead of returning sample data
            print("❌ API key validation failed - throwing noAPIKey error")
            throw MenuServiceError.noAPIKey
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
        // Get device language (for future localization, defaulting to English for now)
        let deviceLanguage = "en" // Locale.current.languageCode ?? "en"
        
        return """
        I will provide you with OCR text from a restaurant menu in any language.
        Parse it and return a JSON object with the following structure.
        
        IMPORTANT REQUIREMENTS:
        1. Sort categories in logical meal order: "starter", "main course", "dessert", "drink", "other"
        2. If a currency symbol (€, $, £, etc.) is visible on the menu, extract it ONCE at the top level
        3. Convert all prices to Double values (remove currency symbols, use dots for decimals)
        4. If no prices are found on the menu, omit "currency" and set all "price" to null
        5. Return results in English (target language: \(deviceLanguage))
        6. For nutrition_scores: if you can reasonably estimate nutritional content, provide [protein, fat, carbs] on 0-10 scale. If not possible (like for drinks, wines, simple items), set to null
        
        Expected JSON format:
        {
          "currency": "€" or null,
          "categories": [
            {
              "name": "starter",
              "dishes": [
                {
                  "original_name": "name in original language",
                  "translated_name": "name in English", 
                  "ingredients_en": ["ingredient1", "ingredient2"],
                  "price": 12.50 or null,
                  "nutrition_scores": [7, 5, 6] or null,
                  "dietary_tags": [1, 0, 0, 1]
                }
              ]
            }
          ]
        }
        
        CRITICAL: 
        - Categories must be in this exact order when present: "starter" → "main course" → "dessert" → "drink" → "other"
        - Prices must be Double numbers without currency symbols  
        - Currency should be extracted once at the top level if visible
        - nutrition_scores: [protein, fat, carbs] on 0-10 scale OR null if cannot estimate
        - dietary_tags: [vegetarian, vegan, gluten_free, dairy_free] as 0/1
        
        Return compact JSON only, no explanations.

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
    case noAPIKey
    
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
        case .noAPIKey:
            return "No Gemini API key configured. Please set your GEMINI_API_KEY in Xcode environment variables."
        }
    }
} 
