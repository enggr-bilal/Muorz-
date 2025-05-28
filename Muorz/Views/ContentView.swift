//
//  ContentView.swift
//  Muorz'
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences()

    var body: some View {
        CameraView(preferences: preferences)
    }
}
