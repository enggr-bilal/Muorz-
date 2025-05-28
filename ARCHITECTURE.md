# Muorz Architecture Documentation

## User Preferences & Filtering System

### Overview

The Muorz app implements a sophisticated preference and filtering system that clearly separates **persistent default settings** from **temporary session filters**. This design ensures that user preferences remain stable while allowing flexible filtering during menu browsing.

## Core Components

### 1. UserPreferences (Persistent Settings)

**Location**: `Muorz/ViewModel/UserPreferences.swift`

**Purpose**: Manages persistent user settings that survive app restarts.

**Properties**:
- `defaultDietaryPreference: String?` - The dietary filter automatically applied on app launch
- `showHighProteinTag: Bool` - Controls visibility of High Protein nutrition tags
- `showLowFatTag: Bool` - Controls visibility of Low Fat nutrition tags  
- `showLowCarbsTag: Bool` - Controls visibility of Low Carbs nutrition tags
- `userName: String` - User's display name

**Key Behaviors**:
- All changes are automatically saved to UserDefaults
- Only modifiable through ProfileView
- Display preferences default to `true` for better UX
- Changes do NOT affect active filters in MenuView

### 2. MenuViewModel (Temporary Filters)

**Location**: `Muorz/ViewModel/MenuViewModel.swift`

**Purpose**: Manages temporary filtering state for the current session.

**Filter Properties**:
- `selectedDietaryPreference: String?` - Current dietary filter (can override default)
- `selectedNutritionPreferences: Set<String>` - Active nutrition filters
- `selectedCategory: String` - Current category filter
- `searchText: String` - Current search query

**Key Behaviors**:
- Filters are initialized with default values on app launch via `initializeWithDefaults()`
- All filter changes are temporary and session-based
- Filters reset to defaults when app restarts
- No automatic synchronization with UserPreferences changes

### 3. ProfileView (Settings Interface)

**Location**: `Muorz/Views/Settings/ProfileView.swift`

**Purpose**: Provides interface for managing persistent default settings.

**Sections**:
- **Default Dietary Filter**: Sets the dietary preference applied on app launch
- **Nutrition Tag Display**: Controls which nutrition tags are visible on menu items

**Key Behaviors**:
- Changes immediately save to UserDefaults
- Does NOT affect current session filters
- Clear separation between defaults and current filters

### 4. MenuView (Filtering Interface)

**Location**: `Muorz/Views/Menu/MenuView.swift`

**Purpose**: Provides interface for temporary filtering during menu browsing.

**Filter Controls**:
- Search button (magnifying glass icon)
- Category filter (All, Starter, Main, Dessert)
- Dietary filter (temporary override)
- Nutrition filters (High Protein, Low Fat, Low Carbs) - **Adaptive based on display preferences**

**Key Behaviors**:
- Filters start with default values from UserPreferences
- All changes are temporary and session-based
- Search terms are highlighted in real-time
- Nutrition tag visibility controlled by UserPreferences
- **Nutrition filter button only appears if at least one nutrition tag is enabled in display preferences**
- **Nutrition filter menu only shows options for enabled tags**

## Data Flow

### App Launch
1. UserPreferences loads saved settings from UserDefaults
2. MenuViewModel initializes with default dietary preference
3. Nutrition filters start empty (no filtering)
4. Menu items display tags based on UserPreferences display settings
5. **FilterHeader adapts nutrition button visibility based on enabled display tags**

### Filter Changes in MenuView
1. User changes filter → MenuViewModel updates
2. Filtered results update immediately
3. UserPreferences remain unchanged
4. Display preferences continue to control tag visibility
5. **Available nutrition filters adapt to display preferences in real-time**

### Settings Changes in ProfileView
1. User changes default → UserPreferences updates
2. Change saves to UserDefaults immediately
3. Current session filters remain unchanged
4. New default applies on next app launch
5. **Nutrition tag display changes immediately affect FilterHeader button visibility**

## Search System

### Search Bar Integration
- Hidden by default in FilterHeader
- Accessible via magnifying glass button
- Replaces filter buttons when active
- "Done" button returns to filter view

### Text Highlighting
- Implemented via `HighlightedText` component
- Highlights search terms in dish names and ingredients
- Uses yellow background with black text
- Case-insensitive matching

### Search Suggestions
- Based on available ingredients in current menu
- Updates dynamically as user types
- Limited to 5 suggestions for performance
- Tappable for quick selection

## Component Relationships

```
UserPreferences (Persistent)
    ↓ (initialize defaults)
MenuViewModel (Temporary)
    ↓ (filter data)
MenuView (Display)
    ↓ (display preferences)
MenuItemRow (Individual items)
```

## Best Practices

### Adding New Preferences
1. Add property to UserPreferences with didSet for auto-save
2. Add UI control in ProfileView
3. Update documentation

### Adding New Filters
1. Add property to MenuViewModel
2. Add filter logic to `filteredItems` computed property
3. Add UI control in FilterHeader
4. Update `clearAllFilters()` method

### Modifying Display Logic
1. Check if change affects defaults (UserPreferences) or session (MenuViewModel)
2. Update appropriate component
3. Ensure proper data flow
4. Test persistence behavior

## Testing Considerations

### Default Preferences
- Test persistence across app restarts
- Verify ProfileView changes save correctly
- Ensure defaults don't affect current session

### Temporary Filters
- Test filter combinations
- Verify reset behavior on app restart
- Ensure independence from defaults

### Search & Highlighting
- Test search suggestions
- Verify text highlighting accuracy
- Test transition between search and filters

This architecture ensures a clear separation of concerns while providing a smooth user experience for both persistent preferences and temporary filtering needs. 