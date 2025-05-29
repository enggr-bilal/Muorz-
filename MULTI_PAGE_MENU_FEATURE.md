# 📄 Multi-Page Menu Feature

## 🎯 Overview

The Muorz app now supports scanning multiple pages of menus, allowing users to capture complete restaurant menus that span several pages and process them as a single, comprehensive menu.

## ✨ Key Features

### 📸 Multi-Photo Capture
- **Sequential Capture**: Take multiple photos one after another
- **Visual Collection**: See all captured pages in a grid layout
- **Page Management**: Add or remove individual pages
- **Clear Workflow**: Intuitive interface for multi-page scanning

### 🔄 Combined OCR Processing
- **Sequential Processing**: OCR processes each page individually
- **Text Combination**: Combines text from all pages with clear page separators
- **Progress Tracking**: Shows which page is currently being processed
- **Error Handling**: Continues processing even if some pages fail

### 🧠 Enhanced AI Processing
- **Context Awareness**: Gemini API receives combined text with page markers
- **Complete Menu Understanding**: AI can understand menu structure across multiple pages
- **Category Organization**: Properly categorizes items from all pages
- **Relationship Detection**: Understands connections between pages

## 🎨 User Interface

### Initial Capture Screen
- **Updated Instructions**: "Scan your menu pages" with multi-page guidance
- **Capture Button**: "Capture Page" instead of "Scan Menu"
- **Clear Workflow**: Users understand they can capture multiple pages

### Multi-Photo Management Screen
- **Header**: Shows total number of captured pages
- **Image Grid**: 2-column grid showing all captured pages
- **Page Numbers**: Each image labeled as "Page 1", "Page 2", etc.
- **Remove Functionality**: X button on each image to remove individual pages
- **Processing Indicators**: Visual feedback during OCR processing

### Action Controls
- **Process All Pages**: Main action button with gradient styling
- **Add Page**: Secondary button to capture additional pages
- **Clear All**: Destructive action to start over
- **Text Preview**: Shows combined OCR text when available

## 🔧 Technical Implementation

### Data Structure
```swift
@Published var capturedImages: [UIImage] = []
@Published var combinedOCRText = ""
@Published var currentProcessingIndex = 0
@Published var individualOCRResults: [String] = []
```

### Processing Flow
1. **Image Collection**: Users capture multiple images sequentially
2. **Batch Processing**: All images processed when user clicks "Process All Pages"
3. **Sequential OCR**: Each image processed individually with progress tracking
4. **Text Combination**: OCR results combined with page separators
5. **API Processing**: Combined text sent to Gemini API as single request

### Text Format
```
=== PAGE 1 ===
[OCR text from first page]

=== PAGE 2 ===
[OCR text from second page]

=== PAGE 3 ===
[OCR text from third page]
```

## 🚀 User Workflow

### Standard Multi-Page Workflow
1. **Tap "Capture Page"** → Take photo of first menu page
2. **Tap "Add Page"** → Take photo of second menu page
3. **Repeat** for additional pages as needed
4. **Review** captured pages in grid view
5. **Remove** any incorrect/blurry pages if needed
6. **Tap "Process All Pages"** → Wait for OCR and AI processing
7. **View Menu** → See complete processed menu

### Single Page Workflow (Still Supported)
1. **Tap "Capture Page"** → Take photo of menu
2. **Tap "Process All Pages"** → Process single page
3. **View Menu** → See processed menu

## 📊 Benefits

### For Users
- **Complete Menu Capture**: No need to worry about large menus
- **Flexible Workflow**: Can add pages incrementally
- **Quality Control**: Can remove poor quality images before processing
- **Clear Progress**: Visual feedback during processing
- **Better Results**: AI understands complete menu context

### For Restaurants
- **Comprehensive Coverage**: Full menu representation
- **Better Organization**: AI can understand menu structure across pages
- **Accurate Categorization**: Items properly grouped even across page boundaries

## 🔄 State Management

### View States
1. **Initial State**: Camera interface (no images captured)
2. **Multi-Photo State**: Grid view with captured images and controls
3. **Processing State**: Progress indicators and disabled controls
4. **Success State**: Processed menu results
5. **Error State**: Error handling with retry options

### Data Flow
- **CameraView**: Main container managing state transitions
- **OCRViewModel**: Handles image collection and processing logic
- **MultiPhotoView**: Dedicated UI for multi-page management
- **CapturedImageCard**: Individual image display with controls

## 🐛 Error Handling

### Individual Page Failures
- Processing continues even if some pages fail OCR
- Failed pages logged but don't stop overall processing
- Users can remove failed pages and retry

### Network Failures
- Combined text processed only if at least one page succeeds
- Standard retry logic applies to final API call
- Clear error messages for different failure types

## 🔮 Future Enhancements

### Potential Improvements
- **Page Reordering**: Drag and drop to reorder pages
- **Live Preview**: Real-time camera preview for better capture
- **Auto-Detection**: Automatic detection of menu pages vs other content
- **Page Optimization**: Automatic image enhancement for better OCR
- **Batch Export**: Export all pages as PDF or images

### Advanced Features
- **Smart Cropping**: Automatic menu boundary detection
- **Language Detection**: Per-page language detection for better OCR
- **Menu Validation**: AI-powered detection of incomplete captures
- **Restaurant Recognition**: Automatic restaurant info extraction

## 📈 Performance Considerations

### Optimization Strategies
- **Sequential Processing**: Prevents memory overload with large images
- **Image Compression**: Optimize images before OCR processing
- **Memory Management**: Clear processed images from memory when done
- **Progress Feedback**: Keep users engaged during long processing times

### Resource Usage
- **Memory**: Limited by device capabilities, images cleared after processing
- **Network**: Single API call with combined text (efficient)
- **Processing Time**: Scales linearly with number of pages
- **Storage**: Temporary storage only, no persistent image storage

---

**The multi-page menu feature transforms Muorz from a single-page scanner into a comprehensive menu digitization tool, enabling capture and processing of complete restaurant menus regardless of their size or complexity.** 