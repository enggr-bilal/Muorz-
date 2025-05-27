# Xcode Cleanup Guide - Muorz

This guide helps resolve compilation errors and clean up the Xcode project after refactoring.

## 🚨 Common Issues After Refactoring

### 1. Multiple Commands Produce Error
**Error**: `Multiple commands produce '...SearchBar.stringsdata'` or `...MenuService.stringsdata'`

**Cause**: Duplicate files in the project or Xcode cache issues

**Solution**:
1. Clean the project: `Product` → `Clean Build Folder` (⌘+Shift+K)
2. Delete derived data: `~/Library/Developer/Xcode/DerivedData/Muorz-*`
3. Remove duplicate file references in Xcode

### 2. Type Lookup Ambiguity
**Error**: `'MenuServiceProtocol' is ambiguous for type lookup in this context`

**Cause**: Multiple definitions or import issues

**Solution**: ✅ **FIXED** - Removed duplicate `MenuService.swift` files

## 🧹 Cleanup Steps

### Step 1: Clean Xcode Cache
```bash
# Navigate to project directory
cd /Users/snaud/Documents/Academy/Projects/CHF/Muorz-

# Remove Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Muorz-*

# Clean build folder in Xcode
# Product → Clean Build Folder (⌘+Shift+K)
```

### Step 2: Verify File Structure
Current clean structure:
```
Muorz/
├── Model/
│   ├── MenuItem.swift          ✅
│   ├── FilterModels.swift      ✅
│   └── OCRResult.swift         ✅
├── ViewModel/
│   ├── MenuService.swift       ✅ (Only one)
│   ├── MenuViewModel.swift     ✅
│   ├── OCRViewModel.swift      ✅
│   ├── APIConfiguration.swift  ✅
│   ├── SelectionManager.swift  ✅
│   └── UserPreferences.swift   ✅
├── Views/
│   ├── CameraView.swift        ✅
│   ├── ContentView.swift       ✅
│   ├── Components/
│   │   └── SearchBar.swift     ✅ (Only one)
│   └── Menu/
│       └── MenuView.swift      ✅
```

### Step 3: Remove File References in Xcode
1. Open `Muorz.xcodeproj` in Xcode
2. In the Project Navigator, look for any red (missing) files
3. Right-click on red files → `Delete` → `Move to Trash`
4. Check for duplicate references to the same file

### Step 4: Re-add Files if Necessary
If any files are missing from the project:
1. Right-click on the appropriate folder in Xcode
2. `Add Files to "Muorz"`
3. Navigate to the file and add it
4. Ensure `Target Membership` is set to `Muorz`

### Step 5: Verify Imports
Ensure all files have correct imports:

**OCRViewModel.swift**:
```swift
import Vision
import SwiftUI
import Foundation  // ✅ Added
```

**MenuViewModel.swift**:
```swift
import Foundation
import Combine
```

**MenuService.swift**:
```swift
import Foundation
import Combine
```

## 🔧 Build Settings Check

### Target Settings
1. Select `Muorz` target in Xcode
2. Go to `Build Settings`
3. Search for `Swift Compiler - Language`
4. Ensure `Swift Language Version` is set to `Swift 5`

### Deployment Target
- Minimum iOS version: `15.0`
- Xcode version: `15.0+`

## 🧪 Test Build

After cleanup:
1. Clean build folder: `⌘+Shift+K`
2. Build project: `⌘+B`
3. Run on simulator: `⌘+R`

## 🚨 If Issues Persist

### Reset Xcode Completely
```bash
# Close Xcode completely
# Remove all Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Restart Xcode and open project
```

### Check for Hidden Files
```bash
# Look for hidden duplicate files
find . -name ".*SearchBar*" -o -name ".*MenuService*"

# Remove any found
rm -f ./*SearchBar* ./*MenuService*
```

### Recreate Project (Last Resort)
If all else fails:
1. Create new Xcode project
2. Copy all `.swift` files to new project
3. Add files to project target
4. Configure build settings

## ✅ Success Indicators

Project is clean when:
- [ ] No red files in Project Navigator
- [ ] No duplicate file warnings
- [ ] Clean build succeeds (`⌘+Shift+K` then `⌘+B`)
- [ ] App runs without crashes
- [ ] All imports resolve correctly

## 📱 Final Verification

Test the complete flow:
1. App launches to `CameraView` ✅
2. Camera interface appears ✅
3. Can select photo from picker ✅
4. OCR processing works ✅
5. Menu view displays correctly ✅
6. Search functionality works ✅

---

**After following this guide, your Muorz project should compile and run without errors.** 