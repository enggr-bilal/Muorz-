//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI
import Foundation

struct UserInfoHeader: View {
    @Binding var userName: String
    let onNameChange: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            TextField("Your Name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: userName) { _ in
                    onNameChange()
                }
        }
        .padding(.vertical, 8)
    }
}

struct DietaryPreferencePicker: View {
    @Binding var selectedPreference: String?
    
    var body: some View {
        Picker("Dietary Preference", selection: $selectedPreference) {
            Text("None")
                .tag(Optional<String>.none)
            ForEach(UserPreferences.dietaryOptions) { option in
                Label {
                    Text(option.name)
                } icon: {
                    Image(systemName: option.icon)
                        .foregroundColor(.accentColor)
                }
                .tag(Optional(option.id))
            }
        }
    }
}

struct NutritionSortPicker: View {
    @Binding var selectedSortPriority: String
    
    var body: some View {
        Picker("Nutrition Sort Priority", selection: $selectedSortPriority) {
            ForEach(UserPreferences.nutritionSortOptions) { option in
                Label {
                    Text(option.name)
                } icon: {
                    Image(systemName: option.icon)
                        .foregroundColor(.accentColor)
                }
                .tag(option.id)
            }
        }
    }
}

struct NutritionDisplayToggles: View {
    @ObservedObject var preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $preferences.showHighProteinTag) {
                Label {
                    Text("High Protein")
                } icon: {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.blue)
                }
            }
            
            Toggle(isOn: $preferences.showLowFatTag) {
                Label {
                    Text("Low Fat")
                } icon: {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                }
            }
            
            Toggle(isOn: $preferences.showLowCarbsTag) {
                Label {
                    Text("Low Carbs")
                } icon: {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

struct ProfileNavigationLink: View {
    let title: String
    let icon: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            Label(title, systemImage: icon)
        }
    }
}

struct LogoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
        }
    }
} 
