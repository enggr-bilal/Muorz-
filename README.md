# Muorz 🍽️

> **AI-Powered Menu Scanner for iOS - Transform any menu into an intelligent, searchable experience**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)

## 🌟 Overview

Muorz is a modern iOS application that uses advanced OCR and AI technology to scan restaurant menus, extract text, and provide intelligent menu browsing with search, filtering, and nutritional insights. Built with SwiftUI and following MVVM architecture principles.

## ✨ Key Features

### 🤖 Intelligent Menu Processing
- **Advanced OCR**: Apple Vision Framework for high-accuracy text recognition
- **AI Processing**: Google Gemini 2.0 Flash API for intelligent menu parsing
- **Multi-language Support**: Processes menus in any language, outputs in English
- **Smart Translation**: Automatic translation with ingredient inference
- **Nutritional Analysis**: AI-powered nutrition scoring (protein, fat, carbs on 0-10 scale)
- **Dietary Detection**: Automatic identification of vegetarian, vegan, gluten-free, dairy-free options

### 📸 Modern Camera Experience
- **Camera-First Interface**: Streamlined scanning experience as app entry point
- **Multi-Photo Support**: Capture and process multiple menu pages
- **Real-time Processing**: Live feedback during OCR and AI processing
- **Smart Image Handling**: Automatic optimization for better text recognition
- **Seamless Navigation**: Smooth transitions between camera and menu views

### 🔍 Advanced Search & Filtering
- **Intelligent Search**: Search across dish names, ingredients, and descriptions
- **Real-time Highlighting**: Search terms highlighted in yellow for easy identification
- **Smart Suggestions**: Auto-complete based on available ingredients
- **Category Filtering**: Filter by meal type (Starter, Main Course, Dessert, Drinks)
- **Dietary Filtering**: Filter by dietary preferences with persistent defaults
- **Nutritional Sorting**: Sort by protein, fat, or carb content within categories

### ⚙️ Personalized Preferences
- **Persistent Settings**: Default dietary preferences and nutrition priorities
- **Customizable Display**: Toggle nutrition tags visibility
- **Session Filters**: Temporary filters that don't affect saved preferences
- **User Profiles**: Personal settings and preferences management

### 🛒 Selection Management
- **Smart Cart**: Add items with quantity controls
- **Price Calculation**: Automatic total calculation with multi-currency support
- **Selection Summary**: Clear overview of selected items and estimated costs
- **Server-Friendly Display**: Original names in large format for easy ordering

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+** target deployment
- **Swift 5.9+**
- **Gemini API Key** from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Muorz
   ```

2. **Configure Gemini API Key**
   
   #### Method 1: Environment Variable (Recommended)
   1. In Xcode: **Product** → **Scheme** → **Edit Scheme...**
   2. Select **"Run"** → **"Arguments"** tab
   3. Under **"Environment Variables"**, add:
      - **Name**: `GEMINI_API_KEY`
      - **Value**: Your API key from Google AI Studio
      - **✅ Check the checkbox to enable**
   
   #### Method 2: Info.plist (Alternative)
   1. Open `Info.plist` in Xcode
   2. Add new key:
      - **Key**: `GEMINI_API_KEY`
      - **Type**: String  
      - **Value**: Your API key
   
   ⚠️ **Security Note**: Never commit API keys to version control

3. **Build and Run**
   ```bash
   # Open in Xcode
   open Muorz.xcodeproj
   
   # Build and run on simulator or device
   ```

### ✅ Verification

After setup, the Xcode console should display:
- `🚀 Attempting Gemini API call` (successful configuration)
- `⚠️ No Gemini API key configured` (configuration needed)

## 🏗️ Architecture

### Project Structure

```
Muorz/
├── Model/                          # Data Models
│   ├── MenuItem.swift              # Core menu item model with API support
│   ├── OCRResult.swift             # OCR processing results
│   └── FilterModels.swift          # Filter and preference models
├── ViewModels/                     # Business Logic Layer
│   ├── OCRViewModel.swift          # OCR processing and multi-photo support
│   ├── MenuViewModel.swift         # Menu data and filtering logic
│   ├── UserPreferences.swift       # Persistent user settings
│   └── SelectionManager.swift      # Cart and selection management
├── Services/                       # Service Layer
│   ├── MenuService.swift           # Gemini API integration
│   └── APIConfiguration.swift      # API configuration and security
├── Views/                          # User Interface
│   ├── ContentView.swift           # Main app coordinator
│   ├── Camera/                     # Camera interface components
│   │   ├── CameraView.swift        # Main camera view
│   │   ├── DirectCameraView.swift  # Camera controls and capture
│   │   └── CameraPreviewView.swift # Camera preview display
│   ├── Menu/                       # Menu browsing interface
│   │   ├── MenuView.swift          # Main menu display
│   │   ├── Filters/                # Filter components
│   │   └── ItemRow/                # Menu item display components
│   ├── Selection/                  # Cart and selection views
│   ├── Settings/                   # User preferences interface
│   └── Components/                 # Reusable UI components
└── MuorzApp.swift                  # App entry point
```

### Design Patterns

- **MVVM Architecture**: Clear separation between Views, ViewModels, and Models
- **Protocol-Oriented Design**: Service protocols for dependency injection and testing
- **Reactive Programming**: Combine framework for data flow and state management
- **Modular Components**: Reusable SwiftUI components with clear responsibilities

## 🔧 Technical Implementation

### Data Flow

1. **Camera Capture**: User captures menu photos using DirectCameraView
2. **OCR Processing**: Apple Vision Framework extracts text from images
3. **AI Processing**: Gemini API converts raw text to structured menu data
4. **Data Transformation**: API response converted to internal MenuItem models
5. **UI Updates**: Reactive UI updates based on processed data
6. **User Interaction**: Search, filter, and selection with real-time feedback

### API Integration

#### Gemini API Response Format
```json
[
  {
    "ctg": "Main Course",
    "dsh": [
      {
        "nme": "PIZZA VEGETARIANA",
        "tr_nme": "Vegetarian Pizza",
        "ingr": ["tomato", "mozzarella", "vegetables", "basil"],
        "n_scr": [5, 6, 7],
        "tgs": [1, 0, 0, 0],
        "prc": "12,00 €"
      }
    ]
  }
]
```

#### Internal Data Model
```swift
struct MenuItem: Identifiable, Codable {
    let originalName: String        // Original language name
    let translatedName: String      // English translation
    let ingredientsEn: [String]     // Ingredients in English
    let categoryEn: String          // Category (starter, main, dessert)
    let price: String?              // Price as string
    let nutritionScores: NutritionScores  // [protein, fat, carbs]
    let tags: DietaryTags          // [vegetarian, vegan, gluten_free, dairy_free]
}
```

### Error Handling

- **Network Errors**: Automatic retry with exponential backoff
- **API Errors**: User-friendly error messages with retry options
- **OCR Failures**: Graceful degradation with manual text input option
- **Configuration Issues**: Clear setup instructions and validation

## 🎯 User Experience

### App Flow

1. **Launch**: App opens to camera interface
2. **Capture**: User photographs menu pages (supports multiple photos)
3. **Processing**: Real-time feedback during OCR and AI processing
4. **Browse**: Intelligent menu display with search and filtering
5. **Select**: Add items to cart with quantity controls
6. **Review**: View selection summary with total pricing

### Key Interactions

- **Search**: Tap magnifying glass to reveal search bar with suggestions
- **Filter**: Use filter buttons for category, dietary, and nutrition filtering
- **Sort**: Nutrition priority sorting within each category
- **Select**: Tap items to add to cart, use +/- controls for quantities
- **Navigate**: Seamless transitions between camera and menu views

## 🔮 Features & Capabilities

### ✅ Implemented Features

- **Camera-First Experience**: Modern camera interface as primary entry point
- **Multi-Photo OCR**: Process multiple menu pages in sequence
- **AI Menu Processing**: Google Gemini 2.0 Flash integration
- **Intelligent Search**: Search across names, ingredients, and descriptions
- **Advanced Filtering**: Category, dietary, and nutritional filters
- **Smart Sorting**: Nutrition-based sorting within categories
- **Persistent Preferences**: User settings that survive app restarts
- **Selection Management**: Cart functionality with quantity controls
- **Real-time Highlighting**: Search term highlighting in results
- **Error Recovery**: Comprehensive error handling with retry mechanisms
- **Responsive Design**: Adapts to different screen sizes and orientations

### 🚧 Known Limitations

- **API Dependency**: Requires internet connection for menu processing
- **Language Support**: OCR optimized for French and English menus
- **Menu Persistence**: Processed menus are not saved between sessions

### 🔮 Future Roadmap

#### High Priority
- [ ] Menu history and persistence with SwiftData
- [ ] Offline OCR capabilities for basic text extraction
- [ ] Enhanced multi-language support
- [ ] Menu sharing and export functionality

#### Medium Priority
- [ ] Restaurant discovery and location integration
- [ ] Social features and menu recommendations
- [ ] Nutritional information database integration
- [ ] Voice search and accessibility improvements

#### Low Priority
- [ ] Integration with food delivery services
- [ ] User reviews and ratings system
- [ ] Advanced dietary restriction support
- [ ] Machine learning for improved accuracy

## 🛠️ Development

### Code Quality Standards

- **SwiftUI Best Practices**: Declarative UI with proper state management
- **MVVM Architecture**: Clear separation of concerns
- **Protocol-Oriented Design**: Testable and maintainable code
- **Comprehensive Documentation**: All public interfaces documented
- **Error Handling**: Robust error handling throughout the app
- **Performance Optimization**: Efficient algorithms and memory management

### Testing Strategy

- **Unit Tests**: ViewModels and service layer testing
- **Integration Tests**: API integration and data flow testing
- **UI Tests**: Critical user flows and accessibility testing
- **Performance Tests**: Memory usage and response time validation

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture patterns
4. Add comprehensive tests for new functionality
5. Update documentation as needed
6. Submit a pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Apple Vision Framework**: For powerful OCR capabilities
- **Google Gemini API**: For intelligent menu processing
- **SwiftUI Community**: For design patterns and best practices
- **Open Source Contributors**: For inspiration and code examples

---

**Muorz - Transforming Menu Experiences with AI 🍽️**  
*Modern interface • Intelligent processing • Seamless experience*