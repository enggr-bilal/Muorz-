# Muorz - Menu OCR & Processing App

An iOS application built with SwiftUI that allows users to photograph restaurant menus, process them with Apple's OCR, and send the data to an API to get a structured and translated version of the menu.

## 🎯 Product Vision

The application allows users to:
- Take photos of restaurant menus
- Automatically extract text with Apple's OCR
- Process text via an API (ChatGPT) to get structured JSON
- Display the menu in a clear and organized way
- Filter and search through dishes and ingredients
- Customize display according to dietary preferences

## 🎯 User Preferences & Filtering System

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

## 🏗️ Architecture

### Project Structure

```
Muorz/
├── Model/
│   ├── MenuItem.swift          # Data models with JSON support
│   ├── FilterModels.swift      # Filter models
│   └── OCRResult.swift         # OCR results
├── ViewModel/
│   ├── MenuViewModel.swift     # Main ViewModel with search
│   ├── MenuService.swift       # API service (ready for integration)
│   ├── OCRViewModel.swift      # Enhanced OCR processing
│   ├── SelectionManager.swift  # Cart management
│   └── UserPreferences.swift   # User preferences
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

#### MenuItem
```swift
struct MenuItem: Identifiable, Codable {
    let originalName: String        // Original name (French)
    let translatedName: String      // Translated name (English)
    let ingredientsEn: [String]     // Ingredients in English
    let categoryEn: String          // Category (starter, main course, dessert)
    let price: String?              // Price (optional)
    let nutritionScores: NutritionScores
    let tags: DietaryTags
}
```

#### API JSON Format
```json
{
  "menu_items": [
    {
      "original_name": "PIZZA VEGETARIANA",
      "translated_name": "Vegetarian Pizza",
      "ingredients_en": ["tomato", "mozzarella", "vegetables"],
      "category_en": "main course",
      "price": "12,00 €",
      "nutrition_scores": {
        "protein": 5,
        "fat": 6,
        "carbs": 7
      },
      "tags": {
        "vegetarian": true,
        "vegan": false,
        "gluten_free": false,
        "dairy_free": false
      }
    }
  ],
  "restaurant_info": {
    "name": "Restaurant Name",
    "cuisine": "Italian",
    "location": "City"
  }
}
```

## 🔍 Features

### ✅ Implemented
- **Camera-First Experience**: Modern camera interface as app entry point
- **Advanced OCR**: Text extraction with multilingual support (FR/EN)
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

### 🚧 Ready for API
- **API Service**: Complete structure for ChatGPT integration
- **Error Handling**: Robust network and API error handling
- **JSON Models**: Automatic mapping with `Codable`
- **Mock Service**: For development and testing

## 🛠️ Usage

### Camera/Lens View
- Entry point of the application
- Camera interface for menu photography
- Real-time OCR processing
- Seamless transition to menu view

### Search
```swift
// Search works on:
// - Dish names (original and translated)
// - Ingredients
// - Automatic suggestions based on available ingredients
// - Real-time highlighting of search terms in results
```

### Filters & Sorting
- **Categories**: All, Starter, Main Course, Dessert
- **Diets**: Vegetarian, Vegan, Gluten-Free, Dairy-Free (temporary override of default)
- **Nutrition Sorting**: Sort by protein, fat, or carbs priority within each section
  - Protein Priority: Higher protein items first
  - Low Fat Priority: Lower fat items first
  - Low Carbs Priority: Lower carbs items first

### User Preferences
- **Default Dietary Filter**: Persistent setting applied on app launch
- **Default Nutrition Sort Priority**: Persistent sorting preference for menu items within sections
- **Nutrition Tag Display**: Controls visibility of nutrition tags (not filtering)
- **Temporary Filters**: Session-based, reset on app restart
- **Temporary Sort Override**: Can temporarily change sorting without affecting default preference

## 🔧 API Integration

### Configuration
```swift
// In MenuService.swift
let menuService = MenuService(
    apiKey: "your-api-key",
    baseURL: "https://your-api-endpoint.com"
)
```

### Expected API Endpoint
```
POST /process-menu
Content-Type: application/json
Authorization: Bearer {api-key}

{
  "ocr_text": "extracted text from image",
  "language": "fr",
  "output_language": "en"
}
```

## 📱 User Interface

### Reusable Components
- **CameraView**: Modern camera interface with multiple states
- **SearchBar**: Search bar with intelligent suggestions
- **FilterHeader**: Horizontal filters with smooth animations
- **MenuItemRow**: Rich dish display with nutrition info
- **NutritionTag**: Color-coded nutritional tags
- **ProcessingView**: Real-time OCR processing feedback
- **ErrorStateView**: Comprehensive error handling with retry
- **SuccessView**: Celebration of successful processing

### Animations
- Smooth transitions between states
- Filter animations
- Visual feedback for interactions

## 🧪 Testing and Development

### Mock Service
```swift
let mockService = MockMenuService()
// Simulates API calls with test data
```

### Test Data
- 8 example dishes with all properties
- Different categories and diets
- Varied nutritional scores

## 🚀 Next Steps

1. **API Integration**: Connect real ChatGPT endpoint
2. **Persistence**: Save processed menus
3. **History**: Keep history of scanned menus
4. **Sharing**: Share menus with other users
5. **Offline**: Offline mode with local cache

## 📋 Improvements Made

### Architecture
- ✅ Clear Model/ViewModel/View separation
- ✅ Dedicated API service
- ✅ Robust error handling
- ✅ Codable support for JSON

### Features
- ✅ Ingredient search
- ✅ Search suggestions
- ✅ Complete interface states
- ✅ Optimized filters
- ✅ Camera integration

### Code Quality
- ✅ Complete documentation
- ✅ Consistent naming
- ✅ Component reusability
- ✅ Asynchronous state management

### User Preferences
- **Default Dietary Filter**: Persistent setting applied on app launch
- **Default Nutrition Sort Priority**: Persistent sorting preference for menu items within sections
- **Nutrition Tag Display**: Controls visibility of nutrition tags (not filtering)
- **Temporary Filters**: Session-based, reset on app restart
- **Temporary Sort Override**: Can temporarily change sorting without affecting default preference

---

**Built with ❤️ in SwiftUI** 