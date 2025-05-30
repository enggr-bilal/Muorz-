//
//  MenuService.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import Combine

// MARK: - Service Protocol

/// Protocol defining the interface for menu processing services
/// Allows for dependency injection and testing with mock implementations
protocol MenuServiceProtocol {
    /// Processes OCR text and returns structured menu data
    /// - Parameter text: Raw OCR text from menu images
    /// - Returns: Structured menu response with items and restaurant info
    /// - Throws: MenuServiceError for various failure cases
    func processOCRText(_ text: String) async throws -> MenuResponse
}

// MARK: - Gemini API Service Implementation

/// Service responsible for processing OCR text through Google's Gemini API
/// Converts raw menu text into structured menu data with items, categories, and metadata
class MenuService: MenuServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    /// API key for Gemini service authentication
    private let apiKey: String
    
    /// URL session for network requests with custom configuration
    private var session: URLSession
    
    // MARK: - Initialization
    
    /// Initializes the menu service with API configuration
    /// - Parameters:
    ///   - apiKey: Gemini API key (defaults to configuration value)
    ///   - session: URL session for requests (defaults to shared session)
    init(apiKey: String = APIConfiguration.geminiAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        
        // Configure session with appropriate timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.requestTimeout
        config.timeoutIntervalForResource = APIConfiguration.requestTimeout * 2
        self.session = URLSession(configuration: config)
        
        print("🔧 MenuService initialized with API key length: \(apiKey.count)")
    }
    
    // MARK: - Public API Methods
    
    /// Processes OCR text through Gemini API to extract structured menu data
    /// Implements retry logic with exponential backoff for reliability
    /// - Parameter text: Raw OCR text extracted from menu images
    /// - Returns: Structured MenuResponse containing menu items and restaurant info
    /// - Throws: MenuServiceError for various failure scenarios
    func processOCRText(_ text: String) async throws -> MenuResponse {
        print("🔍 MenuService.processOCRText called")
        print("   API Key configured: \(APIConfiguration.isGeminiAPIConfigured)")
        print("   Use Mock Service: \(APIConfiguration.useMockService)")
        print("   Text length: \(text.count) characters")
        
        // Validate API configuration
        try validateAPIConfiguration()
        
        var lastError: Error?
        
        // Implement retry logic with exponential backoff
        for attempt in 1...APIConfiguration.maxRetries {
            do {
                print("🚀 Attempting Gemini API call (attempt \(attempt)/\(APIConfiguration.maxRetries))")
                
                let request = try buildAPIRequest(for: text)
                let geminiResponse = try await performAPICall(request)
                let menuResponse = MenuResponse(from: geminiResponse)
                
                print("✅ Successfully processed menu with \(menuResponse.menuItems.count) items")
                return menuResponse
                
            } catch {
                lastError = error
                print("❌ Gemini API Error (attempt \(attempt)): \(error)")
                
                // Don't retry on certain unrecoverable errors
                if case MenuServiceError.geminiError = error,
                   case MenuServiceError.noAPIKey = error {
                    break
                }
                
                // Wait before retrying with exponential backoff
                if attempt < APIConfiguration.maxRetries {
                    let delay = TimeInterval(attempt * attempt) // 1s, 4s, 9s...
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    print("⏳ Waiting \(delay)s before retry...")
                }
            }
        }
        
        // Throw the last encountered error
        throw lastError ?? MenuServiceError.networkError(
            NSError(domain: "MenuService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unknown error after \(APIConfiguration.maxRetries) attempts"
            ])
        )
    }
    
    // MARK: - Private API Methods
    
    /// Validates that the API is properly configured
    /// - Throws: MenuServiceError.noAPIKey if configuration is invalid
    private func validateAPIConfiguration() throws {
        // Mock service is disabled in production
        if APIConfiguration.useMockService {
            print("⚠️ Mock service is enabled - throwing noAPIKey error")
            throw MenuServiceError.noAPIKey
        }
        
        guard APIConfiguration.isGeminiAPIConfigured else {
            print("❌ API key validation failed - throwing noAPIKey error")
            throw MenuServiceError.noAPIKey
        }
    }
    
    /// Builds a properly formatted API request for the Gemini service
    /// - Parameter ocrText: Raw OCR text to process
    /// - Returns: Configured URLRequest ready for execution
    /// - Throws: MenuServiceError.invalidURL if URL construction fails
    private func buildAPIRequest(for ocrText: String) throws -> URLRequest {
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
                    parts: [GeminiPart(text: prompt)]
                )
            ]
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        APIConfiguration.logAPIRequest(request)
        return request
    }
    
    /// Performs the actual API call and handles response processing
    /// - Parameter request: Configured URLRequest to execute
    /// - Returns: Parsed GeminiMenuResponse from the API
    /// - Throws: Various MenuServiceError cases for different failure scenarios
    private func performAPICall(_ request: URLRequest) async throws -> GeminiMenuResponse {
        let (data, response) = try await session.data(for: request)
        
        APIConfiguration.logAPIResponse(data, response, nil)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MenuServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            // Try to decode error response for better error messages
            if let errorData = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw MenuServiceError.geminiError(errorData.error.message)
            }
            throw MenuServiceError.serverError(httpResponse.statusCode)
        }
        
        return try parseGeminiResponse(from: data)
    }
    
    /// Parses the Gemini API response and extracts menu data
    /// - Parameter data: Raw response data from the API
    /// - Returns: Parsed GeminiMenuResponse
    /// - Throws: MenuServiceError.decodingError if parsing fails
    private func parseGeminiResponse(from data: Data) throws -> GeminiMenuResponse {
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)
            
            // Extract JSON content from the text response
            guard let candidate = geminiResponse.candidates.first,
                  let part = candidate.content.parts.first else {
                throw MenuServiceError.decodingError(
                    NSError(domain: "MenuService", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "No content in Gemini response"
                    ])
                )
            }
            
            // Clean and parse the JSON from the text response
            let jsonText = cleanJSONText(part.text)
            
            guard let jsonData = jsonText.data(using: .utf8) else {
                throw MenuServiceError.decodingError(
                    NSError(domain: "MenuService", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid JSON text from Gemini"
                    ])
                )
            }
            
            if APIConfiguration.enableAPILogging {
                print("📄 Parsed JSON: \(jsonText.prefix(500))...")
            }
            
            return try JSONDecoder().decode(GeminiMenuResponse.self, from: jsonData)
            
        } catch {
            print("❌ Decoding error: \(error)")
            if let responseText = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseText.prefix(1000))...")
            }
            throw MenuServiceError.decodingError(error)
        }
    }
    
    /// Cleans JSON text by removing markdown formatting and whitespace
    /// - Parameter rawText: Raw text response from Gemini
    /// - Returns: Cleaned JSON string ready for parsing
    private func cleanJSONText(_ rawText: String) -> String {
        return rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Builds the prompt for menu parsing with specific formatting requirements
    /// - Parameter ocrText: Raw OCR text to include in the prompt
    /// - Returns: Formatted prompt string for the Gemini API
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

/// Request structure for Gemini API calls
private struct GeminiAPIRequest: Codable {
    let contents: [GeminiContent]
}

/// Content structure containing text parts for Gemini API
private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

/// Individual text part for Gemini API requests
private struct GeminiPart: Codable {
    let text: String
}

/// Response structure from Gemini API
private struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]
}

/// Candidate response from Gemini API
private struct GeminiCandidate: Codable {
    let content: GeminiContent
}

/// Error response structure from Gemini API
private struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

/// Error details from Gemini API
private struct GeminiError: Codable {
    let message: String
    let code: Int
}

// MARK: - Error Handling

/// Comprehensive error types for menu service operations
enum MenuServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case geminiError(String)
    case noAPIKey
    
    /// Human-readable error descriptions for user display
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration"
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
    
    /// Indicates whether the error is recoverable with retry
    var isRetryable: Bool {
        switch self {
        case .networkError:
            return true // Retry on network errors
        case .serverError(let code):
            return code >= 500 // Retry on server errors
        case .invalidURL, .noAPIKey, .geminiError:
            return false // Don't retry on configuration or API errors
        case .invalidResponse, .decodingError:
            return false // Don't retry on parsing errors
        }
    }
} 
