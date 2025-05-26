//
//  TEST.swift
//  Muorz’
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
            ForEach(FilterData.dietFilters) { option in
                Label {
                    Text(option.name)
                } icon: {
                    Image(systemName: option.icon)
                        .foregroundColor(.green)
                }
                .tag(Optional(option.id))
            }
        }
    }
}

struct NutritionPreferenceToggles: View {
    @Binding var selectedPreferences: Set<String>
    let onPreferenceChange: () -> Void
    
    var body: some View {
        ForEach(FilterData.nutritionFilters) { option in
            Toggle(isOn: Binding(
                get: { selectedPreferences.contains(option.tag) },
                set: { isOn in
                    if isOn {
                        selectedPreferences.insert(option.tag)
                    } else {
                        selectedPreferences.remove(option.tag)
                    }
                    onPreferenceChange()
                }
            )) {
                Label {
                    Text(option.name)
                } icon: {
                    Image(systemName: option.icon)
                        .foregroundColor(.accentColor)
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
