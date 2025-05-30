//
//  ContentView.swift
//  Muorz
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

/// Main content view that serves as the navigation coordinator for the Muorz app
/// Initializes core dependencies and presents the primary camera scanning interface
struct ContentView: View {
    /// User preferences for dietary filters, language settings, and app configuration
    @StateObject private var preferences = UserPreferences()

    var body: some View {
        CameraView(preferences: preferences)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
