//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

class UserPreferences: ObservableObject {
    @Published var defaultDietaryPreference: String? {
        didSet {
            saveDietaryPreference()
        }
    }
    @Published var defaultNutritionPreferences: Set<String>
    @Published var userName: String
    
    // Dietary preferences options
    static let dietaryOptions = [
        PreferenceOption(id: "vegetarian", name: "Vegetarian", icon: ""),
        PreferenceOption(id: "vegan", name: "Vegan", icon: ""),
        PreferenceOption(id: "glutenFree", name: "Gluten Free", icon: ""),
        PreferenceOption(id: "dairyFree", name: "Dairy Free", icon: "")
    ]
    
    // Nutrition preferences options
    static let nutritionOptions = [
        PreferenceOption(id: "protein", name: "High Protein", icon: "figure.strengthtraining.traditional"),
        PreferenceOption(id: "fat", name: "Low Fat", icon: "leaf.fill"),
        PreferenceOption(id: "carbs", name: "Low Carbs", icon: "chart.line.downtrend.xyaxis")
    ]
    
    init() {
        // Load saved preferences from UserDefaults
        let defaults = UserDefaults.standard
        self.defaultDietaryPreference = defaults.string(forKey: "defaultDietaryPreference")
        self.defaultNutritionPreferences = Set(defaults.array(forKey: "defaultNutritionPreferences") as? [String] ?? [])
        self.userName = defaults.string(forKey: "userName") ?? ""
    }
    
    private func saveDietaryPreference() {
        if let preference = defaultDietaryPreference {
            UserDefaults.standard.set(preference, forKey: "defaultDietaryPreference")
        } else {
            UserDefaults.standard.removeObject(forKey: "defaultDietaryPreference")
        }
    }
    
    func saveNutritionPreferences() {
        UserDefaults.standard.set(Array(defaultNutritionPreferences), forKey: "defaultNutritionPreferences")
    }
    
    func saveUserName() {
        UserDefaults.standard.set(userName, forKey: "userName")
    }
}

struct PreferenceOption: Identifiable {
    let id: String
    let name: String
    let icon: String
} 
