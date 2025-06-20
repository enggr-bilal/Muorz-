//
//  OCRMenuApp.swift
//  Muorz'
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI
import SwiftData

@main
struct OCRMenuApp: App {
    @StateObject private var onboardingState = OnboardingState()
    @StateObject private var preferences = UserPreferences()
    @StateObject private var muorzManager = MuorzManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingState.hasCompletedOnboarding {
                    ContentView(
                        preferences: preferences,
                        muorzManager: muorzManager
                    )
                } else {
                    OnboardingView(
                        preferences: preferences,
                        muorzManager: muorzManager,
                        onComplete: {
                            onboardingState.completeOnboarding()
                        }
                    )
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [ScannedMenu.self, PersistedMenuItem.self])
    }
}
