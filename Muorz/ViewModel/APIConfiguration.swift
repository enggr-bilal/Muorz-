//
//  APIConfiguration.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

// MARK: - API Configuration

struct APIConfiguration {
    static let shared = APIConfiguration()
    
    // MARK: - Environment Configuration
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://dev-api.muorz.com"
            case .staging:
                return "https://staging-api.muorz.com"
            case .production:
                return "https://api.muorz.com"
            }
        }
    }
    
    // MARK: - Current Configuration
    
    #if DEBUG
    let environment: Environment = .development
    #else
    let environment: Environment = .production
    #endif
    
    var baseURL: String {
        return environment.baseURL
    }
    
    // MARK: - API Endpoints
    
    enum Endpoint {
        case processMenu
        case getMenuHistory
        case saveMenu
        case deleteMenu
        
        var path: String {
            switch self {
            case .processMenu:
                return "/api/v1/process-menu"
            case .getMenuHistory:
                return "/api/v1/menus"
            case .saveMenu:
                return "/api/v1/menus"
            case .deleteMenu:
                return "/api/v1/menus"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .processMenu, .saveMenu:
                return .POST
            case .getMenuHistory:
                return .GET
            case .deleteMenu:
                return .DELETE
            }
        }
    }
    
    // MARK: - HTTP Methods
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    // MARK: - API Keys (configure according to environment)
    
    var apiKey: String {
        // TODO: Retrieve from secure configuration file
        // or from environment variables
        return Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
    }
    
    var openAIKey: String {
        return Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }
    
    // MARK: - Request Configuration
    
    var timeoutInterval: TimeInterval {
        return 30.0 // 30 seconds
    }
    
    var maxRetryAttempts: Int {
        return 3
    }
    
    // MARK: - Helper Methods
    
    func fullURL(for endpoint: Endpoint) -> String {
        return baseURL + endpoint.path
    }
    
    func defaultHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "Muorz-iOS/\(appVersion())"
        ]
        
        if !apiKey.isEmpty {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        
        return headers
    }
    
    private func appVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version)(\(build))"
    }
}

// MARK: - API Request Builder

extension APIConfiguration {
    func buildRequest(for endpoint: Endpoint, body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: fullURL(for: endpoint)) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = timeoutInterval
        
        // Add headers
        for (key, value) in defaultHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}

// MARK: - ChatGPT Specific Configuration

extension APIConfiguration {
    struct ChatGPTConfig {
        static let model = "gpt-4"
        static let maxTokens = 2000
        static let temperature = 0.3
        
        static let systemPrompt = """
        You are a menu processing assistant. Your task is to analyze OCR text from restaurant menus and convert it into structured JSON format.
        
        Requirements:
        1. Extract menu items with their original names (usually in French)
        2. Provide English translations for dish names
        3. List ingredients in English
        4. Categorize items (starter, main course, dessert, drink)
        5. Extract prices when available
        6. Assign nutrition scores (1-10 scale) for protein, fat, and carbs
        7. Add dietary tags (vegetarian, vegan, gluten_free, dairy_free)
        
        Return only valid JSON in the specified format. Do not include any explanations or additional text.
        """
        
        static func buildPrompt(with ocrText: String) -> String {
            return """
            \(systemPrompt)
            
            OCR Text to process:
            \(ocrText)
            
            Expected JSON format:
            {
              "menu_items": [
                {
                  "original_name": "string",
                  "translated_name": "string",
                  "ingredients_en": ["string"],
                  "category_en": "starter|main course|dessert|drink",
                  "price": "string or null",
                  "nutrition_scores": {
                    "protein": number,
                    "fat": number,
                    "carbs": number
                  },
                  "tags": {
                    "vegetarian": boolean,
                    "vegan": boolean,
                    "gluten_free": boolean,
                    "dairy_free": boolean
                  }
                }
              ],
              "restaurant_info": {
                "name": "string or null",
                "cuisine": "string or null",
                "location": "string or null"
              }
            }
            """
        }
    }
}

// MARK: - Network Monitoring

extension APIConfiguration {
    var isNetworkLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    func logRequest(_ request: URLRequest) {
        guard isNetworkLoggingEnabled else { return }
        
        print("🌐 API Request:")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }
    
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard isNetworkLoggingEnabled else { return }
        
        print("📡 API Response:")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            print("Data: \(responseString)")
        }
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
    }
} 