//
//  ContentView.swift
//  Muorz'
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var muorzManager = MuorzManager()
    @StateObject private var onboardingState = OnboardingState()

    var body: some View {
        Group {
            if onboardingState.hasCompletedOnboarding {
                // Main app flow
                CameraView(preferences: preferences)
            } else {
                // Onboarding flow
                OnboardingView(
                    preferences: preferences,
                    muorzManager: muorzManager,
                    onComplete: {
                        onboardingState.completeOnboarding()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.5), value: onboardingState.hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
}
