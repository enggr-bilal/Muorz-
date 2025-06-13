# Muorz 

Available on TestFlight : https://testflight.apple.com/join/6yWPWu3N Feedbacks are welcome :)

> **iOS SwiftUI App for Intelligent Menu Processing with OCR and AI**

## Configuration Status

**Gemini 2.0 Flash API configured and ready**  
**API data flow fixed** - API data now displays correctly  

**Your API key:** See `PRIVATE_API_KEY.txt`  


---

## Features

### Intelligent Menu Processing
- **Gemini 2.0 Flash API** integration for advanced menu analysis
- **Real-time OCR** using Vision framework
- **Automatic translation** to English
- **Nutritional scoring** inference (protein, fat, carbs on 0-10 scale)
- **Dietary tags** detection (vegetarian, vegan, gluten-free, dairy-free)
- **Smart categorization** of dishes

### Advanced OCR
- **Apple Vision Framework** for high-accuracy text recognition
- **Multi-language support** for international menus
- **Real-time processing** with live camera feed
- **Automatic image optimization** for better OCR results

### Smart Search & Filtering
- **Intelligent search** with ingredient-based suggestions
- **Real-time highlighting** of search terms
- **Category filtering** (Starter, Main Course, Dessert)
- **Dietary filtering** with customizable defaults
- **Nutritional sorting** with priority-based ordering

### User Preferences
- **Default dietary preferences** set in ProfileView
- **Nutrition sort priorities** (Protein, Low Fat, Low Carbs)
- **Persistent settings** that survive app restarts
- **Temporary overrides** in MenuView without affecting defaults

## Business Model 🎯

### Freemium System
- **Muorz Currency**: Core virtual currency system
- **Weekly Allocation**: 3 Muorz automatically refilled every 7 days
- **Welcome Bonus**: New users receive 2 extra Muorz (5 total)
- **Smart Deduction**: Muorz only deducted upon successful menu processing

### Purchase Options
- **Travel Day Pass**: 24-hour unlimited scanning (€1.99)
- **Muorz Packages**:
  - Small: 10 Muorz (€1.49)
  - Medium: 20 Muorz (€2.49)
  - Large: 30 Muorz (€3.49)

### Revenue Features
- **In-App Store**: Beautiful purchase interface with package selection
- **Referral System**: 5 Muorz bonus for both referrer and referee
- **Smart UI**: 
  - Muorz counter with refill timer
  - Lock icons when no Muorz available
  - Travel Pass indicator
  - Purchase prompts at strategic moments

### Business Logic
- **Scan Prevention**: Users cannot scan without available Muorz
- **Weekly Refills**: Automatic refill every Monday
- **State Management**: Persistent across app updates
- **Analytics Ready**: Track conversion, usage patterns, and revenue metrics

### Future Revenue Streams
- **Restaurant Partnerships**: Bonus Muorz for partner venues
- **Seasonal Promotions**: Special events with bonus Muorz
- **Bulk Discounts**: Special pricing for frequent travelers
- **Social Features**: Premium features for active users

## Product Vision

The application allows users to:
- Take photos of restaurant menus
- Automatically extract text with Apple's OCR
- Process text via Google's Gemini API to get structured JSON
- Display the menu in a clear and organized way
- Filter and search through dishes and ingredients
- Customize display according to dietary preferences

## API Integration

### Gemini API Implementation

The app now uses **Google's Gemini 2.0 Flash** model for intelligent menu processing:

#### Key Features
- **Advanced AI Processing**: Gemini 2.0 Flash for fast and accurate menu parsing
- **Multi-language Support**: Processes menus in any language, outputs in English
- **Structured Data**: Consistent JSON format with nutrition scores and dietary tags
- **Intelligent Inference**: Automatically infers ingredients and nutritional information
- **Secure Configuration**: Multiple methods for API key management

#### API Response Format
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
  }
]
```

#### Setup Instructions
1. **Get API Key**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. **Configure Key**: Use environment variable `GEMINI_API_KEY` or Info.plist
3. **Test Integration**: App automatically falls back to sample data if no key is configured

## User Preferences & Filtering System

### Architecture Overview

The app uses a clear separation between **default preferences** and **temporary filters**:

#### Default Preferences (ProfileView only)
- **Default Dietary Filter**: Automatically applied when the app opens
- **Default Nutrition Sort Priority**: Controls how items are sorted within each section
- **Nutrition Tag Display**: Controls which nutrition tags are visible on menu items
- These settings are persistent and only changeable from the ProfileView

#### Temporary Filters (MenuView)
- **Category Filter**: Filter by food category (Starter, Main, Dessert, etc.)
- **Dietary Filter**: Temporarily override the default dietary preference
- **Nutrition Sort Priority**: Temporarily override the default sorting priority
- **Search**: Text-based search in dish names and ingredients
- These filters reset to default values when the app restarts

### Key Behaviors

1. **Default Dietary Preference**:
   - Set in ProfileView → Settings → Default Dietary Filter
   - Automatically applied when opening the app
   - Changing filters in MenuView does NOT affect this default
   - Only way to change: ProfileView settings

2. **Default Nutrition Sort Priority**:
   - Set in ProfileView → Settings → Default Nutrition Sort Priority
   - Controls how menu items are sorted within each category section
   - Options: No Priority, Protein Priority, Low Fat Priority, Low Carbs Priority
   - Can be temporarily overridden in MenuView without affecting the default
   - Automatically applied when opening the app

3. **Nutrition Tag Display**:
   - Toggles in ProfileView control which tags are shown on menu items
   - These are display preferences, NOT filters
   - Tags show nutritional properties: High Protein, Low Fat, Low Carbs

4. **MenuView Filters**:
   - All filters are temporary and session-based
   - Start with default dietary preference applied
   - Start with default nutrition sort priority applied
   - Can be changed freely without affecting defaults
   - Reset when app restarts

### Search & Highlighting

- **Search Bar**: Hidden by default, accessible via magnifying glass button
- **Text Highlighting**: Search terms are highlighted in yellow in dish names and ingredients
- **Suggestions**: Intelligent suggestions based on available ingredients
- **Real-time**: Search results update as you type

### Filters & Sorting

- **Categories**: All, Starter, Main Course, Dessert
- **Diets**: Vegetarian, Vegan, Gluten-Free, Dairy-Free (temporary override of default)
- **Nutrition Sorting**: Sort items within each section by nutritional priority
  - **No Priority**: Items appear in their original order
  - **Protein Priority**: Items with higher protein content appear first
  - **Low Fat Priority**: Items with lower fat content appear first  
  - **Low Carbs Priority**: Items with lower carbs content appear first
  - *Adaptive interface: Button shows corresponding nutrition tag icon and color when active*
  - *Simplified menu: Text-only options with checkmarks for selection*

### Interface States
- **Loading**: During OCR/API processing
- **Error**: With retry capability
- **Empty**: When no results match filters
- **Success**: Structured menu display with intelligent sorting

## Architecture

### Project Structure

```
Muorz/
├── Model/
│   ├── MenuItem.swift          # Data models with Gemini API support
│   ├── FilterModels.swift      # Filter models
│   └── OCRResult.swift         # OCR results
├── ViewModel/
│   ├── MenuViewModel.swift     # Main ViewModel with search
│   ├── MenuService.swift       # Gemini API service
│   ├── OCRViewModel.swift      # Enhanced OCR processing
│   ├── SelectionManager.swift  # Cart management
│   ├── UserPreferences.swift   # User preferences
│   └── APIConfiguration.swift  # Secure API configuration
├── Views/
│   ├── ContentView.swift       # Main view
│   ├── CameraView.swift        # Camera/Lens view (entry point)
│   ├── Components/
│   │   ├── SearchBar.swift     # Search bar with suggestions
│   │   └── QuantityControl.swift
│   ├── Menu/
│   │   ├── MenuView.swift      # Refactored menu view
│   │   ├── Filters/
│   │   │   └── FilterHeader.swift
│   │   └── ItemRow/
│   │       ├── MenuItemRow.swift
│   │       ├── MenuItemInfo.swift
│   │       ├── NutritionTag.swift
│   │       └── NutritionTagsSection.swift
│   ├── Selection/
│   └── Settings/
└── Assets.xcassets/
```

### Data Models

#### MenuItem (Internal Format)
```swift
struct MenuItem: Identifiable, Codable {
    let originalName: String        // Original name (any language)
    let translatedName: String      // Translated name (English)
    let ingredientsEn: [String]     // Ingredients in English
    let categoryEn: String          // Category (starter, main course, dessert)
    let price: String?              // Price (optional)
    let nutritionScores: NutritionScores
    let tags: DietaryTags
}
```

#### Gemini API Format (Compact)
```json
[
  {
    "ctg": "Main Course",
    "dsh": [
      {
        "nme": "PIZZA VEGETARIANA",
        "tr_nme": "Vegetarian Pizza",
        "ingr": ["tomato", "mozzarella", "vegetables"],
        "n_scr": [5, 6, 7],
        "tgs": [1, 0, 0, 0],
        "prc": "12,00 €"
      }
    ]
  }
]
```

## Features

### Implemented
- **Camera-First Experience**: Modern camera interface as app entry point
- **Advanced OCR**: Text extraction with multilingual support (FR/EN)
- **Gemini AI Processing**: Google's Gemini 2.0 Flash for intelligent menu parsing
- **Smart Search**: Search in dish names AND ingredients with suggestions
- **Multiple Filters**: By category, diet, and nutrition
- **Intelligent Sorting**: Sort menu items by nutritional priorities (protein, fat, carbs)
- **Persistent Preferences**: Default dietary filters and nutrition sort priorities
- **Adaptive UI**: Nutrition options adapt based on user display preferences
- **Modern Interface**: SwiftUI design with smooth animations and gradients
- **Complete State Management**: Loading, processing, success, and error states
- **MVVM Architecture**: Clear separation of responsibilities
- **Seamless Navigation**: Smooth transitions between camera and menu views
- **Server-Readable Selection**: Original names displayed in large, multi-line format for easy server reading
- **Secure API Configuration**: Multiple methods for API key management
- **Error Handling & Retries**: Robust network error handling with exponential backoff
- **Development Tools**: Mock service and detailed logging for development

### API Features
- **Gemini API Integration**: Complete implementation with Google's latest model
- **Automatic Fallback**: Sample data when API is unavailable
- **Retry Logic**: Up to 3 attempts with exponential backoff
- **Secure Configuration**: Environment variables and Info.plist support
- **Development Mode**: Mock service for testing without API calls
- **Comprehensive Logging**: Detailed request/response logging in debug mode

## Usage

### API Setup - Required Configuration

#### Configuration in Xcode
1. **Product** → **Scheme** → **Edit Scheme...**
2. **Run** → **Arguments** → **Environment Variables**
3. **Add**:
   - Name: `GEMINI_API_KEY`
   - Value: `[YOUR_GEMINI_API_KEY]`

#### Verification
- Xcode Console should display: `🚀 Attempting Gemini API call`
- If you see `⚠️ No Gemini API key configured`, the configuration failed


### Camera/Lens View
- Entry point of the application
- Camera interface for menu photography
- Real-time OCR processing with Vision framework
- Automatic Gemini API processing
- Seamless transition to menu view

### Search & Filtering
- **Smart Search**: Search in dish names and ingredients
- **Category Filters**: All, Starter, Main Course, Dessert
- **Dietary Filters**: Vegetarian, Vegan, Gluten-Free, Dairy-Free
- **Nutrition Sorting**: Sort by protein, fat, or carbs content
- **Real-time Updates**: All filters update instantly

### Menu Display
- **Categorized Layout**: Items grouped by category
- **Nutrition Tags**: Visual indicators for nutritional properties
- **Interactive Selection**: Add items to cart with quantity controls
- **Search Highlighting**: Search terms highlighted in results
- **Responsive Design**: Adapts to different screen sizes

## Technical Implementation

### API Integration
- **Service Layer**: Protocol-based architecture for testability
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Retry Logic**: Automatic retries with exponential backoff
- **Fallback**: Graceful degradation when API is unavailable
- **Security**: No hardcoded API keys, environment-based configuration

### Data Processing
- **OCR Pipeline**: Vision framework → Text extraction → API processing
- **Data Transformation**: Gemini API response → Internal data models
- **State Management**: Reactive updates using Combine framework
- **Persistence**: User preferences saved locally

### User Interface
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clear separation of concerns
- **Reactive UI**: Automatic updates based on state changes
- **Accessibility**: VoiceOver support and accessibility labels
- **Dark Mode**: Full support for system appearance modes

## Known Issues

- **Menu Persistence**: Menus are not saved between app sessions
- **Offline Mode**: No offline functionality currently available

## Roadmap

### High Priority
- [ ] Implement menu persistence with SwiftData
- [ ] Add menu history functionality
- [ ] Improve error handling and user feedback

### Medium Priority
- [ ] Add offline LLM capabilities (iOS 26 On device Model)
- [ ] Add favorite dishes feature
- [ ] Improve camera interface

### Low Priority
- [ ] Implement restaurant discovery
- [ ] Add user reviews and ratings
- [ ] B2B Model partnership with restaurants
 
