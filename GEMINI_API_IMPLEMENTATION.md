# Gemini API Implementation

## 🎯 Overview

This document describes the implementation of Google's Gemini API for processing restaurant menu OCR text in the Muorz app.

## 📋 Features Implemented

### 1. API Integration
- **Gemini 2.0 Flash Model**: Latest and fastest Gemini model
- **Structured JSON Output**: Custom prompt for consistent menu parsing
- **Error Handling**: Comprehensive error management with retries
- **Secure Configuration**: Multiple methods for API key management

### 2. Data Models

#### API Response Models (Gemini Format)
```swift
struct GeminiMenuResponse: Codable {
    let categories: [MenuCategory]
}

struct MenuCategory: Codable {
    let categoryName: String  // "ctg"
    let dishes: [APIDish]     // "dsh"
}

struct APIDish: Codable {
    let originalName: String      // "nme"
    let translatedName: String    // "tr_nme"
    let ingredients: [String]     // "ingr"
    let nutritionScores: [Int]    // "n_scr" [protein, fat, carbs]
    let tags: [Int]              // "tgs" [vegetarian, vegan, gluten_free, dairy_free]
    let price: String            // "prc"
}
```

#### Internal App Models
- **MenuItem**: Internal representation with full property names
- **MenuResponse**: Wrapper for processed menu items
- **NutritionScores**: Structured nutrition data
- **DietaryTags**: Boolean dietary preferences

### 3. API Prompt Engineering

The custom prompt ensures consistent JSON output:

```
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
```

## 🔧 Configuration

### API Key Setup

#### Method 1: Environment Variable (Recommended for Development)
1. In Xcode: Product → Scheme → Edit Scheme
2. Select "Run" → "Arguments" tab
3. Add Environment Variable:
   - Name: `GEMINI_API_KEY`
   - Value: `your_actual_api_key_here`

#### Method 2: Info.plist (Production)
1. Open Info.plist
2. Add key: `GEMINI_API_KEY` (String)
3. Value: `your_actual_api_key_here`

#### Method 3: Direct Code (Not Recommended)
Replace the placeholder in `APIConfiguration.swift`

### Development Configuration

```swift
// Use mock service for testing
USE_MOCK_SERVICE=true

// Enable detailed API logging
// Automatically enabled in DEBUG builds
```

## 🏗️ Architecture

### Service Layer
```
OCRViewModel
    ↓
APIConfiguration.createMenuService()
    ↓
MenuService (Gemini API) OR MockMenuService
    ↓
GeminiMenuResponse → MenuResponse → MenuItem[]
```

### Error Handling
- **Retry Logic**: Up to 3 attempts with exponential backoff
- **Fallback**: Sample data when API is unavailable
- **Logging**: Detailed request/response logging in debug mode

### Data Flow
1. **OCR Extraction**: Vision framework extracts text from image
2. **API Request**: Text sent to Gemini API with custom prompt
3. **JSON Parsing**: Response parsed into structured data
4. **Model Conversion**: API models converted to internal models
5. **UI Update**: MenuViewModel receives processed menu items

## 📊 API Response Example

```json
[
  {
    "ctg": "Starter",
    "dsh": [
      {
        "nme": "BRUSCHETTA VEGETARIANA",
        "tr_nme": "Vegetarian Bruschetta",
        "ingr": ["tomato", "basil", "mozzarella", "bread"],
        "n_scr": [4, 5, 7],
        "tgs": [1, 0, 0, 0],
        "prc": "8,00 €"
      }
    ]
  },
  {
    "ctg": "Main Course",
    "dsh": [
      {
        "nme": "PIZZA MARGHERITA",
        "tr_nme": "Margherita Pizza",
        "ingr": ["tomato sauce", "mozzarella", "basil", "dough"],
        "n_scr": [5, 6, 8],
        "tgs": [1, 0, 0, 0],
        "prc": "12,00 €"
      }
    ]
  }
]
```

## 🔒 Security Features

### API Key Protection
- Environment variables for development
- Info.plist for production builds
- No hardcoded keys in source code
- Automatic fallback to sample data

### Request Security
- HTTPS only communication
- Request timeout configuration
- Error message sanitization
- No sensitive data logging in production

## 🧪 Testing & Development

### Mock Service
```swift
class MockMenuService: MenuServiceProtocol {
    func processOCRText(_ text: String) async throws -> MenuResponse {
        // Returns sample data with simulated delay
    }
}
```

### Debug Features
- Request/response logging
- API configuration validation
- Performance timing
- Error details in console

### Environment Variables
```bash
GEMINI_API_KEY=your_key_here
USE_MOCK_SERVICE=true  # Force mock service
```

## 📈 Performance Optimizations

### Request Optimization
- **Timeout Configuration**: 30-second timeout
- **Retry Logic**: Exponential backoff (1s, 4s, 9s)
- **Session Reuse**: Configured URLSession
- **Efficient Parsing**: Direct JSON decoding

### Memory Management
- **Async/Await**: Modern concurrency
- **Weak References**: Prevent retain cycles
- **Data Streaming**: Efficient response handling

## 🚀 Usage

### Basic Implementation
```swift
let ocrViewModel = OCRViewModel()
await ocrViewModel.processImage(menuImage)

// Access processed menu
if let menu = ocrViewModel.processedMenu {
    let items = menu.menuItems
    // Use menu items in UI
}
```

### Custom Service
```swift
let customService = MenuService(apiKey: "your_key")
let ocrViewModel = OCRViewModel(menuService: customService)
```

## 🔄 Future Enhancements

### Planned Features
- **Caching**: Local storage of processed menus
- **Offline Mode**: Fallback when API unavailable
- **Batch Processing**: Multiple images at once
- **Language Detection**: Automatic language identification

### API Improvements
- **Response Validation**: Schema validation
- **Custom Models**: Fine-tuned models for specific cuisines
- **Image Analysis**: Direct image processing (when available)
- **Streaming**: Real-time processing updates

## 📚 Dependencies

### Required
- Foundation (URLSession, JSON)
- Vision (OCR processing)
- SwiftUI (UI updates)

### External
- Google Gemini API
- No additional third-party libraries

## 🐛 Troubleshooting

### Common Issues

#### API Key Not Working
- Verify key is correctly set
- Check API quotas and billing
- Ensure key has Gemini API access

#### JSON Parsing Errors
- Check API response format
- Verify prompt consistency
- Enable debug logging

#### Network Timeouts
- Check internet connection
- Increase timeout values
- Verify API endpoint availability

### Debug Commands
```swift
// Enable detailed logging
APIConfiguration.enableAPILogging = true

// Check configuration
print("API Configured: \(APIConfiguration.isGeminiAPIConfigured)")

// Force mock service
APIConfiguration.useMockService = true
```

## 📄 License & Usage

This implementation is part of the Muorz app and follows the project's licensing terms. The Gemini API usage is subject to Google's terms of service and pricing. 