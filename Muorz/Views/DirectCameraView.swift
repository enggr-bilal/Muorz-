import SwiftUI
import AVFoundation

struct DirectCameraView: View {
    @StateObject private var cameraManager = CameraManager(maxPhotoCount: 2)
    @ObservedObject var ocrViewModel: OCRViewModel
    @ObservedObject var muorzManager: MuorzManager
    @ObservedObject var preferences: UserPreferences
    
    let hasProcessedMenu: Bool
    let onViewMenu: () -> Void
    
    @State private var showingProcessedMenu = false
    @State private var showingImageDetail: (image: UIImage, index: Int)?
    @State private var showingDebugView = false // 🧪 DEBUG STATE
    
    var body: some View {
        ZStack {
            // Full screen camera preview background
            Color.black
                .ignoresSafeArea(.all)
            
            if cameraManager.isCameraReady {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea(.all)
                    .clipped()
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Preparing camera...")
                        .font(.system(.caption, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea(.all)
            }
            
            // Zoom indicator overlay
            ZoomIndicatorView(
                zoomFactor: cameraManager.zoomFactor,
                isZoomAvailable: cameraManager.isZoomAvailable
            )
            
            // Focus indicator overlay
            FocusIndicatorView(cameraManager: cameraManager)
            
            // 🎯 NEW: Muorz Counter in top-right corner
            VStack {
                HStack {
                    // 🧪 DEBUG: Temporary debug button (remove in production)
//                    Button("🧪") {
//                        showingDebugView = true
//                    }
//                    .font(.title2)
//                    .foregroundColor(.orange)
//                    .padding(.top, 60)
//                    .padding(.leading, 20)
                    

                    Spacer()
                    MuorzCounter(
                        muorzManager: muorzManager,
                        onDebugLongPress: {
                            // 🧪 DEBUG: Long press to show debug view
                            showingDebugView = false
                        }
                    )
                    .padding(.top, 60) // Safe area padding
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // Overlay UI elements
            VStack(spacing: 0) {
                Spacer()
                
                // Bottom controls area
                BottomControlsOverlay(
                    cameraManager: cameraManager,
                    muorzManager: muorzManager,
                    onProceed: {
                        processImages()
                    },
                    hasProcessedMenu: hasProcessedMenu,
                    onViewMenu: onViewMenu
                )
                .padding(.bottom, 50) // Safe area padding
            }
            
            // Photo stack overlay (bottom left, aligned with capture button)
            PhotoStackOverlay(
                images: cameraManager.capturedImages,
                onImageTap: { image, index in
                    showingImageDetail = (image, index)
                },
                onRemoveImage: { index in
                    cameraManager.removeImage(at: index)
                }
            )
        }
        .ignoresSafeArea(.all) // This should give true fullscreen
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .alert("Camera Error", isPresented: $cameraManager.showingAlert) {
            Button("OK") { }
        } message: {
            Text(cameraManager.alertMessage)
        }
        .sheet(item: Binding<IdentifiableImageWithIndex?>(
            get: { 
                showingImageDetail.map { 
                    IdentifiableImageWithIndex(image: $0.image, index: $0.index) 
                } 
            },
            set: { _ in showingImageDetail = nil }
        )) { item in
            ImageDetailView(
                image: item.image,
                onDismiss: {
                    showingImageDetail = nil
                },
                onDelete: {
                    cameraManager.removeImage(at: item.index)
                    showingImageDetail = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showingProcessedMenu) {
            ProcessedMenuView(
                ocrViewModel: ocrViewModel,
                preferences: preferences,
                onDismiss: {
                    showingProcessedMenu = false
                    cameraManager.clearAllImages()
                }
            )
        }
        .sheet(isPresented: $showingDebugView) {
            DebugView(
                onboardingState: {
                    // Create a temporary OnboardingState for debug purposes
                    let state = OnboardingState()
                    return state
                }(),
                muorzManager: muorzManager,
                preferences: preferences
            )
        }
    }
    
    private func processImages() {
        // 🎯 BUSINESS LOGIC: Check if user can scan before processing
        guard muorzManager.canScan else {
            cameraManager.performHapticFeedback(for: .warning)
            cameraManager.showAlert("No Muorz available. Purchase more to continue scanning.")
            return
        }
        
        guard !cameraManager.capturedImages.isEmpty else { return }
        
        // Optimize images if needed to manage memory
        cameraManager.optimizeImagesIfNeeded()
        
        // Get the best image for processing
        let imageForProcessing: UIImage
        
        if cameraManager.capturedImages.count == 1 {
            imageForProcessing = cameraManager.capturedImages.first!
        } else {
            // Combine multiple images for better OCR results
            guard let combinedImage = cameraManager.combineImagesForOCR() else {
                cameraManager.performHapticFeedback(for: .error)
                cameraManager.showAlert("Failed to process captured images")
                return
            }
            imageForProcessing = combinedImage
        }
        
        // Validate image before processing
        let validationResult = cameraManager.validateImageForOCR(imageForProcessing)
        guard validationResult == .valid else {
            cameraManager.performHapticFeedback(for: .warning)
            cameraManager.showAlert(validationResult.message)
            return
        }
        
        // Enhance image quality for better OCR
        let enhancedImage = cameraManager.enhanceImageForOCR(imageForProcessing)
        
        cameraManager.performHapticFeedback(for: .success)
        ocrViewModel.processImage(enhancedImage)
        showingProcessedMenu = true
    }
}

// MARK: - UI Components

struct CaptureButton: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var muorzManager: MuorzManager
    
    var body: some View {
        Button {
            if muorzManager.canScan {
                cameraManager.capturePhoto()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(muorzManager.canScan ? Color.white : Color.gray.opacity(0.5))
                    .frame(width: 80, height: 80)
                
                if !cameraManager.canTakeMorePhotos {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
                } else if !muorzManager.canScan {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .disabled(!cameraManager.canTakeMorePhotos || !muorzManager.canScan)
        .opacity((cameraManager.canTakeMorePhotos && muorzManager.canScan) ? 1.0 : 0.6)
        .scaleEffect((cameraManager.canTakeMorePhotos && muorzManager.canScan) ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: cameraManager.canTakeMorePhotos)
        .animation(.easeInOut(duration: 0.2), value: muorzManager.canScan)
    }
}

struct ProceedButton: View {
    let isVisible: Bool
    let canProceed: Bool
    let onProceed: () -> Void
    var isLarge: Bool = false
    
    var body: some View {
        Group {
            if isVisible {
                Button {
                    if canProceed {
                        onProceed()
                    }
                } label: {
                    Image(systemName: canProceed ? "arrow.right" : "lock.fill")
                        .font(.system(isLarge ? .title : .title3, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isLarge ? 80 : 60, height: isLarge ? 80 : 60)
                        .background(canProceed ? Color.accentColor : Color.gray)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
                .scaleEffect(canProceed ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.2), value: canProceed)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Supporting Views

struct IdentifiableImageWithIndex: Identifiable {
    let id = UUID()
    let image: UIImage
    let index: Int
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ImageDetailView: View {
    let image: UIImage
    let onDismiss: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - NEW Professional Menu Processing View

struct ProcessedMenuView: View {
    @ObservedObject var ocrViewModel: OCRViewModel
    @ObservedObject var preferences: UserPreferences
    let onDismiss: () -> Void
    
    @State private var currentPhraseIndex = 0
    @State private var displayedText = ""
    @State private var isTyping = false
    @State private var showDebugInfo = false // For debug mode
    @State private var typewriterTimer: Timer?
    
    private let loadingPhrases = [
        "Unfolding your menu like a local…",
        "Checking what's cooking behind the scenes…",
        "Matching dishes to your preferences…",
        "Finding what's safe — and delicious…",
        "Dusting off some hidden gems from the menu…",
        "Almost ready to order with confidence…"
    ]
    
    private var isDebugModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "showDebugDuringProcessing")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same background as rest of app
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                if ocrViewModel.isProcessing {
                    loadingStateView
                } else if let error = ocrViewModel.errorMessage {
                    errorStateView(message: error)
                } else if let menu = ocrViewModel.processedMenu {
                    // Check if menu has items, otherwise show error
                    if menu.menuItems.isEmpty {
                        errorStateView(message: "empty_menu")
                    } else {
                        successStateView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if ocrViewModel.isProcessing {
                startTypewriterAnimation()
            }
        }
        .onDisappear {
            stopTypewriterAnimation()
        }
    }
    
    // MARK: - Loading State
    
    private var loadingStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Title
            Text("Muorz")
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Typewriter Animation Area
            VStack(spacing: 20) {
                Text(displayedText)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3) // Allow up to 3 lines
                    .frame(minHeight: 60) // Minimum height for up to 3 lines
                    .animation(.none, value: displayedText) // Disable animation on text changes
                
                // Subtle progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(0.8)
            }
            
            Spacer()
            
            // Debug toggle (only show when debug mode is enabled)
            if isDebugModeEnabled && showDebugInfo && !ocrViewModel.extractedText.isEmpty {
                debugInfoView
            }
            
            // Cancel button
            Button("Cancel") {
                stopTypewriterAnimation()
                ocrViewModel.clearResults()
                onDismiss()
            }
            .font(.body)
            .foregroundColor(.secondary)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
        .onTapGesture(count: 3) {
            // Triple tap to show debug info (only if debug mode is enabled)
            if isDebugModeEnabled {
                showDebugInfo.toggle()
            }
        }
    }
    
    // MARK: - Success State
    
    private var successStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success animation
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accent)
                
                Text("Buon appetito!")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                
                if let menu = ocrViewModel.processedMenu {
                    Text("\(menu.menuItems.count) delicious options discovered")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                
            }
            
            Spacer()
            
            // Action button
            Button {
                onDismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(.body, weight: .semibold))
                    
                    Text("Explore the menu")
                        .font(.system(.title3, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentColor)
                .cornerRadius(26)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Error State
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                
                VStack(spacing: 12) {
                    Text(message == "empty_menu" ? "This menu seems to be hiding its secrets" : "Something went wrong")
                        .font(.system(.title, design: .serif))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text(message == "empty_menu" ? 
                         "We couldn't find any dishes in this image. Try capturing a clearer photo of the menu, or make sure the text is visible and well-lit." :
                         "Don't worry — even the best chefs have kitchen mishaps. Let's give it another go.")
                    .font(.system(.caption))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button {
                    if message == "empty_menu" {
                        // For empty menu, go back to camera to retake photo
                        ocrViewModel.clearResults()
                        onDismiss()
                    } else {
                        // For other errors, retry processing
                        ocrViewModel.retryProcessing()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: message == "empty_menu" ? "camera.fill" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text(message == "empty_menu" ? "Take New Photo" : "Try Again")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentColor)
                    .cornerRadius(26)
                }
                if message != "empty_menu" {
                    Button("Start Over") {
                        ocrViewModel.clearResults()
                        onDismiss()
                    }
                    .font(.system(.caption))
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Debug Info View
    
    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧪 Debug Info:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            ScrollView {
                Text(ocrViewModel.extractedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Typewriter Animation
    
    private func startTypewriterAnimation() {
        currentPhraseIndex = 0
        displayedText = ""
        isTyping = true
        typeNextCharacter()
    }
    
    private func stopTypewriterAnimation() {
        isTyping = false
        typewriterTimer?.invalidate()
        typewriterTimer = nil
    }
    
    private func updateTypewriterText() {
        guard isTyping else { return }
        // This is handled by the typeNextCharacter method
    }
    
    private func typeNextCharacter() {
        guard isTyping && currentPhraseIndex < loadingPhrases.count else { return }
        
        let currentPhrase = loadingPhrases[currentPhraseIndex]
        
        if displayedText.count < currentPhrase.count {
            // Continue typing current phrase
            let nextIndex = currentPhrase.index(currentPhrase.startIndex, offsetBy: displayedText.count)
            displayedText += String(currentPhrase[nextIndex])
            
            typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                typeNextCharacter()
            }
        } else {
            // Finished current phrase, wait then move to next
            typewriterTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                moveToNextPhrase()
            }
        }
    }
    
    private func moveToNextPhrase() {
        guard isTyping else { return }
        
        currentPhraseIndex += 1
        
        if currentPhraseIndex < loadingPhrases.count {
            // Move to next phrase
            displayedText = ""
            typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                typeNextCharacter()
            }
        } else {
            // All phrases done, cycle back to first
            currentPhraseIndex = 0
            displayedText = ""
            typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                typeNextCharacter()
            }
        }
    }
}

// MARK: - Fullscreen Overlay Components

struct BottomControlsOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var muorzManager: MuorzManager
    let onProceed: () -> Void
    let hasProcessedMenu: Bool
    let onViewMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Instruction text - Only show when user can scan
            if muorzManager.canScan {
                Text(cameraManager.currentInstructionText)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Controls with smooth slide animation
            ZStack {
                if cameraManager.canTakeMorePhotos {
                    // Capture button when photos can still be taken
                    CaptureButton(cameraManager: cameraManager, muorzManager: muorzManager)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Proceed button - position and size changes based on state
                if !cameraManager.capturedImages.isEmpty {
                    HStack {
                        if cameraManager.canTakeMorePhotos {
                            // When can still take photos: proceed button on the right, small size
                            Spacer()
                            Spacer()
                            
                            ProceedButton(
                                isVisible: true,
                                canProceed: muorzManager.canScan,
                                onProceed: onProceed,
                                isLarge: false // Small size when on the right
                            )
                        } else {
                            // When max photos reached: proceed button in center, large size
                            Spacer()
                            
                            ProceedButton(
                                isVisible: true,
                                canProceed: muorzManager.canScan,
                                onProceed: onProceed,
                                isLarge: true // Large size when centered
                            )
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.6), value: cameraManager.canTakeMorePhotos)
                }
                
                // View Menu button overlay positioned to the left
                if hasProcessedMenu && cameraManager.canTakeMorePhotos {
                    HStack {
                        Button {
                            onViewMenu()
                        } label: {
                            Image(systemName: "list.bullet.clipboard.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: 55, height: 55)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                        Spacer() // Extra space to position properly
                    }
                    .padding(.horizontal, 24)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: cameraManager.canTakeMorePhotos)
            .animation(.easeInOut(duration: 0.5), value: cameraManager.capturedImages.count)
        }
        .animation(.easeInOut(duration: 0.3), value: muorzManager.canScan) // Animation for instruction text visibility
    }
}

struct PhotoStackOverlay: View {
    let images: [UIImage]
    let onImageTap: (UIImage, Int) -> Void
    let onRemoveImage: (Int) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 12) {
                    ForEach(images.indices, id: \.self) { index in
                        let image = images[index]
                        
                        ZStack(alignment: .topTrailing) {
                            Button {
                                onImageTap(image, index)
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .zIndex(Double(images.count - index))
                            }
                            
                            // Remove button
                            Button {
                                onRemoveImage(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.leading, 24)
            .padding(.bottom, 200) // Position above the prompt text and controls
        }
    }
}

// MARK: - Focus Indicator

struct FocusIndicatorView: View {
    let cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            if cameraManager.isFocusing, let focusPoint = cameraManager.focusPoint {
                FocusReticle()
                    .position(focusPoint)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.2), value: cameraManager.isFocusing)
                    .animation(.easeInOut(duration: 0.2), value: focusPoint)
                    .onAppear {
                        print("🎯 Focus indicator appeared at: \(focusPoint)")
                    }
            }
        }
        .onReceive(cameraManager.$isFocusing) { isFocusing in
            print("🎯 isFocusing changed to: \(isFocusing)")
        }
        .onReceive(cameraManager.$focusPoint) { focusPoint in
            print("🎯 focusPoint changed to: \(String(describing: focusPoint))")
        }
    }
}

struct FocusReticle: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer square
            Rectangle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: 80, height: 80)
                .scaleEffect(isAnimating ? 0.8 : 1.0)
            
            // Inner crosshairs
            VStack {
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 20)
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2, height: 20)
            }
            .offset(y: isAnimating ? 0 : -10)
            
            HStack {
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 20, height: 2)
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 20, height: 2)
            }
            .offset(x: isAnimating ? 0 : -10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DirectCameraView(
        ocrViewModel: OCRViewModel(),
        muorzManager: MuorzManager(),
        preferences: UserPreferences(),
        hasProcessedMenu: false,
        onViewMenu: {}
    )
} 
