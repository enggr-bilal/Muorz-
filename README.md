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

### Menu History & Persistence
- **SwiftData Integration**: All scanned menus automatically saved
- **Comprehensive History**: View all previously scanned menus with metadata
- **Smart Organization**: Menus sorted by scan date with restaurant names
- **Rating System**: 5-star rating system for each scanned menu
- **Review Notes**: Add personal notes and reviews to saved menus
- **Favorites System**: Mark favorite menus for quick access
- **Menu Details**: Full menu recreation with same UI as original scan
- **Search & Filter**: Find specific menus by restaurant name or date
- **Persistent Storage**: All data saved locally using SwiftData
- **GPS Integration**: Location data saved with each scan for context

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

The app uses **Google's Gemini 2.0 Flash** model for intelligent menu processing:

#### Key Features
- **Advanced AI Processing**: Gemini 2.0 Flash for fast and accurate menu parsing
- **Multi-language Support**: Processes menus in any language, outputs in English
- **Structured Data**: Consistent JSON format with validated nutrition scores and dietary tags
- **Intelligent Inference**: Automatically infers ingredients and nutritional information
- **Secure Configuration**: Multiple methods for API key management
- **Robust Validation**: Automatic validation of nutrition scores and dietary tags

#### API Response Format
```json
{
  "currency": "€",
  "categories": [
    {
      "name": "starter",
      "dishes": [
        {
          "original_name": "BRUSCHETTA VEGETARIANA",
          "translated_name": "Vegetarian Bruschetta",
          "ingredients_en": ["tomato", "basil", "mozzarella", "bread"],
          "price": 8.00,
          "nutrition_scores": [4, 5, 7],
          "dietary_tags": [1, 0, 0, 0]
        }
      ]
    }
  ]
}
```

#### Data Validation & Processing

##### Nutrition Scores
- **Scale**: 0-10 for each component (protein, fat, carbs)
- **Guidelines**:
  - Protein: 0-2 (low), 3-6 (medium), 7-10 (high)
  - Fat: 0-3 (low), 4-6 (medium), 7-10 (high)
  - Carbs: 0-3 (low), 4-6 (medium), 7-10 (high)
- **Validation**: Scores are automatically clamped to 0-10 range
- **Null Values**: Used for drinks, wines, or items where estimation is impossible

##### Dietary Tags
- **Format**: Array of 4 integers [vegetarian, vegan, gluten_free, dairy_free]
- **Values**: 1 (true) or 0 (false)
- **Validation Rules**:
  - Vegetarian: true if no meat/fish
  - Vegan: true if no animal products
  - Gluten-free: true if no wheat/barley/rye
  - Dairy-free: true if no milk/cheese/cream
- **Default**: [0, 0, 0, 0] if tags are missing or invalid

##### Categories
- **Standard Order**: "starter", "pizza", "pasta", "main course", "dessert", "drink"
- **Custom Categories**: Supported but sorted after standard categories
- **Normalization**: All category names are converted to lowercase

##### Prices
- **Format**: Double values without currency symbols
- **Currency**: Extracted once at the top level if visible
- **Null Values**: Used when no price information is available

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
│   ├── OCRResult.swift         # OCR results
│   └── ScannedMenu.swift       # SwiftData models for menu persistence
├── ViewModel/
│   ├── MenuViewModel.swift     # Main ViewModel with search
│   ├── MenuService.swift       # Gemini API service
│   ├── OCRViewModel.swift      # Enhanced OCR processing
│   ├── SelectionManager.swift  # Cart management
│   ├── UserPreferences.swift   # User preferences
│   ├── ScannedMenuService.swift # History management service
│   └── APIConfiguration.swift  # Secure API configuration
├── Views/
│   ├── ContentView.swift       # Main view with navigation
│   ├── CameraView.swift        # Camera/Lens view (entry point)
│   ├── DirectCameraView.swift  # Enhanced camera interface
│   ├── Components/
│   │   ├── SearchBar.swift     # Search bar with suggestions
│   │   ├── QuantityControl.swift
│   │   └── MuorzCounter.swift  # Currency display component
│   ├── Menu/
│   │   ├── MenuView.swift      # Refactored menu view
│   │   ├── Filters/
│   │   │   └── FilterHeader.swift
│   │   └── ItemRow/
│   │       ├── MenuItemRow.swift
│   │       ├── MenuItemInfo.swift
│   │       ├── NutritionTag.swift
│   │       └── NutritionTagsSection.swift
│   ├── History/
│   │   ├── ScannedMenuHistoryView.swift  # History list view
│   │   └── ScannedMenuCard.swift         # Menu cards with rating system
│   ├── Selection/
│   └── Settings/
└── Assets.xcassets/
```

### Data Models

#### MenuItem (Internal Format)
```swift
struct MenuItem: Identifiable, Codable {
    let id = UUID()
    let originalName: String        // Original name (any language)
    let translatedName: String      // Translated name (English)
    let ingredientsEn: [String]     // Ingredients in English
    let categoryEn: String          // Category (normalized to lowercase)
    let price: String?              // Price as formatted string
    let nutritionScores: NutritionScores  // Validated scores (0-10)
    let tags: DietaryTags          // Validated dietary preferences
}

struct NutritionScores: Codable, Equatable {
    let protein: Int  // 0-10 scale
    let fat: Int      // 0-10 scale
    let carbs: Int    // 0-10 scale
}

struct DietaryTags: Codable, Equatable {
    let vegetarian: Bool
    let vegan: Bool
    let glutenFree: Bool
    let dairyFree: Bool
}
```

#### Gemini API Format
```json
{
  "currency": "€",
  "categories": [
    {
      "name": "starter",
      "dishes": [
        {
          "original_name": "PIZZA VEGETARIANA",
          "translated_name": "Vegetarian Pizza",
          "ingredients_en": ["tomato", "mozzarella", "vegetables"],
          "price": 12.50,
          "nutrition_scores": [5, 6, 7],
          "dietary_tags": [1, 0, 0, 0]
        }
      ]
    }
  ]
}
```

#### Data Flow
1. **OCR Text** → Gemini API processes raw menu text
2. **API Response** → Validated and converted to internal format
3. **Internal Model** → Used throughout the app for display and filtering
4. **User Interface** → Displays validated data with proper formatting

#### Validation Rules
- **Nutrition Scores**: Clamped to 0-10 range
- **Dietary Tags**: Default to false if missing/invalid
- **Categories**: Normalized to lowercase, sorted by standard order
- **Prices**: Converted to Double, currency extracted to top level
- **Ingredients**: Preserved in English, inferred if missing

#### ScannedMenu (SwiftData Model)
```swift
@Model
class ScannedMenu {
    // MARK: - Core Properties
    var id: UUID
    var menuItems: [PersistedMenuItem]
    var currency: String?
    
    // MARK: - Location & Context
    var restaurantName: String?
    var scannedAt: Date
    var latitude: Double?
    var longitude: Double?
    
    // MARK: - User Data
    var notes: String?
    var rating: Int?        // 1-5 stars rating
    var review: String?     // User review text
    var isFavorite: Bool
    var tags: [String]      // Custom tags for organization
    
    // MARK: - Metadata
    var ocrText: String?
    var processingDuration: TimeInterval?
}

@Model
class PersistedMenuItem {
    var id: UUID
    var originalName: String
    var translatedName: String
    var ingredientsEn: [String]
    var categoryEn: String
    var price: String?
    
    // Nutrition scores (0-10 scale)
    var proteinScore: Int
    var fatScore: Int
    var carbsScore: Int
    
    // Dietary tags
    var isVegetarian: Bool
    var isVegan: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
}
```

## Features

### Implemented
- **Camera-First Experience**: Modern camera interface as app entry point
- **Advanced OCR**: Text extraction with multilingual support (FR/EN)
- **Gemini AI Processing**: Google's Gemini 2.0 Flash for intelligent menu parsing
- **Menu History System**: Complete SwiftData-powered menu persistence and history
- **Rating & Reviews**: 5-star rating system with personal notes for each menu
- **Smart Navigation**: Seamless navigation between camera, menu, and history views
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

### Menu History
- **Access**: History button in camera view for quick access
- **Menu Cards**: Beautiful cards showing restaurant name, date, and rating
- **Star Ratings**: Display and edit 5-star ratings with secondary color styling
- **Favorites**: Heart icon to mark/unmark favorite menus
- **Menu Details**: Tap any card to view full menu with same UI as original scan
- **Navigation**: Clean navigation with back buttons and serif typography
- **Automatic Saving**: All scanned menus automatically saved with metadata
- **Rating System**: Rate menus and add personal reviews for future reference
- **Organization**: Menus sorted by scan date with clear visual hierarchy

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
- **SwiftData Persistence**: Automatic menu saving with comprehensive metadata
- **State Management**: Reactive updates using Combine framework
- **Persistence**: User preferences and menu history saved locally

### User Interface
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clear separation of concerns
- **Reactive UI**: Automatic updates based on state changes
- **Accessibility**: VoiceOver support and accessibility labels
- **Dark Mode**: Full support for system appearance modes

## Known Issues

- **Offline Mode**: No offline functionality currently available
- **Menu Export**: No export functionality for menu data

## Roadmap

### High Priority
- [ ] Add offline LLM capabilities (iOS 26 On device Model)
- [ ] Implement menu export and sharing features
- [ ] Add location-based restaurant discovery

### Medium Priority
- [ ] Enhance rating system with detailed categories
- [ ] Add menu comparison features
- [ ] Improve camera interface with manual controls

### Low Priority
- [ ] Implement restaurant discovery
- [ ] Add social sharing of favorite menus
- [ ] B2B Model partnership with restaurants

### Recently Completed ✅
- [x] Implement menu persistence with SwiftData
- [x] Add menu history functionality
- [x] Implement rating and review system
- [x] Add favorites functionality
- [x] Create seamless navigation between views
 
