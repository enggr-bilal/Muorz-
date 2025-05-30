//
//  UserPreferences.swift
//  Muorz
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

/// ViewModel responsible for managing user preferences and settings
/// Handles persistent storage of dietary preferences, display settings, and user information
class UserPreferences: ObservableObject {
    
    // MARK: - Default Filter Preferences
    // These preferences are only changeable from ProfileView and persist across app launches
    
    /// Default dietary preference applied to new menu sessions
    @Published var defaultDietaryPreference: String? {
        didSet { saveDietaryPreference() }
    }
    
    /// Default nutrition sorting priority for menu items
    @Published var defaultNutritionSortPriority: String {
        didSet { saveNutritionSortPriority() }
    }
    
    // MARK: - Display Preferences
    // Controls which nutrition tags are shown in the menu interface
    
    /// Whether to show high protein tags on menu items
    @Published var showHighProteinTag: Bool {
        didSet { saveDisplayPreferences() }
    }
    
    /// Whether to show low fat tags on menu items
    @Published var showLowFatTag: Bool {
        didSet { saveDisplayPreferences() }
    }
    
    /// Whether to show low carbs tags on menu items
    @Published var showLowCarbsTag: Bool {
        didSet { saveDisplayPreferences() }
    }
    
    // MARK: - User Information
    
    /// User's display name
    @Published var userName: String
    
    // MARK: - Static Configuration Options
    
    /// Available dietary preference options for user selection
    static let dietaryOptions = [
        PreferenceOption(id: "vegetarian", name: "Vegetarian", icon: "leaf.fill"),
        PreferenceOption(id: "vegan", name: "Vegan", icon: "carrot.fill"),
        PreferenceOption(id: "glutenFree", name: "Gluten Free", icon: "g.circle.fill"),
        PreferenceOption(id: "dairyFree", name: "Dairy Free", icon: "drop.fill")
    ]
    
    /// Available nutrition display tag options
    static let nutritionDisplayOptions = [
        PreferenceOption(id: "protein", name: "High Protein", icon: "figure.strengthtraining.traditional"),
        PreferenceOption(id: "fat", name: "Low Fat", icon: "leaf.fill"),
        PreferenceOption(id: "carbs", name: "Low Carbs", icon: "chart.line.downtrend.xyaxis")
    ]
    
    /// Available nutrition sorting priority options
    static let nutritionSortOptions = [
        PreferenceOption(id: "none", name: "No Priority", icon: "equal.circle"),
        PreferenceOption(id: "protein", name: "Protein Priority", icon: "figure.strengthtraining.traditional"),
        PreferenceOption(id: "fat", name: "Low Fat Priority", icon: "leaf.fill"),
        PreferenceOption(id: "carbs", name: "Low Carbs Priority", icon: "chart.line.downtrend.xyaxis")
    ]
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let defaultDietaryPreference = "defaultDietaryPreference"
        static let defaultNutritionSortPriority = "defaultNutritionSortPriority"
        static let showHighProteinTag = "showHighProteinTag"
        static let showLowFatTag = "showLowFatTag"
        static let showLowCarbsTag = "showLowCarbsTag"
        static let userName = "userName"
    }
    
    // MARK: - Initialization
    
    /// Initializes user preferences by loading saved values from UserDefaults
    init() {
        let defaults = UserDefaults.standard
        
        // Load default dietary preference
        self.defaultDietaryPreference = defaults.string(forKey: Keys.defaultDietaryPreference)
        
        // Load default nutrition sort priority (defaults to "none")
        self.defaultNutritionSortPriority = defaults.string(forKey: Keys.defaultNutritionSortPriority) ?? "none"
        
        // Load display preferences (default to true for better UX)
        self.showHighProteinTag = defaults.object(forKey: Keys.showHighProteinTag) as? Bool ?? true
        self.showLowFatTag = defaults.object(forKey: Keys.showLowFatTag) as? Bool ?? true
        self.showLowCarbsTag = defaults.object(forKey: Keys.showLowCarbsTag) as? Bool ?? true
        
        // Load user information
        self.userName = defaults.string(forKey: Keys.userName) ?? ""
        
        print("⚙️ User preferences loaded")
    }
    
    // MARK: - Public Methods
    
    /// Saves the user's display name to persistent storage
    func saveUserName() {
        UserDefaults.standard.set(userName, forKey: Keys.userName)
        print("👤 User name saved: \(userName)")
    }
    
    /// Resets all preferences to their default values
    func resetToDefaults() {
        defaultDietaryPreference = nil
        defaultNutritionSortPriority = "none"
        showHighProteinTag = true
        showLowFatTag = true
        showLowCarbsTag = true
        userName = ""
        
        // Clear from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.defaultDietaryPreference)
        defaults.removeObject(forKey: Keys.defaultNutritionSortPriority)
        defaults.removeObject(forKey: Keys.showHighProteinTag)
        defaults.removeObject(forKey: Keys.showLowFatTag)
        defaults.removeObject(forKey: Keys.showLowCarbsTag)
        defaults.removeObject(forKey: Keys.userName)
        
        print("🔄 User preferences reset to defaults")
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if any nutrition tags are enabled for display
    var hasNutritionTagsEnabled: Bool {
        return showHighProteinTag || showLowFatTag || showLowCarbsTag
    }
    
    /// Returns the display name for the current dietary preference
    var dietaryPreferenceDisplayName: String? {
        guard let preference = defaultDietaryPreference else { return nil }
        return Self.dietaryOptions.first { $0.id == preference }?.name
    }
    
    /// Returns the display name for the current nutrition sort priority
    var nutritionSortPriorityDisplayName: String {
        return Self.nutritionSortOptions.first { $0.id == defaultNutritionSortPriority }?.name ?? "No Priority"
    }
    
    // MARK: - Private Save Methods
    
    /// Saves the dietary preference to UserDefaults
    private func saveDietaryPreference() {
        if let preference = defaultDietaryPreference {
            UserDefaults.standard.set(preference, forKey: Keys.defaultDietaryPreference)
            print("🥗 Dietary preference saved: \(preference)")
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.defaultDietaryPreference)
            print("🥗 Dietary preference cleared")
        }
    }
    
    /// Saves the nutrition sort priority to UserDefaults
    private func saveNutritionSortPriority() {
        UserDefaults.standard.set(defaultNutritionSortPriority, forKey: Keys.defaultNutritionSortPriority)
        print("📊 Nutrition sort priority saved: \(defaultNutritionSortPriority)")
    }
    
    /// Saves all display preferences to UserDefaults
    private func saveDisplayPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(showHighProteinTag, forKey: Keys.showHighProteinTag)
        defaults.set(showLowFatTag, forKey: Keys.showLowFatTag)
        defaults.set(showLowCarbsTag, forKey: Keys.showLowCarbsTag)
        print("🏷️ Display preferences saved")
    }
}

// MARK: - Supporting Models

/// Represents a user preference option with display information
struct PreferenceOption: Identifiable {
    /// Unique identifier for the preference option
    let id: String
    
    /// Human-readable display name
    let name: String
    
    /// SF Symbol icon name for UI display
    let icon: String
}
