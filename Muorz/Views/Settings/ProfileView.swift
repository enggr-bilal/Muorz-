//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                
                // Default Dietary Preference
                Section(
                    header: Text("Default Dietary Filter"),
                    footer: Text("This filter will be automatically applied when you open the app. You can temporarily change it in the menu view without affecting this default setting.")
                ) {
                    DietaryPreferencePicker(selectedPreference: $preferences.defaultDietaryPreference)
                }
                
                // Default Nutrition Sort Priority
                Section(
                    header: Text("Default Nutrition Sort Priority"),
                    footer: Text("Items within each section will be sorted according to this nutritional priority. This can be temporarily changed in the menu filters.")
                ) {
                    NutritionSortPicker(selectedSortPriority: $preferences.defaultNutritionSortPriority)
                }
               
                // Nutrition Tag Display Settings
                Section(
                    header: Text("Nutrition Tag Display"),
                    footer: Text("Choose which nutrition tags to display on menu items. These toggles only control visibility, not filtering.")
                ) {
                    NutritionDisplayToggles(preferences: preferences)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Preferences")
                        .font(.system(.title2, design: .serif))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Handle logout
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    ProfileView(preferences: UserPreferences())
} 
