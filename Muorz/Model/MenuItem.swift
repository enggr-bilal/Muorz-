//
//  MenuItem.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

// MARK: - API Response Models (Gemini API Format)

/// Root response structure from Gemini API
struct GeminiMenuResponse: Codable {
    let currency: String?
    let categories: [MenuCategory]
}

/// Menu category from API
struct MenuCategory: Codable {
    let name: String
    let dishes: [APIDish]
}

/// Dish structure from API
struct APIDish: Codable {
    let original_name: String
    let translated_name: String
    let ingredients_en: [String]
    let price: Double?
    let nutrition_scores: [Int]? // [protein, fat, carbs] on 0-10 scale
    let dietary_tags: [Int] // [vegetarian, vegan, gluten_free, dairy_free] as 0/1
    
    // Custom decoder to handle potential missing values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.original_name = try container.decode(String.self, forKey: .original_name)
        self.translated_name = try container.decode(String.self, forKey: .translated_name)
        self.ingredients_en = try container.decode([String].self, forKey: .ingredients_en)
        self.price = try container.decodeIfPresent(Double.self, forKey: .price)
        self.nutrition_scores = try container.decodeIfPresent([Int].self, forKey: .nutrition_scores)
        
        // Ensure dietary_tags is always an array of 4 integers
        if let tags = try? container.decode([Int].self, forKey: .dietary_tags), tags.count == 4 {
            self.dietary_tags = tags
        } else {
            // Default to all false if tags are missing or invalid
            self.dietary_tags = [0, 0, 0, 0]
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case original_name
        case translated_name
        case ingredients_en
        case price
        case nutrition_scores
        case dietary_tags
    }
}

// MARK: - Internal App Models

struct MenuItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let originalName: String
    let translatedName: String
    let ingredientsEn: [String]
    let categoryEn: String
    let price: String?
    let nutritionScores: NutritionScores
    let tags: DietaryTags
    
    // Coding keys for internal storage/persistence
    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case translatedName = "translated_name"
        case ingredientsEn = "ingredients_en"
        case categoryEn = "category_en"
        case price
        case nutritionScores = "nutrition_scores"
        case tags
    }
    
    // Custom initializer for manual creation
    init(originalName: String, translatedName: String, ingredientsEn: [String],
         categoryEn: String, price: String?, nutritionScores: NutritionScores, tags: DietaryTags) {
        self.originalName = originalName
        self.translatedName = translatedName
        self.ingredientsEn = ingredientsEn
        self.categoryEn = categoryEn
        self.price = price
        self.nutritionScores = nutritionScores
        self.tags = tags
    }
    
    // Initializer from API dish
    init(from apiDish: APIDish, category: String) {
        self.originalName = apiDish.original_name
        self.translatedName = apiDish.translated_name
        self.ingredientsEn = apiDish.ingredients_en
        self.categoryEn = category.lowercased()
        
        // Convert Double price to String for internal storage
        if let priceValue = apiDish.price {
            self.price = String(format: "%.2f", priceValue)
        } else {
            self.price = nil
        }
        
        // Convert nutrition scores array to struct with validation
        if let scores = apiDish.nutrition_scores, scores.count >= 3 {
            // Ensure scores are within valid range (0-10)
            let validatedScores = scores.map { min(max($0, 0), 10) }
            self.nutritionScores = NutritionScores(
                protein: validatedScores[0],
                fat: validatedScores[1],
                carbs: validatedScores[2]
            )
        } else {
            // Default nutrition scores when API doesn't provide them
            self.nutritionScores = NutritionScores(
                protein: 5, // Default middle value
                fat: 5,
                carbs: 5
            )
        }
        
        // Convert tags array to struct with validation
        let tagArray = apiDish.dietary_tags
        self.tags = DietaryTags(
            vegetarian: tagArray.count > 0 ? tagArray[0] == 1 : false,
            vegan: tagArray.count > 1 ? tagArray[1] == 1 : false,
            glutenFree: tagArray.count > 2 ? tagArray[2] == 1 : false,
            dairyFree: tagArray.count > 3 ? tagArray[3] == 1 : false
        )
    }
    
    // Custom Equatable implementation (ignoring ID for comparison)
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

struct NutritionScores: Codable, Equatable {
    let protein: Int
    let fat: Int
    let carbs: Int
}

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
}

// MARK: - Menu Response Model (for internal use)

struct MenuResponse: Codable, Equatable {
    let menuItems: [MenuItem]
    let restaurantInfo: RestaurantInfo?
    let currency: String?
    
    // Initializer from Gemini API response
    init(from geminiResponse: GeminiMenuResponse, restaurantInfo: RestaurantInfo? = nil) {
        var items: [MenuItem] = []
        
        // Process each category and its dishes
        for category in geminiResponse.categories {
            for dish in category.dishes {
                // Create MenuItem with validated data
                let menuItem = MenuItem(from: dish, category: category.name)
                items.append(menuItem)
            }
        }
        
        // Sort items by category order
        let categoryOrder = ["starter", "pizza", "pasta", "main course", "dessert", "drink"]
        items.sort { item1, item2 in
            let index1 = categoryOrder.firstIndex(of: item1.categoryEn) ?? Int.max
            let index2 = categoryOrder.firstIndex(of: item2.categoryEn) ?? Int.max
            return index1 < index2
        }
        
        self.menuItems = items
        self.restaurantInfo = restaurantInfo
        self.currency = geminiResponse.currency
    }
    
    // Standard initializer
    init(menuItems: [MenuItem], restaurantInfo: RestaurantInfo?, currency: String? = nil) {
        self.menuItems = menuItems
        self.restaurantInfo = restaurantInfo
        self.currency = currency
    }
}

struct RestaurantInfo: Codable, Equatable {
    let name: String?
    let cuisine: String?
    let location: String?
}

// MARK: - Search and Filter Extensions

extension MenuItem {
    /// Search in ingredients, name, and translated name
    func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowercaseQuery = query.lowercased()
        
        // Search in translated name
        if translatedName.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in original name
        if originalName.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in ingredients
        return ingredientsEn.contains { ingredient in
            ingredient.lowercased().contains(lowercaseQuery)
        }
    }
    
    /// Check if item matches dietary preferences
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
    
    /// Check if item matches nutrition preferences
    func matchesNutritionPreferences(_ preferences: Set<String>,
                                   highProteinThreshold: Int = 7,
                                   lowFatThreshold: Int = 3,
                                   lowCarbsThreshold: Int = 3) -> Bool {
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
    
    /// Get formatted price string
    var formattedPrice: String {
        return price ?? "N/A"
    }
    
    /// Get formatted price with currency symbol
    func formattedPrice(with currency: String?) -> String {
        guard let price = price, let priceValue = Double(price) else {
            return ""
        }
        
        if let currency = currency {
            return "\(currency)\(String(format: "%.2f", priceValue))"
        } else {
            return String(format: "%.2f", priceValue)
        }
    }
    
    /// Get price as Double value
    var priceValue: Double? {
        guard let price = price else { return nil }
        return Double(price)
    }
    
    /// Check if item has price information
    var hasPrice: Bool {
        return price != nil
    }
    
    /// Get ingredients as comma-separated string
    var ingredientsString: String {
        return ingredientsEn.joined(separator: ", ")
    }
}
