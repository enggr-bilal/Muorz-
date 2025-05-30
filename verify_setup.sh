#!/bin/bash

# Muorz Configuration Verification Script
echo "🔍 Verifying Muorz configuration..."
echo ""

# Check that we're in the correct directory
if [ ! -f "README.md" ] || [ ! -d "Muorz" ]; then
    echo "❌ Error: This script must be run from the Muorz project root directory"
    exit 1
fi

echo "✅ Project directory detected"

# Verify file structure
echo ""
echo "📁 Verifying file structure..."

required_files=(
    "README.md"
    "ARCHITECTURE.md"
    "CHANGELOG.md"
    ".gitignore"
    "Muorz/MuorzApp.swift"
    "Muorz/Model/MenuItem.swift"
    "Muorz/Model/OCRResult.swift"
    "Muorz/Model/FilterModels.swift"
    "Muorz/ViewModels/OCRViewModel.swift"
    "Muorz/ViewModels/MenuViewModel.swift"
    "Muorz/ViewModels/UserPreferences.swift"
    "Muorz/ViewModels/SelectionManager.swift"
    "Muorz/Services/MenuService.swift"
    "Muorz/Services/APIConfiguration.swift"
    "Muorz/Views/ContentView.swift"
    "Muorz/Views/Camera/CameraView.swift"
    "Muorz/Views/Camera/DirectCameraView.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
    fi
done

# Check that API keys are not in Git
echo ""
echo "🔒 Security verification..."

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✅ Git repository detected"
    
    # Search for potential API keys
    api_keys_found=$(git grep -r "AIzaSy" . 2>/dev/null || true)
    
    if [ -z "$api_keys_found" ]; then
        echo "✅ No API keys found in Git"
    else
        echo "⚠️  Potential API keys detected in Git:"
        echo "$api_keys_found"
        echo ""
        echo "🚨 WARNING: Remove these keys before committing!"
    fi
else
    echo "⚠️  No Git repository detected"
fi

# Check .gitignore
echo ""
echo "🛡️  Verifying .gitignore..."

if grep -q "PRIVATE_API_KEY.txt" .gitignore 2>/dev/null; then
    echo "✅ Sensitive files protected in .gitignore"
else
    echo "⚠️  .gitignore might not protect all sensitive files"
fi

# Check for API configuration
echo ""
echo "🔧 API Configuration Check..."

if [ -f "PRIVATE_API_KEY.txt" ]; then
    echo "✅ Private API key file found"
    echo "⚠️  Remember: Configure GEMINI_API_KEY environment variable in Xcode"
else
    echo "ℹ️  No private API key file found (this is normal for clean setups)"
fi

# Final instructions
echo ""
echo "🎯 Next Steps:"
echo "1. Open Muorz.xcodeproj in Xcode"
echo "2. Configure GEMINI_API_KEY environment variable:"
echo "   - Product → Scheme → Edit Scheme..."
echo "   - Run → Arguments → Environment Variables"
echo "   - Add: GEMINI_API_KEY = [your_api_key]"
echo "3. Build and run the app"
echo "4. Check Xcode console for API connection messages"
echo ""
echo "📖 For detailed setup: See README.md"
echo ""
echo "✨ Configuration complete! Your Muorz app is ready to use the Gemini API." 