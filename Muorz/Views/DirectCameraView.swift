import SwiftUI
import AVFoundation

struct DirectCameraView: View {
    @StateObject private var cameraManager = CameraManager(maxPhotoCount: 2)
    @ObservedObject var ocrViewModel: OCRViewModel
    @ObservedObject var preferences: UserPreferences
    
    @State private var showingProcessedMenu = false
    @State private var showingImageDetail: (image: UIImage, index: Int)?
    
    var body: some View {
        ZStack {
            // Full screen camera preview background
            Color.black
                .ignoresSafeArea()
            
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea(.all)
            }
            
            // Overlay UI elements
            VStack(spacing: 0) {
                Spacer()
                
                // Bottom controls area
                BottomControlsOverlay(
                    cameraManager: cameraManager,
                    onProceed: {
                        processImages()
                    }
                )
                .padding(.bottom, 40)
            }
            
            // Photo stack overlay (bottom left)
            PhotoStackOverlay(
                images: cameraManager.capturedImages,
                onImageTap: { image, index in
                    showingImageDetail = (image, index)
                }
            )
        }
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
    }
    
    private func processImages() {
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
    
    var body: some View {
        Button {
            cameraManager.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                if !cameraManager.canTakeMorePhotos {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!cameraManager.canTakeMorePhotos)
        .opacity(cameraManager.canTakeMorePhotos ? 1.0 : 0.6)
        .scaleEffect(cameraManager.canTakeMorePhotos ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: cameraManager.canTakeMorePhotos)
    }
}

struct ProceedButton: View {
    let isVisible: Bool
    let onProceed: () -> Void
    
    var body: some View {
        Group {
            if isVisible {
                Button {
                    onProceed()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                }
            } else {
                Spacer()
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

struct ProcessedMenuView: View {
    @ObservedObject var ocrViewModel: OCRViewModel
    @ObservedObject var preferences: UserPreferences
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if ocrViewModel.isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Processing menu...")
                            .font(.title2)
                        
                        if !ocrViewModel.extractedText.isEmpty {
                            Text("Extracted text:")
                                .font(.headline)
                                .padding(.top)
                            
                            ScrollView {
                                Text(ocrViewModel.extractedText)
                                    .padding()
                            }
                            .frame(maxHeight: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding()
                        }
                    }
                    .padding()
                } else if let error = ocrViewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Processing failed")
                            .font(.title2)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            ocrViewModel.retryProcessing()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let menu = ocrViewModel.processedMenu {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Menu processed successfully!")
                            .font(.title2)
                        
                        Text("\(menu.menuItems.count) items found")
                        
                        Button("View Menu") {
                            // Navigate to MenuView - you'll need to implement this navigation
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Processing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        ocrViewModel.clearResults()
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Fullscreen Overlay Components

struct BottomControlsOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    let onProceed: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Instruction text
            Text(cameraManager.currentInstructionText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.4))
                .cornerRadius(16)
                .padding(.horizontal, 24)
            
            // Controls row
            HStack(spacing: 20) {
                // Capture button (center)
                CaptureButton(cameraManager: cameraManager)
                
                // Proceed button (right)
                if !cameraManager.capturedImages.isEmpty {
                    ProceedButton(
                        isVisible: true,
                        onProceed: onProceed
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct PhotoStackOverlay: View {
    let images: [UIImage]
    let onImageTap: (UIImage, Int) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(spacing: 12) {
                    ForEach(images.indices, id: \.self) { index in
                        let image = images[index]
                        
                        Button {
                            onImageTap(image, index)
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .zIndex(Double(images.count - index))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.leading, 24)
            .padding(.bottom, 180) // Position above bottom controls
        }
    }
}

// MARK: - Preview

#Preview {
    DirectCameraView(
        ocrViewModel: OCRViewModel(),
        preferences: UserPreferences()
    )
} 
