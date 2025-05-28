//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

class UserPreferences: ObservableObject {
    // MARK: - Default Values (only changeable from ProfileView)
    @Published var defaultDietaryPreference: String? {
        didSet {
            saveDietaryPreference()
        }
    }
    
    // MARK: - Display Preferences (toggles for showing/hiding tags)
    @Published var showHighProteinTag: Bool {
        didSet {
            saveDisplayPreferences()
        }
    }
    @Published var showLowFatTag: Bool {
        didSet {
            saveDisplayPreferences()
        }
    }
    @Published var showLowCarbsTag: Bool {
        didSet {
            saveDisplayPreferences()
        }
    }
    
    // MARK: - User Info
    @Published var userName: String
    
    // MARK: - Static Options
    static let dietaryOptions = [
        PreferenceOption(id: "vegetarian", name: "Vegetarian", icon: "leaf.fill"),
        PreferenceOption(id: "vegan", name: "Vegan", icon: "carrot.fill"),
        PreferenceOption(id: "glutenFree", name: "Gluten Free", icon: "g.circle.fill"),
        PreferenceOption(id: "dairyFree", name: "Dairy Free", icon: "drop.fill")
    ]
    
    static let nutritionDisplayOptions = [
        PreferenceOption(id: "protein", name: "High Protein", icon: "figure.strengthtraining.traditional"),
        PreferenceOption(id: "fat", name: "Low Fat", icon: "leaf.fill"),
        PreferenceOption(id: "carbs", name: "Low Carbs", icon: "chart.line.downtrend.xyaxis")
    ]
    
    init() {
        let defaults = UserDefaults.standard
        
        // Load default dietary preference
        self.defaultDietaryPreference = defaults.string(forKey: "defaultDietaryPreference")
        
        // Load display preferences (default to true for better UX)
        self.showHighProteinTag = defaults.object(forKey: "showHighProteinTag") as? Bool ?? true
        self.showLowFatTag = defaults.object(forKey: "showLowFatTag") as? Bool ?? true
        self.showLowCarbsTag = defaults.object(forKey: "showLowCarbsTag") as? Bool ?? true
        
        // Load user info
        self.userName = defaults.string(forKey: "userName") ?? ""
    }
    
    // MARK: - Save Methods
    
    private func saveDietaryPreference() {
        if let preference = defaultDietaryPreference {
            UserDefaults.standard.set(preference, forKey: "defaultDietaryPreference")
        } else {
            UserDefaults.standard.removeObject(forKey: "defaultDietaryPreference")
        }
    }
    
    private func saveDisplayPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(showHighProteinTag, forKey: "showHighProteinTag")
        defaults.set(showLowFatTag, forKey: "showLowFatTag")
        defaults.set(showLowCarbsTag, forKey: "showLowCarbsTag")
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
