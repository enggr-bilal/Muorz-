//
//  ContentView.swift
//  Muorz’
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI
import MapKit
struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @StateObject private var viewModel = OCRViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(10)
                        .padding()
                }

                List(viewModel.ocrResults) { result in
                    Text("• \(result.text)")
                }

                Spacer()

                Button("Take Menu Photo") {
                    showImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Menu OCR")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let img = newImage {
                    viewModel.processImage(img)
                }
            }
        }
    }
}
