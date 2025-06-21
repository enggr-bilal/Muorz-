//
//  CameraView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct CameraView: View {
    @StateObject private var ocrViewModel = OCRViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var muorzManager: MuorzManager
    @Binding var showingHistory: Bool
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannedMenuService: ScannedMenuService
    
    @State private var showMenuView = false
    @State private var hasProcessedMenu = false
    @State private var isReturningFromMenu = false
    
    // MARK: - Initialization
    
    init(preferences: UserPreferences, muorzManager: MuorzManager, showingHistory: Binding<Bool>) {
        self.preferences = preferences
        self.muorzManager = muorzManager
        self._showingHistory = showingHistory
        // Note: scannedMenuService will be properly initialized in onAppear
        self._scannedMenuService = StateObject(wrappedValue: ScannedMenuService.create(with: ModelContext(try! ModelContainer(for: ScannedMenu.self))))
    }
    
    var body: some View {
        ZStack {
            // Use the new DirectCameraView for better UX
            DirectCameraView(
                ocrViewModel: ocrViewModel,
                muorzManager: muorzManager,
                preferences: preferences,
                showingHistory: $showingHistory,
                hasProcessedMenu: hasProcessedMenu && !menuViewModel.menuItems.isEmpty,
                onViewMenu: {
                    showMenuView = true
                }
            )
            .onReceive(ocrViewModel.$processedMenu) { processedMenu in
                if let menu = processedMenu, !menu.menuItems.isEmpty {
                    // Update MenuViewModel with processed data
                    menuViewModel.menuItems = menu.menuItems
                    menuViewModel.restaurantInfo = menu.restaurantInfo
                    menuViewModel.currency = menu.currency
                    hasProcessedMenu = true
                    
                    // 🎯 BUSINESS LOGIC: Deduct Muorz when successfully reaching MenuView with API data
                    let muorzDeducted = muorzManager.deductMuorz()
                    if muorzDeducted {
                        print("💰 Muorz deducted - Menu scan successful")
                    } else {
                        print("⚠️ No Muorz available but allowing scan (shouldn't happen if UI is working correctly)")
                    }
                    
                    // 💾 SAVE MENU TO HISTORY
                    Task {
                        do {
                            try await scannedMenuService.saveScannedMenu(menu)
                            print("✅ Menu saved to history: \(menu.restaurantInfo?.name ?? "Unknown restaurant")")
                        } catch {
                            print("❌ Failed to save menu to history: \(error)")
                        }
                    }
                    
                    showMenuView = true
                    isReturningFromMenu = false
                } else if let menu = processedMenu, menu.menuItems.isEmpty {
                    // Menu exists but is empty - don't show MenuView, let ProcessedMenuView handle the error
                    print("📝 Processed menu is empty - staying in ProcessedMenuView for error handling")
                }
            }
        }
        .fullScreenCover(isPresented: $showMenuView, onDismiss: {
            // When returning from MenuView, mark that we're returning and clear OCR state
            isReturningFromMenu = true
            ocrViewModel.clearResults()
            print("🔄 Returned from MenuView - OCR state cleared for fresh scan")
        }) {
            MenuView(viewModel: menuViewModel, preferences: preferences)
        }
        .onAppear {
            scannedMenuService.updateModelContext(modelContext)
            
            // Reset OCR state when initially appearing or returning from menu
            if isReturningFromMenu {
                ocrViewModel.clearResults()
                isReturningFromMenu = false
                print("🧹 OCR state reset for new scan session")
            }
        }
    }
}

// MARK: - Legacy Views (kept for reference but not used)

// MARK: - Header View

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Muorz")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Scan menus, discover flavors")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
}

// MARK: - Camera Interface View

struct CameraInterfaceView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    let hasProcessedMenu: Bool
    let onViewLastMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Camera preview placeholder
            CameraPreviewPlaceholder(selectedImage: selectedImage)
            
            // Instructions
            VStack(spacing: 16) {
                Text("Point your camera at a menu")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("We'll extract the text and translate it for you")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Main capture button
                Button {
                    showImagePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Scan Menu")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                
                // View last menu button (if available)
                if hasProcessedMenu {
                    Button {
                        onViewLastMenu()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("View Last Menu")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                        .frame(height: 44)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Camera Preview Placeholder

struct CameraPreviewPlaceholder: View {
    let selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray5))
                .frame(height: 300)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(20)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Camera Preview")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let extractedText: String
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Processing animation
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("Processing Menu...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Extracting text and translating content")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Extracted text preview (if available)
            if !extractedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Extracted Text:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        Text(extractedText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }
            
            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    let onStartOver: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Processing Failed")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button("Try Again") {
                    onRetry()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue)
                .cornerRadius(12)
                
                Button("Scan New Menu") {
                    onStartOver()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(height: 44)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Success View

struct SuccessView: View {
    let menuResponse: MenuResponse
    let onViewMenu: () -> Void
    let onScanAnother: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Menu Processed!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let restaurantInfo = menuResponse.restaurantInfo,
                   let name = restaurantInfo.name {
                    Text(name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("\(menuResponse.menuItems.count) items found")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button("View Menu") {
                    onViewMenu()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                
                Button("Scan Another Menu") {
                    onScanAnother()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(height: 44)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView(preferences: UserPreferences(), muorzManager: MuorzManager(), showingHistory: .constant(false))
} 