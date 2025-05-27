# App Flow Guide - Muorz

This guide explains the complete user flow of the Muorz application, from camera capture to menu browsing.

## 🎯 Application Flow Overview

```
CameraView (Entry Point)
    ↓
Photo Capture
    ↓
OCR Processing
    ↓
API Processing (ChatGPT)
    ↓
MenuView (Structured Menu)
    ↓
Search & Filter
    ↓
Selection & Cart
```

## 📱 Screen-by-Screen Flow

### 1. CameraView - Entry Point

**Purpose**: Main entry point for menu scanning
**File**: `Muorz/Views/CameraView.swift`

#### States:
- **Initial State**: Camera interface with scan button
- **Processing State**: OCR and API processing with progress
- **Success State**: Menu processed successfully
- **Error State**: Processing failed with retry options

#### Key Features:
- Modern gradient background
- Camera preview placeholder
- Clear call-to-action buttons
- Processing feedback with extracted text preview
- Error handling with retry mechanisms

#### User Actions:
- Tap "Scan Menu" → Opens camera/photo picker
- Select photo → Automatic OCR processing
- View processed menu → Navigate to MenuView
- Scan another menu → Reset to initial state

### 2. OCR Processing Flow

**Purpose**: Extract text from menu images
**File**: `Muorz/ViewModel/OCRViewModel.swift`

#### Process:
1. **Image Capture**: User selects photo from camera/gallery
2. **OCR Extraction**: Apple Vision framework extracts text
3. **Text Processing**: Combine extracted text lines
4. **API Call**: Send text to ChatGPT for structuring
5. **Result Handling**: Parse JSON response or handle errors

#### Visual Feedback:
- Progress indicator during processing
- Extracted text preview (if available)
- Success/error states with appropriate messaging

### 3. MenuView - Structured Display

**Purpose**: Display processed menu with search and filters
**File**: `Muorz/Views/Menu/MenuView.swift`

#### Features:
- **Search Bar**: Search in dish names and ingredients
- **Filter Header**: Category, dietary, and nutrition filters
- **Menu List**: Organized by categories
- **Selection Management**: Add items to cart
- **State Management**: Loading, error, empty states

#### User Actions:
- Search for specific ingredients or dishes
- Apply filters (vegetarian, gluten-free, etc.)
- Add items to selection/cart
- View item details and nutrition info

## 🔄 State Management

### CameraView States

```swift
enum CameraViewState {
    case initial           // Ready to scan
    case processing       // OCR + API processing
    case success(MenuResponse)  // Menu processed
    case error(String)    // Processing failed
}
```

### MenuView States

```swift
enum MenuViewState {
    case loading          // Loading menu data
    case loaded([MenuItem])  // Menu items available
    case empty            // No items match filters
    case error(String)    // Error loading data
}
```

## 🎨 UI/UX Design Principles

### Visual Hierarchy
1. **Primary Actions**: Large, prominent buttons with gradients
2. **Secondary Actions**: Smaller, text-based buttons
3. **Status Indicators**: Clear icons and colors for states
4. **Content Organization**: Grouped by categories with clear headers

### Color Scheme
- **Primary**: Blue to purple gradient for main actions
- **Success**: Green for completed states
- **Error**: Orange/red for error states
- **Neutral**: System grays for backgrounds and secondary text

### Typography
- **Headers**: Bold, rounded fonts for app branding
- **Body Text**: System fonts for readability
- **Actions**: Semibold weights for button text

## 🔧 Technical Implementation

### Navigation Flow

```swift
ContentView
└── CameraView (Entry Point)
    ├── ImagePicker (Sheet)
    └── MenuView (Full Screen Cover)
        ├── SearchBar
        ├── FilterHeader
        ├── MenuListView
        └── SelectionView (Sheet)
```

### Data Flow

```swift
CameraView
├── OCRViewModel
│   ├── processImage()
│   ├── extractedText
│   └── processedMenu
└── MenuViewModel
    ├── menuItems (from OCR)
    ├── searchText
    ├── filters
    └── filteredItems
```

### Service Integration

```swift
OCRViewModel
└── MenuService
    ├── processOCRText() → API Call
    └── MenuResponse → Structured Data
```

## 📊 User Experience Metrics

### Key Performance Indicators
- **OCR Accuracy**: % of text correctly extracted
- **Processing Time**: Average time from photo to menu
- **User Retention**: % of users who complete the flow
- **Search Usage**: % of users who use search functionality

### Success Criteria
- OCR processing completes in < 10 seconds
- API response time < 5 seconds
- Search results appear instantly
- Smooth transitions between states

## 🚀 Future Enhancements

### Planned Features
1. **Real Camera Preview**: Live camera feed instead of photo picker
2. **Offline Mode**: Cache processed menus for offline viewing
3. **Menu History**: Save and revisit previously scanned menus
4. **Social Features**: Share menus with friends
5. **Recommendations**: AI-powered dish recommendations

### Technical Improvements
1. **Caching**: Implement response caching for faster loading
2. **Background Processing**: Process images in background
3. **Batch Processing**: Handle multiple menu pages
4. **Quality Detection**: Detect image quality before processing

## 🔍 Testing Strategy

### Unit Tests
- OCR text extraction accuracy
- Menu item filtering logic
- Search functionality
- State management

### Integration Tests
- Complete flow from photo to menu
- API integration with mock responses
- Error handling scenarios
- Performance under load

### User Testing
- Usability testing with real menus
- Accessibility testing
- Performance testing on various devices
- A/B testing for UI improvements

## 📱 Platform Considerations

### iOS Compatibility
- **Minimum iOS**: 15.0 (for modern SwiftUI features)
- **Camera Permissions**: Required for photo capture
- **Network Access**: Required for API calls
- **Storage**: Minimal local storage for preferences

### Device Support
- **iPhone**: Primary target (all sizes)
- **iPad**: Responsive design adapts to larger screens
- **Accessibility**: VoiceOver and Dynamic Type support

---

**This flow ensures a smooth, intuitive experience from menu scanning to dish selection.** 