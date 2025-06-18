//
//  ContentView.swift
//  Muorz'
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var muorzManager = MuorzManager()
    @State private var showingHistory = false
    
    var body: some View {
        NavigationStack {
            CameraView(preferences: preferences, muorzManager: muorzManager, showingHistory: $showingHistory)
                .navigationDestination(isPresented: $showingHistory) {
                    ScannedMenuHistoryView(preferences: preferences)
                        .navigationBarBackButtonHidden(false)
                }
        }
        .modelContainer(for: ScannedMenu.self, inMemory: false)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScannedMenu.self, inMemory: true)
}
