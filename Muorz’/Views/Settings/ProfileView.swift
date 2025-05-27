//
//  TEST.swift
//  Muorz’
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
                Section(header: Text("Default Dietary Preference"), footer: Text("Menus will be filtered to only show dishes that match your selected diets.")) {
                    DietaryPreferencePicker(selectedPreference: $preferences.defaultDietaryPreference)
                }
               
                
                
                // Default Nutrition Labels
                Section(header: Text("Default Nutrition Labels"), footer: Text("Selected priorities will be displayed with badges to help you spot the right dishes faster.")) {
                    NutritionPreferenceToggles(
                        selectedPreferences: $preferences.defaultNutritionPreferences,
                        onPreferenceChange: { preferences.saveNutritionPreferences() }
                    )
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
