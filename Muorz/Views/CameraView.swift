//
//  CameraView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI
import AVFoundation
import VisionKit

struct CameraView: View {
    @StateObject private var ocrViewModel = OCRViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @ObservedObject var preferences: UserPreferences
    
    @State private var showDocumentScanner = false
    @State private var showMenuView = false
    @State private var hasProcessedMenu = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HeaderView()
                    
                    // Main Content
                    if ocrViewModel.isProcessing {
                        ProcessingView(
                            extractedText: ocrViewModel.extractedText,
                            onCancel: {
                                print("🚫 Processing cancelled, resetting states...")
                                ocrViewModel.clearResults()
                            }
                        )
                    } else if let errorMessage = ocrViewModel.errorMessage {
                        ErrorStateView(
                            message: errorMessage,
                            onRetry: {
                                if !ocrViewModel.capturedImages.isEmpty {
                                    print("🔄 Retrying with captured images...")
                                    ocrViewModel.processAllImages()
                                } else {
                                    print("🔄 No images to retry with - user needs to scan again")
                                }
                            },
                            onStartOver: {
                                print("🔄 Starting over, resetting all states...")
                                ocrViewModel.clearResults()
                            }
                        )
                    } else if let processedMenu = ocrViewModel.processedMenu {
                        SuccessView(
                            menuResponse: processedMenu,
                            onViewMenu: {
                                // Update MenuViewModel with processed data
                                menuViewModel.menuItems = processedMenu.menuItems
                                menuViewModel.restaurantInfo = processedMenu.restaurantInfo
                                showMenuView = true
                            }
                        )
                    } else {
                        // Initial state - Camera interface
                        CameraInterfaceView(
                            showDocumentScanner: $showDocumentScanner,
                            hasProcessedMenu: hasProcessedMenu,
                            hasMenuData: !menuViewModel.menuItems.isEmpty,
                            onViewLastMenu: {
                                showMenuView = true
                            }
                        )
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView { scannedImages in
                    // Directly process scanned images without showing MultiPhotoView
                    print("📄 Received \(scannedImages.count) scanned images, processing directly...")
                    
                    // Clear any previous images and add new ones
                    ocrViewModel.clearResults()
                    for image in scannedImages {
                        ocrViewModel.addImage(image)
                    }
                    
                    // Start processing immediately
                    ocrViewModel.processAllImages()
                }
            }
            .fullScreenCover(isPresented: $showMenuView) {
                MenuView(viewModel: menuViewModel, preferences: preferences)
            }
            .onAppear {
                // 🔑 Setup API key for standalone launches (one-time setup)
                APIConfiguration.setAPIKeyForStandaloneUse()
                
                // 🔑 DIAGNOSTIC COMPLET API Key - pour debugging redémarrage app
                print("🔑 === API KEY DIAGNOSTIC COMPLET ===")
                print("   ProcessInfo environment variables:")
                let allEnvVars = ProcessInfo.processInfo.environment
                for (key, value) in allEnvVars {
                    if key.contains("GEMINI") || key.contains("API") || key.contains("gemini") {
                        print("     \(key): \(value.prefix(15))...")
                    }
                }
                
                print("   Environment GEMINI_API_KEY: \(ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "❌ NOT_FOUND")")
                print("   UserDefaults GEMINI_API_KEY: \(UserDefaults.standard.string(forKey: "GEMINI_API_KEY") ?? "❌ NOT_FOUND")")
                print("   APIConfiguration.geminiAPIKey: \(APIConfiguration.geminiAPIKey.prefix(15))...")
                print("   APIConfiguration.isGeminiAPIConfigured: \(APIConfiguration.isGeminiAPIConfigured)")
                print("   APIConfiguration.useMockService: \(APIConfiguration.useMockService)")
                print("=================================")
                
                // Initialize MenuViewModel with default preferences
                print("🔧 Initializing MenuViewModel with default preferences")
                menuViewModel.initializeWithDefaults(from: preferences)
            }
            .onChange(of: ocrViewModel.processedMenu) { processedMenu in
                if processedMenu != nil {
                    hasProcessedMenu = true
                }
            }
        }
    }
}

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
    @Binding var showDocumentScanner: Bool
    let hasProcessedMenu: Bool
    let hasMenuData: Bool
    let onViewLastMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Camera preview placeholder
            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("Ready to Scan")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .padding(.horizontal, 24)
            
            // Instructions
            VStack(spacing: 16) {
                Text("Scan Menu Pages")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Uses Apple's Document Scanner for professional quality.\nCapture up to 2 pages and proceed to process.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Main capture button
                Button {
                    print("🔘 Capture Page button tapped")
                    showDocumentScanner = true
                    print("   showDocumentScanner set to: \(showDocumentScanner)")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Start Document Scan")
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
                if hasProcessedMenu && hasMenuData {
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
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Document Scanner View (VisionKit) - Limited to 2 pages

struct DocumentScannerView: UIViewControllerRepresentable {
    let onDocumentsScanned: ([UIImage]) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        private let maxPages = 2
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            print("📄 Document scanner finished with \(scan.pageCount) pages")
            
            var scannedImages: [UIImage] = []
            
            // Limit to maxPages (2)
            let pagesToProcess = min(scan.pageCount, maxPages)
            
            for pageIndex in 0..<pagesToProcess {
                let image = scan.imageOfPage(at: pageIndex)
                scannedImages.append(image)
                print("📸 Added page \(pageIndex + 1) - Size: \(image.size)")
            }
            
            if scan.pageCount > maxPages {
                print("⚠️ Limited to \(maxPages) pages (original scan had \(scan.pageCount) pages)")
            }
            
            // Pass scanned images to the callback
            parent.onDocumentsScanned(scannedImages)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("❌ Document scanner failed: \(error.localizedDescription)")
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("🚫 Document scanner cancelled")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    CameraView(preferences: UserPreferences())
} 
