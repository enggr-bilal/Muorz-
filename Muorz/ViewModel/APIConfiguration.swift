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
    
    // MARK: - Gemini API Configuration
    
    /// Gemini API Key - Replace with your actual API key
    /// Get your API key from: https://makersuite.google.com/app/apikey
    static let geminiAPIKey: String = {
        // First, try to get from environment variable (for development with Xcode)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            print("✅ Found API key from environment variable (Xcode launch)")
            return envKey
        }
        
        // Then try to get from UserDefaults (for standalone app launch)
        if let userDefaultsKey = UserDefaults.standard.string(forKey: "GEMINI_API_KEY"), !userDefaultsKey.isEmpty {
            print("✅ Found API key from UserDefaults (standalone launch)")
            return userDefaultsKey
        }
        
        // Then try to get from Info.plist (for production)
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GEMINI_API_KEY"] as? String, !key.isEmpty {
            print("✅ Found API key from Info.plist")
            return key
        }
        
        // Finally, return placeholder (will use sample data)
        print("❌ No API key found - using placeholder")
        return "YOUR_GEMINI_API_KEY_HERE"
    }()
    
    /// Set API key in UserDefaults for standalone app launches
    static func setAPIKeyForStandaloneUse() {
        let apiKey = "AIzaSyAy5T7zHmtCUHtWmIaqbPZZCDUBN13RfRs"
        UserDefaults.standard.set(apiKey, forKey: "GEMINI_API_KEY")
        UserDefaults.standard.synchronize()
        print("🔑 API key saved to UserDefaults for standalone use")
    }
    
    /// Gemini API Base URL
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    // MARK: - API Validation
    
    /// Check if Gemini API is properly configured
    static var isGeminiAPIConfigured: Bool {
        return !geminiAPIKey.isEmpty && 
               geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" &&
               geminiAPIKey != "YOUR_GEMINI_API_KEY"
    }
    
    /// Get configured MenuService instance
    static func createMenuService() -> MenuServiceProtocol {
        return MenuService(apiKey: geminiAPIKey)
    }
    
    // MARK: - Development Configuration
    
    /// Whether to use mock service for development
    static let useMockService: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["USE_MOCK_SERVICE"] == "true"
        #else
        return false
        #endif
    }()
    
    /// API request timeout in seconds
    static let requestTimeout: TimeInterval = 30.0
    
    /// Maximum retries for failed requests
    static let maxRetries: Int = 3
    
    // MARK: - Logging Configuration
    
    /// Enable API request/response logging
    static let enableAPILogging: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// Log API requests and responses
    static func logAPIRequest(_ request: URLRequest) {
        guard enableAPILogging else { return }
        
        print("🌐 API Request:")
        print("   URL: \(request.url?.absoluteString ?? "Unknown")")
        print("   Method: \(request.httpMethod ?? "Unknown")")
        
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString.prefix(500))...")
        }
    }
    
    static func logAPIResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        guard enableAPILogging else { return }
        
        print("📡 API Response:")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("   Status: \(httpResponse.statusCode)")
        }
        
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
        
        if let data = data,
           let responseString = String(data: data, encoding: .utf8) {
            print("   Data: \(responseString.prefix(500))...")
        }
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

        If the input text does not contain recognizable menu items or is not a restaurant menu, return a valid JSON in the specified format but with no items included.

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

// MARK: - API Setup Instructions

/*
 
 ## Gemini API Setup Instructions
 
 ### 1. Get your API Key
 - Go to https://makersuite.google.com/app/apikey
 - Sign in with your Google account
 - Create a new API key
 - Copy the generated key
 
 ### 2. Configure the API Key (Choose one method)
 
 #### Method A: Environment Variable (Recommended for development)
 1. In Xcode, go to Product → Scheme → Edit Scheme
 2. Select "Run" on the left
 3. Go to "Arguments" tab
 4. Under "Environment Variables", add:
    - Name: GEMINI_API_KEY
    - Value: your_actual_api_key_here
 
 #### Method B: Info.plist (For production builds)
 1. Open Info.plist in Xcode
 2. Add a new key:
    - Key: GEMINI_API_KEY
    - Type: String
    - Value: your_actual_api_key_here
 
 #### Method C: Direct replacement (Not recommended)
 Replace "YOUR_GEMINI_API_KEY_HERE" in the geminiAPIKey property above
 
 ### 3. Test the Configuration
 - Run the app
 - Try processing a menu image
 - Check the console for configuration messages
 
 ### 4. Security Notes
 - Never commit API keys to version control
 - Use environment variables for development
 - Consider using a secure key management service for production
 - Add Info.plist to .gitignore if using Method B
 
 */ 
