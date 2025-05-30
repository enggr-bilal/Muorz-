import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.backgroundColor = .black
        
        let previewLayer = cameraManager.makePreviewLayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Add pinch gesture recognizer for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the frame when the view size changes
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraManager: cameraManager)
    }
    
    class Coordinator: NSObject {
        let cameraManager: CameraManager
        
        init(cameraManager: CameraManager) {
            self.cameraManager = cameraManager
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            Task { @MainActor in
                cameraManager.handlePinchGesture(gesture)
            }
        }
    }
}

// MARK: - Zoom Indicator Overlay

struct ZoomIndicatorView: View {
    let zoomFactor: CGFloat
    let isZoomAvailable: Bool
    @State private var showIndicator = false
    
    var body: some View {
        if isZoomAvailable && showIndicator {
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(String(format: "%.1f", zoomFactor))x")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Zoom level bar
                        ZoomLevelBar(currentZoom: zoomFactor, maxZoom: 6.0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.trailing, 20)
                    .padding(.top, 80)
                }
                
                Spacer()
            }
            .allowsHitTesting(false)
            .onChange(of: zoomFactor) { _ in
                showIndicator = true
                
                // Hide indicator after 2 seconds of no zoom changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showIndicator = false
                }
            }
            .onAppear {
                if zoomFactor > 1.01 { // Show if already zoomed
                    showIndicator = true
                }
            }
        }
    }
}

struct ZoomLevelBar: View {
    let currentZoom: CGFloat
    let maxZoom: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * zoomProgress, height: 4)
            }
        }
        .frame(width: 60, height: 4)
    }
    
    private var zoomProgress: CGFloat {
        let normalizedZoom = (currentZoom - 1.0) / (maxZoom - 1.0)
        return max(0, min(1, normalizedZoom))
    }
} 