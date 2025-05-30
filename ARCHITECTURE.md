# Muorz Architecture Documentation

## Overview

Muorz follows a clean MVVM (Model-View-ViewModel) architecture with clear separation of concerns. The app is organized into distinct layers: Models for data structures, ViewModels for business logic, Services for external integrations, and Views for user interface components.

## Project Structure

```
Muorz/
├── Model/                          # Data Models
│   ├── MenuItem.swift              # Core menu item model with API support
│   ├── OCRResult.swift             # OCR processing results and metadata
│   └── FilterModels.swift          # Filter and preference models
├── ViewModels/                     # Business Logic Layer
│   ├── OCRViewModel.swift          # OCR processing and multi-photo support
│   ├── MenuViewModel.swift         # Menu data and filtering logic
│   ├── UserPreferences.swift       # Persistent user settings management
│   └── SelectionManager.swift      # Cart and selection management
├── Services/                       # Service Layer
│   ├── MenuService.swift           # Gemini API integration and processing
│   └── APIConfiguration.swift      # API configuration and security
├── Views/                          # User Interface Components
│   ├── ContentView.swift           # Main app coordinator
│   ├── Camera/                     # Camera interface components
│   │   ├── CameraView.swift        # Main camera view and navigation
│   │   ├── DirectCameraView.swift  # Camera controls and capture logic
│   │   └── CameraPreviewView.swift # Camera preview display
│   ├── Menu/                       # Menu browsing interface
│   │   ├── MenuView.swift          # Main menu display and coordination
│   │   ├── Filters/                # Filter components
│   │   └── ItemRow/                # Menu item display components
│   ├── Selection/                  # Cart and selection views
│   ├── Settings/                   # User preferences interface
│   └── Components/                 # Reusable UI components
└── MuorzApp.swift                  # App entry point and configuration
```

## Core Components

### 1. UserPreferences (Persistent Settings)

**Location**: `Muorz/ViewModels/UserPreferences.swift`

**Purpose**: Manages persistent user settings that survive app restarts using UserDefaults.

**Key Properties**:
- `defaultDietaryPreference: String?` - Dietary filter automatically applied on app launch
- `defaultNutritionSortPriority: String` - Default nutrition sorting priority
- `showHighProteinTag: Bool` - Controls visibility of High Protein nutrition tags
- `showLowFatTag: Bool` - Controls visibility of Low Fat nutrition tags  
- `showLowCarbsTag: Bool` - Controls visibility of Low Carbs nutrition tags
- `userName: String` - User's display name

**Key Behaviors**:
- All changes automatically saved to UserDefaults via property observers
- Only modifiable through Settings/ProfileView interface
- Display preferences default to `true` for optimal user experience
- Changes do NOT affect active session filters in MenuView

### 2. MenuViewModel (Session Management)

**Location**: `Muorz/ViewModels/MenuViewModel.swift`

**Purpose**: Manages menu data, filtering, and search functionality for the current session.

**Key Properties**:
- `menuItems: [MenuItem]` - Processed menu items from API
- `searchText: String` - Current search query
- `selectedCategory: String` - Current category filter
- `selectedDietaryPreference: String?` - Session dietary filter (can override default)
- `selectedNutritionSortPriority: String` - Session nutrition sorting priority

**Key Behaviors**:
- Initializes with default values from UserPreferences on app launch
- All filter changes are temporary and session-based
- Provides computed properties for filtered and sorted data
- Filters reset to defaults when app restarts
- No automatic synchronization with UserPreferences changes

### 3. OCRViewModel (Text Processing)

**Location**: `Muorz/ViewModels/OCRViewModel.swift`

**Purpose**: Manages OCR text extraction and API processing workflow.

**Key Features**:
- Multi-photo capture and processing support
- Sequential OCR processing with progress tracking
- Integration with MenuService for AI processing
- Comprehensive error handling and retry logic
- State management for processing workflow

### 4. SelectionManager (Cart Management)

**Location**: `Muorz/ViewModels/SelectionManager.swift`

**Purpose**: Manages user's menu item selections and cart functionality.

**Key Features**:
- Add/remove items with quantity controls
- Price calculation with multi-currency support
- Selection summary and totals
- Validation and bounds checking for quantities

### 5. MenuService (API Integration)

**Location**: `Muorz/Services/MenuService.swift`

**Purpose**: Handles communication with Google Gemini API for menu processing.

**Key Features**:
- Protocol-based design for testability
- Comprehensive error handling with retry logic
- Request/response transformation
- Secure API key management
- Exponential backoff for failed requests

## Data Flow Architecture

### App Launch Sequence
1. **MuorzApp** initializes and presents ContentView
2. **ContentView** creates UserPreferences and presents CameraView
3. **UserPreferences** loads saved settings from UserDefaults
4. **CameraView** initializes OCRViewModel and MenuViewModel
5. **MenuViewModel** initializes with default preferences via `initializeWithDefaults()`

### Menu Processing Flow
1. **User captures photos** in DirectCameraView
2. **OCRViewModel** processes images sequentially using Vision Framework
3. **Combined OCR text** sent to MenuService for AI processing
4. **Gemini API** returns structured menu data
5. **MenuResponse** converted to MenuItem models
6. **MenuViewModel** updates with processed data
7. **UI automatically updates** via reactive bindings

### Filter and Search Flow
1. **User interacts** with filter controls in MenuView
2. **MenuViewModel** updates filter properties
3. **Computed properties** recalculate filtered results
4. **UI updates** automatically via @Published properties
5. **UserPreferences remain unchanged** (session-only changes)

### Settings Management Flow
1. **User changes settings** in ProfileView/Settings
2. **UserPreferences** updates and saves to UserDefaults
3. **Current session filters** remain unchanged
4. **New defaults apply** on next app launch

## User Preferences & Filtering System

### Persistent vs Session State

**Persistent Settings (UserPreferences)**:
- Default dietary preference
- Default nutrition sort priority  
- Nutrition tag display preferences
- User profile information
- Saved to UserDefaults, survive app restarts
- Only changeable through Settings interface

**Session State (MenuViewModel)**:
- Current search query
- Active category filter
- Active dietary filter (can override default)
- Active nutrition sort priority (can override default)
- Reset to defaults on app launch
- Changeable through MenuView interface

### Filter Adaptation System

The app implements an adaptive filter system where available options change based on user preferences:

**Nutrition Filter Visibility**:
- Nutrition filter button only appears if at least one nutrition tag is enabled in display preferences
- Nutrition filter menu only shows options for enabled tags
- This ensures users only see filters for nutrition information they want to track

**Search and Highlighting**:
- Real-time search across dish names, ingredients, and descriptions
- Search terms highlighted in yellow for easy identification
- Intelligent suggestions based on available ingredients
- Debounced input for optimal performance

## Component Relationships

```
UserPreferences (Persistent Storage)
    ↓ (initialize defaults)
MenuViewModel (Session Management)
    ↓ (filter and sort data)
MenuView (Display Coordination)
    ↓ (display preferences)
MenuItemRow (Individual Item Display)
```

## Error Handling Strategy

### Network and API Errors
- Automatic retry with exponential backoff
- User-friendly error messages
- Graceful degradation when API unavailable
- Clear recovery instructions

### OCR Processing Errors
- Individual image failure handling
- Partial success processing (some images succeed)
- Clear feedback on processing status
- Retry mechanisms for failed operations

### Configuration Errors
- API key validation and clear setup instructions
- Environment variable detection
- Fallback mechanisms for development

## Testing Architecture

### Unit Testing Strategy
- ViewModels tested in isolation with mock dependencies
- Service layer tested with mock network responses
- Model validation and transformation testing
- Filter and search logic validation

### Integration Testing
- End-to-end API integration testing
- OCR processing pipeline testing
- Data flow validation across components
- State management consistency testing

## Performance Considerations

### Memory Management
- Efficient image handling for OCR processing
- Proper cleanup of temporary data
- Optimized state management with minimal re-renders

### Search Performance
- Debounced search input (300ms delay)
- Efficient filtering algorithms with early termination
- Cached search suggestions
- Optimized computed properties

### Network Efficiency
- Request batching where possible
- Intelligent retry logic to avoid excessive API calls
- Response caching for repeated requests
- Minimal data transfer with compact API format

## Best Practices

### Adding New Features

**New Persistent Preferences**:
1. Add property to UserPreferences with `didSet` for auto-save
2. Add UI control in Settings/ProfileView
3. Update initialization logic in MenuViewModel
4. Update documentation

**New Session Filters**:
1. Add property to MenuViewModel
2. Add filter logic to computed properties
3. Add UI control in MenuView filter interface
4. Update `clearAllFilters()` method

**New UI Components**:
1. Follow SwiftUI best practices with proper state management
2. Use protocol-oriented design for reusability
3. Implement proper accessibility support
4. Add comprehensive documentation

### Code Quality Standards

- **Separation of Concerns**: Each component has a single, well-defined responsibility
- **Protocol-Oriented Design**: Use protocols for dependency injection and testing
- **Reactive Programming**: Leverage Combine for clean data flow
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Documentation**: All public interfaces thoroughly documented
- **Testing**: Unit and integration tests for critical functionality

This architecture ensures maintainability, testability, and scalability while providing a smooth user experience across all app features. 