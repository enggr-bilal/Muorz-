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
                // User Info Section
                Section {
                    UserInfoHeader(
                        userName: $preferences.userName,
                        onNameChange: { preferences.saveUserName() }
                    )
                }
                
                // Default Dietary Preference
                Section(header: Text("Default Dietary Preference")) {
                    DietaryPreferencePicker(selectedPreference: $preferences.defaultDietaryPreference)
                }
                .headerProminence(.increased)
                
                // Default Nutrition Labels
                Section(header: Text("Default Nutrition Labels")) {
                    NutritionPreferenceToggles(
                        selectedPreferences: $preferences.defaultNutritionPreferences,
                        onPreferenceChange: { preferences.saveNutritionPreferences() }
                    )
                }
                .headerProminence(.increased)
                
                // Additional Options
                Section {
                    ProfileNavigationLink(
                        title: "Order History",
                        icon: "clock.arrow.circlepath",
                        destination: AnyView(Text("Order History"))
                    )
                    
                    ProfileNavigationLink(
                        title: "Payment Methods",
                        icon: "creditcard",
                        destination: AnyView(Text("Payment Methods"))
                    )
                    
                    ProfileNavigationLink(
                        title: "Notifications",
                        icon: "bell",
                        destination: AnyView(Text("Notifications"))
                    )
                }
                
                // Logout Button
                Section {
                    LogoutButton {
                        showingLogoutAlert = true
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
