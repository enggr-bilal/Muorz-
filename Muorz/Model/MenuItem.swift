//
//  MenuItem.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

// MARK: - API Response Models

/// Root response structure from Gemini API containing menu categories
struct GeminiMenuResponse: Codable {
    let categories: [MenuCategory]
    
    /// Custom decoder to handle array directly from API response
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.categories = try container.decode([MenuCategory].self)
    }
    
    /// Custom encoder for API compatibility
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(categories)
    }
}

/// Menu category structure from API response
struct MenuCategory: Codable {
    let categoryName: String
    let dishes: [APIDish]
    
    enum CodingKeys: String, CodingKey {
        case categoryName = "ctg"
        case dishes = "dsh"
    }
}

/// Dish structure from API response using compact format for efficiency
struct APIDish: Codable {
    let originalName: String
    let translatedName: String
    let ingredients: [String]
    let nutritionScores: [Int] // [protein, fat, carbs]
    let tags: [Int] // [vegetarian, vegan, gluten_free, dairy_free] as 0/1
    let price: String
    
    enum CodingKeys: String, CodingKey {
        case originalName = "nme"
        case translatedName = "tr_nme"
        case ingredients = "ingr"
        case nutritionScores = "n_scr"
        case tags = "tgs"
        case price = "prc"
    }
}

// MARK: - Core App Models

/// Core menu item model used throughout the application
/// Represents a single dish with all its properties and metadata
struct MenuItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let originalName: String
    let translatedName: String
    let ingredientsEn: [String]
    let categoryEn: String
    let price: String?
    let nutritionScores: NutritionScores
    let tags: DietaryTags
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case translatedName = "translated_name"
        case ingredientsEn = "ingredients_en"
        case categoryEn = "category_en"
        case price
        case nutritionScores = "nutrition_scores"
        case tags
    }
    
    // MARK: - Initializers
    
    /// Standard initializer for manual creation
    /// - Parameters:
    ///   - originalName: Original dish name in source language
    ///   - translatedName: Translated dish name in user's language
    ///   - ingredientsEn: List of ingredients in English
    ///   - categoryEn: Category name in English
    ///   - price: Optional price string
    ///   - nutritionScores: Nutrition scoring information
    ///   - tags: Dietary restriction tags
    init(
        originalName: String,
        translatedName: String,
        ingredientsEn: [String],
        categoryEn: String,
        price: String?,
        nutritionScores: NutritionScores,
        tags: DietaryTags
    ) {
        self.originalName = originalName
        self.translatedName = translatedName
        self.ingredientsEn = ingredientsEn
        self.categoryEn = categoryEn
        self.price = price
        self.nutritionScores = nutritionScores
        self.tags = tags
    }
    
    /// Initializer from API dish response
    /// Converts compact API format to full MenuItem structure
    /// - Parameters:
    ///   - apiDish: Dish data from API response
    ///   - category: Category name for this dish
    init(from apiDish: APIDish, category: String) {
        self.originalName = apiDish.originalName
        self.translatedName = apiDish.translatedName
        self.ingredientsEn = apiDish.ingredients
        self.categoryEn = category.lowercased()
        self.price = apiDish.price.isEmpty ? nil : apiDish.price
        
        // Convert nutrition scores array to structured format
        let scores = apiDish.nutritionScores
        self.nutritionScores = NutritionScores(
            protein: scores.indices.contains(0) ? scores[0] : 0,
            fat: scores.indices.contains(1) ? scores[1] : 0,
            carbs: scores.indices.contains(2) ? scores[2] : 0
        )
        
        // Convert tags array to structured format
        let tagArray = apiDish.tags
        self.tags = DietaryTags(
            vegetarian: tagArray.indices.contains(0) ? tagArray[0] == 1 : false,
            vegan: tagArray.indices.contains(1) ? tagArray[1] == 1 : false,
            glutenFree: tagArray.indices.contains(2) ? tagArray[2] == 1 : false,
            dairyFree: tagArray.indices.contains(3) ? tagArray[3] == 1 : false
        )
    }
    
    // MARK: - Equatable Implementation
    
    /// Custom Equatable implementation that ignores UUID for comparison
    /// Two MenuItems are equal if all their content properties match
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.originalName == rhs.originalName &&
               lhs.translatedName == rhs.translatedName &&
               lhs.ingredientsEn == rhs.ingredientsEn &&
               lhs.categoryEn == rhs.categoryEn &&
               lhs.price == rhs.price &&
               lhs.nutritionScores == rhs.nutritionScores &&
               lhs.tags == rhs.tags
    }
}

// MARK: - Supporting Models

/// Nutrition scoring information for menu items
/// Scores are typically on a scale of 0-10
struct NutritionScores: Codable, Equatable {
    let protein: Int
    let fat: Int
    let carbs: Int
    
    /// Computed property to check if item is high in protein
    var isHighProtein: Bool { protein >= 6 }
    
    /// Computed property to check if item is low in fat
    var isLowFat: Bool { fat <= 5 }
    
    /// Computed property to check if item is low in carbs
    var isLowCarbs: Bool { carbs <= 4 }
}

/// Dietary restriction tags for menu items
/// Indicates whether an item meets specific dietary requirements
struct DietaryTags: Codable, Equatable {
    let vegetarian: Bool
    let vegan: Bool
    let glutenFree: Bool
    let dairyFree: Bool
    
    enum CodingKeys: String, CodingKey {
        case vegetarian
        case vegan
        case glutenFree = "gluten_free"
        case dairyFree = "dairy_free"
    }
    
    /// Returns all active dietary tags as a set of strings
    var activeTags: Set<String> {
        var tags: Set<String> = []
        if vegetarian { tags.insert("vegetarian") }
        if vegan { tags.insert("vegan") }
        if glutenFree { tags.insert("glutenFree") }
        if dairyFree { tags.insert("dairyFree") }
        return tags
    }
}

// MARK: - Menu Response Model

/// Complete menu response containing items and restaurant information
/// Used internally after processing API responses
struct MenuResponse: Codable, Equatable {
    let menuItems: [MenuItem]
    let restaurantInfo: RestaurantInfo?
    
    enum CodingKeys: String, CodingKey {
        case menuItems = "menu_items"
        case restaurantInfo = "restaurant_info"
    }
    
    // MARK: - Initializers
    
    /// Initializer from Gemini API response
    /// Converts API format to internal menu structure
    /// - Parameters:
    ///   - geminiResponse: Response from Gemini API
    ///   - restaurantInfo: Optional restaurant metadata
    init(from geminiResponse: GeminiMenuResponse, restaurantInfo: RestaurantInfo? = nil) {
        var items: [MenuItem] = []
        
        for category in geminiResponse.categories {
            for dish in category.dishes {
                let menuItem = MenuItem(from: dish, category: category.categoryName)
                items.append(menuItem)
            }
        }
        
        self.menuItems = items
        self.restaurantInfo = restaurantInfo
    }
    
    /// Standard initializer
    /// - Parameters:
    ///   - menuItems: Array of menu items
    ///   - restaurantInfo: Optional restaurant metadata
    init(menuItems: [MenuItem], restaurantInfo: RestaurantInfo?) {
        self.menuItems = menuItems
        self.restaurantInfo = restaurantInfo
    }
    
    // MARK: - Computed Properties
    
    /// Returns all unique categories from menu items
    var categories: [String] {
        Array(Set(menuItems.map { $0.categoryEn })).sorted()
    }
    
    /// Returns total number of items in the menu
    var totalItems: Int {
        menuItems.count
    }
}

/// Restaurant metadata information
struct RestaurantInfo: Codable, Equatable {
    let name: String?
    let cuisine: String?
    let location: String?
}

// MARK: - MenuItem Extensions

extension MenuItem {
    
    // MARK: - Search Functionality
    
    /// Checks if the menu item matches a search query
    /// Searches across translated name, original name, and ingredients
    /// - Parameter query: Search query string
    /// - Returns: True if item matches the query
    func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowercaseQuery = query.lowercased()
        
        // Search in translated name (primary)
        if translatedName.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in original name (secondary)
        if originalName.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in ingredients (tertiary)
        return ingredientsEn.contains { ingredient in
            ingredient.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Filter Functionality
    
    /// Checks if item matches a specific dietary preference
    /// - Parameter preference: Dietary preference string
    /// - Returns: True if item meets the dietary requirement
    func matchesDietaryPreference(_ preference: String?) -> Bool {
        guard let preference = preference else { return true }
        
        switch preference {
        case "vegetarian": return tags.vegetarian
        case "vegan": return tags.vegan
        case "glutenFree": return tags.glutenFree
        case "dairyFree": return tags.dairyFree
        default: return true
        }
    }
    
    /// Checks if item matches nutrition preferences
    /// - Parameters:
    ///   - preferences: Set of nutrition preference strings
    ///   - highProteinThreshold: Minimum protein score for high protein (default: 6)
    ///   - lowFatThreshold: Maximum fat score for low fat (default: 5)
    ///   - lowCarbsThreshold: Maximum carbs score for low carbs (default: 4)
    /// - Returns: True if item meets any of the nutrition preferences
    func matchesNutritionPreferences(
        _ preferences: Set<String>,
        highProteinThreshold: Int = 6,
        lowFatThreshold: Int = 5,
        lowCarbsThreshold: Int = 4
    ) -> Bool {
        guard !preferences.isEmpty else { return true }
        
        for preference in preferences {
            switch preference {
            case "protein":
                if nutritionScores.protein >= highProteinThreshold { return true }
            case "fat":
                if nutritionScores.fat <= lowFatThreshold { return true }
            case "carbs":
                if nutritionScores.carbs <= lowCarbsThreshold { return true }
            default:
                continue
            }
        }
        return false
    }
    
    // MARK: - Display Helpers
    
    /// Returns formatted price string for display
    var formattedPrice: String {
        return price ?? "N/A"
    }
    
    /// Returns ingredients as comma-separated string for display
    var ingredientsString: String {
        return ingredientsEn.joined(separator: ", ")
    }
    
    /// Returns a short description combining name and key ingredients
    var shortDescription: String {
        let mainIngredients = ingredientsEn.prefix(3).joined(separator: ", ")
        return mainIngredients.isEmpty ? translatedName : "\(translatedName) • \(mainIngredients)"
    }
}
