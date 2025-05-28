# API Integration Guide - Muorz

This guide explains how to integrate the ChatGPT API into the Muorz application to process OCR menus.

## 🚀 Integration Steps

### 1. API Keys Configuration

#### Option A: Info.plist (Recommended for development)
```xml
<!-- In Info.plist -->
<key>API_KEY</key>
<string>your-api-key-here</string>
<key>OPENAI_API_KEY</key>
<string>your-openai-key-here</string>
```

#### Option B: Environment variables
```swift
// In APIConfiguration.swift
var apiKey: String {
    return ProcessInfo.processInfo.environment["API_KEY"] ?? ""
}
```

#### Option C: Secure configuration (Production)
```swift
// Use a secret management service like AWS Secrets Manager
// or Azure Key Vault for production
```

### 2. API Service Activation

In `MenuService.swift`, replace the `processOCRText` method:

```swift
func processOCRText(_ text: String) async throws -> MenuResponse {
    // Build the request
    let request = try buildAPIRequest(for: text)
    
    // Log the request (in development)
    APIConfiguration.shared.logRequest(request)
    
    // Perform API call
    let response = try await performAPICall(request)
    
    return response
}
```

### 3. ChatGPT API Implementation

#### ChatGPT request structure
```swift
private struct ChatGPTRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    let temperature: Double
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}
```

#### ChatGPT call method
```swift
private func callChatGPT(with ocrText: String) async throws -> MenuResponse {
    let config = APIConfiguration.ChatGPTConfig.self
    
    let request = ChatGPTRequest(
        model: config.model,
        messages: [
            ChatGPTRequest.Message(
                role: "user",
                content: config.buildPrompt(with: ocrText)
            )
        ],
        maxTokens: config.maxTokens,
        temperature: config.temperature
    )
    
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        throw MenuServiceError.invalidURL
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer \(APIConfiguration.shared.openAIKey)", 
                       forHTTPHeaderField: "Authorization")
    
    urlRequest.httpBody = try JSONEncoder().encode(request)
    
    let (data, response) = try await session.data(for: urlRequest)
    
    // Process ChatGPT response
    let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
    
    // Extract JSON from response content
    guard let content = chatResponse.choices.first?.message.content else {
        throw MenuServiceError.invalidResponse
    }
    
    // Parse JSON returned by ChatGPT
    guard let jsonData = content.data(using: .utf8) else {
        throw MenuServiceError.decodingError(NSError(domain: "Invalid JSON", code: 0))
    }
    
    return try JSONDecoder().decode(MenuResponse.self, from: jsonData)
}
```

### 4. Error Handling

```swift
enum APIError: LocalizedError {
    case rateLimitExceeded
    case invalidAPIKey
    case quotaExceeded
    case serverError(Int)
    case networkTimeout
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .quotaExceeded:
            return "API quota exceeded. Please upgrade your plan."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .networkTimeout:
            return "Network timeout. Please check your connection."
        case .invalidJSON:
            return "Invalid response format from API."
        }
    }
}
```

### 5. Retry Logic

```swift
private func performAPICallWithRetry(_ request: URLRequest, 
                                   maxRetries: Int = 3) async throws -> MenuResponse {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await performAPICall(request)
        } catch {
            lastError = error
            
            // Ne pas retry pour certaines erreurs
            if case MenuServiceError.invalidURL = error {
                throw error
            }
            
            // Attendre avant le prochain essai
            if attempt < maxRetries {
                let delay = TimeInterval(attempt * 2) // Backoff exponentiel
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? MenuServiceError.networkError(NSError(domain: "Unknown", code: 0))
}
```

## 🔧 Advanced Configuration

### 1. Response Caching

```swift
class MenuCache {
    private let cache = NSCache<NSString, MenuResponse>()
    
    func store(_ response: MenuResponse, for key: String) {
        cache.setObject(response, forKey: key as NSString)
    }
    
    func retrieve(for key: String) -> MenuResponse? {
        return cache.object(forKey: key as NSString)
    }
    
    func cacheKey(for ocrText: String) -> String {
        return ocrText.sha256
    }
}
```

### 2. Monitoring and Analytics

```swift
extension MenuService {
    private func trackAPICall(success: Bool, duration: TimeInterval, error: Error? = nil) {
        // Integrate with your analytics service
        // Ex: Firebase Analytics, Mixpanel, etc.
        
        let properties = [
            "success": success,
            "duration": duration,
            "error": error?.localizedDescription ?? "none"
        ]
        
        // Analytics.track("api_call_completed", properties: properties)
    }
}
```

### 3. Cost Optimization

```swift
extension APIConfiguration.ChatGPTConfig {
    // Optimize prompt to reduce tokens
    static let optimizedSystemPrompt = """
    Convert OCR menu text to JSON. Format:
    {"menu_items":[{"original_name":"","translated_name":"","ingredients_en":[],"category_en":"","price":"","nutrition_scores":{"protein":0,"fat":0,"carbs":0},"tags":{"vegetarian":false,"vegan":false,"gluten_free":false,"dairy_free":false}}],"restaurant_info":{"name":"","cuisine":"","location":""}}
    """
}
```

## 🧪 Testing

### 1. Unit Tests

```swift
class MenuServiceTests: XCTestCase {
    func testProcessOCRText() async throws {
        let mockService = MockMenuService()
        let response = try await mockService.processOCRText("Test menu text")
        
        XCTAssertFalse(response.menuItems.isEmpty)
        XCTAssertNotNil(response.restaurantInfo)
    }
}
```

### 2. Integration Tests

```swift
class APIIntegrationTests: XCTestCase {
    func testRealAPICall() async throws {
        // Test with real API key (development only)
        let service = MenuService(
            apiKey: "test-key",
            baseURL: "https://dev-api.muorz.com"
        )
        
        let response = try await service.processOCRText("PIZZA MARGHERITA 12€")
        XCTAssertFalse(response.menuItems.isEmpty)
    }
}
```

## 📊 Monitoring

### 1. Metrics to Monitor

- **Success Rate**: % of successful API calls
- **Latency**: Average response time
- **Cost**: Tokens used per call
- **Quality**: Accuracy of translations and categorizations

### 2. Alerts

```swift
extension MenuService {
    private func checkAPIHealth() async {
        // Check API health periodically
        // Send alerts if necessary
    }
}
```

## 🚀 Deployment

### 1. Environment Variables

```bash
# .env.development
API_KEY=dev-api-key
OPENAI_API_KEY=dev-openai-key
BASE_URL=https://dev-api.muorz.com

# .env.production
API_KEY=prod-api-key
OPENAI_API_KEY=prod-openai-key
BASE_URL=https://api.muorz.com
```

### 2. CI/CD Configuration

```yaml
# .github/workflows/deploy.yml
- name: Set API Keys
  run: |
    echo "API_KEY=${{ secrets.API_KEY }}" >> $GITHUB_ENV
    echo "OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }}" >> $GITHUB_ENV
```

## 📋 Integration Checklist

- [ ] API keys configured
- [ ] API service activated
- [ ] Error handling implemented
- [ ] Retry logic in place
- [ ] Cache configured (optional)
- [ ] Unit tests passing
- [ ] Integration tests validated
- [ ] Monitoring configured
- [ ] Documentation updated

## 🆘 Troubleshooting

### Common Errors

1. **"Invalid API Key"**
   - Check configuration in Info.plist
   - Ensure the key is active

2. **"Rate limit exceeded"**
   - Implement a queue system
   - Reduce call frequency

3. **"Invalid JSON response"**
   - Check ChatGPT prompt
   - Add client-side JSON validation

4. **Frequent timeouts**
   - Increase timeout
   - Optimize prompt size

---

**For any questions, consult the API documentation or contact the development team.** 