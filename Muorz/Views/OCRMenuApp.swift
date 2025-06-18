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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [ScannedMenu.self, PersistedMenuItem.self])
    }
}
