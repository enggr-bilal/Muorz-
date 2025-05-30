import AVFoundation
import UIKit
import SwiftUI

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var capturedImages: [UIImage] = []
    @Published var isCameraReady = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    // Camera session
    private var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // Configuration
    let maxPhotoCount: Int
    
    init(maxPhotoCount: Int = 2) {
        self.maxPhotoCount = maxPhotoCount
        super.init()
        Task {
            await requestCameraPermission()
        }
    }
    
    var canTakeMorePhotos: Bool {
        capturedImages.count < maxPhotoCount
    }
    
    var currentInstructionText: String {
        if capturedImages.isEmpty {
            return "Take a picture of the menu"
        } else if capturedImages.count == 1 {
            return "Add more photos or tap 'Proceed'"
        } else if canTakeMorePhotos {
            return "Ready for the next capture (\(capturedImages.count)/\(maxPhotoCount))"
        } else {
            return "Maximum photos reached - tap 'Proceed'"
        }
    }
    
    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await setupCamera()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await setupCamera()
            } else {
                showAlert("Camera access denied")
            }
        case .denied, .restricted:
            showAlert("Camera access is required to scan menus")
        @unknown default:
            showAlert("Unknown camera permission status")
        }
    }
    
    private func setupCamera() async {
        captureSession.beginConfiguration()
        
        // Configure session preset for high quality preview
        // Use high quality for preview but we'll optimize capture separately
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        } else if captureSession.canSetSessionPreset(.medium) {
            captureSession.sessionPreset = .medium
        } else {
            captureSession.sessionPreset = .photo
        }

        // Add video input with autofocus
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showAlert("Unable to access camera")
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Configure autofocus and other camera settings
                try configureVideoDevice(videoDevice)
            } else {
                showAlert("Couldn't add video device input to the session")
                return
            }
        } catch {
            showAlert("Couldn't create video device input: \(error)")
            return
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            // Keep some quality for OCR but not excessive
            photoOutput.isHighResolutionCaptureEnabled = false
            if #available(iOS 13.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .balanced
            }
        } else {
            showAlert("Could not add photo output to the session")
            return
        }

        captureSession.commitConfiguration()
        isCameraReady = true
    }
    
    private func configureVideoDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        // Enable autofocus
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        } else if device.isFocusModeSupported(.autoFocus) {
            device.focusMode = .autoFocus
        }
        
        // Enable auto exposure
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        } else if device.isExposureModeSupported(.autoExpose) {
            device.exposureMode = .autoExpose
        }
        
        // Enable auto white balance
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
        
        // Set video stabilization if available
        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        Task {
            captureSession.startRunning()
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        Task {
            captureSession.stopRunning()
        }
    }
    
    func capturePhoto() {
        guard canTakeMorePhotos else {
            performHapticFeedback(for: .warning)
            showAlert("Maximum number of photos reached (\(maxPhotoCount))")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        
        // Configure for optimal OCR processing
        settings.isHighResolutionPhotoEnabled = false // Smaller file size
        
        // Optimize for quality vs speed balance
        if #available(iOS 13.0, *) {
            settings.photoQualityPrioritization = .balanced
        }
        
        performHapticFeedback(for: .capture)
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func removeImage(at index: Int) {
        guard index < capturedImages.count else { return }
        capturedImages.remove(at: index)
    }
    
    func clearAllImages() {
        capturedImages.removeAll()
    }
    
    func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // Preview layer
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            showAlert("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showAlert("Failed to process captured image")
            return
        }
        
        // Add captured image to the array
        capturedImages.append(image)
    }
} 