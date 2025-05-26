//
//  OCRMenuApp.swift
//  Muorz’
//
//  Created by Muhammad Bilal on 12/05/25.
//

import SwiftUI

@main
struct OCRMenuApp: App {
    @StateObject private var preferences = UserPreferences()
    
    var body: some Scene {
        WindowGroup {
            MenuView(preferences: preferences)
        }
    }
}
