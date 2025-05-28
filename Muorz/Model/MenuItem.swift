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
    let categories: [MenuCategory]
    
    // Custom decoder to handle array directly
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.categories = try container.decode([MenuCategory].self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(categories)
    }
}

/// Menu category from API
struct MenuCategory: Codable {
    let categoryName: String
    let dishes: [APIDish]
    
    enum CodingKeys: String, CodingKey {
        case categoryName = "ctg"
        case dishes = "dsh"
    }
}

/// Dish structure from API (compact format)
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
        self.originalName = apiDish.originalName
        self.translatedName = apiDish.translatedName
        self.ingredientsEn = apiDish.ingredients
        self.categoryEn = category.lowercased()
        self.price = apiDish.price.isEmpty ? nil : apiDish.price
        
        // Convert nutrition scores array to struct
        let scores = apiDish.nutritionScores
        self.nutritionScores = NutritionScores(
            protein: scores.count > 0 ? scores[0] : 0,
            fat: scores.count > 1 ? scores[1] : 0,
            carbs: scores.count > 2 ? scores[2] : 0
        )
        
        // Convert tags array to struct
        let tagArray = apiDish.tags
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
    
    enum CodingKeys: String, CodingKey {
        case menuItems = "menu_items"
        case restaurantInfo = "restaurant_info"
    }
    
    // Initializer from Gemini API response
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
    
    // Standard initializer
    init(menuItems: [MenuItem], restaurantInfo: RestaurantInfo?) {
        self.menuItems = menuItems
        self.restaurantInfo = restaurantInfo
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
                                   highProteinThreshold: Int = 6,
                                   lowFatThreshold: Int = 5,
                                   lowCarbsThreshold: Int = 4) -> Bool {
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
    
    /// Get ingredients as comma-separated string
    var ingredientsString: String {
        return ingredientsEn.joined(separator: ", ")
    }
}

// MARK: - Sample Data

extension MenuItem {
    static let sampleData = [
        MenuItem(
            originalName: "INVOLTINI DE SPECK",
            translatedName: "Speck Rolls",
            ingredientsEn: ["speck ham", "ricotta"],
            categoryEn: "starter",
            price: nil,
            nutritionScores: NutritionScores(protein: 7, fat: 8, carbs: 2),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: true, dairyFree: false)
        ),
        MenuItem(
            originalName: "MINI POIVRONS FARCIS AU THON",
            translatedName: "Mini Peppers Stuffed with Tuna",
            ingredientsEn: ["mini peppers", "tuna", "olive oil", "herbs"],
            categoryEn: "starter",
            price: "5,00 €",
            nutritionScores: NutritionScores(protein: 6, fat: 5, carbs: 2),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: true, dairyFree: true)
        ),
        MenuItem(
            originalName: "BRUSCHETTA VEGETARIANA",
            translatedName: "Vegetarian Bruschetta",
            ingredientsEn: ["tomato coulis", "eggplants", "sun-dried tomatoes", "mushrooms", "bell peppers", "mozzarella", "bread"],
            categoryEn: "starter",
            price: nil,
            nutritionScores: NutritionScores(protein: 4, fat: 5, carbs: 7),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        MenuItem(
            originalName: "PIZZA VEGETARIANA",
            translatedName: "Vegetarian Pizza",
            ingredientsEn: ["tomato coulis", "mushrooms", "tomatoes", "bell peppers", "artichokes", "eggplants", "mozzarella", "oregano"],
            categoryEn: "main course",
            price: "12,00 €",
            nutritionScores: NutritionScores(protein: 5, fat: 6, carbs: 7),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        MenuItem(
            originalName: "PASTA ALLA BOLOGNESE",
            translatedName: "Bolognese Pasta",
            ingredientsEn: ["tomato sauce", "ground beef", "tomatoes", "onions", "pasta"],
            categoryEn: "main course",
            price: "7,50 €",
            nutritionScores: NutritionScores(protein: 6, fat: 6, carbs: 7),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: false, dairyFree: true)
        ),
        MenuItem(
            originalName: "LASAGNE VEGETARIANA",
            translatedName: "Vegetarian Lasagna",
            ingredientsEn: ["pasta", "béchamel", "crème fraîche", "eggplants", "tomatoes", "zucchini", "onions", "pesto", "mozzarella"],
            categoryEn: "main course",
            price: "9,00 €",
            nutritionScores: NutritionScores(protein: 6, fat: 7, carbs: 6),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        MenuItem(
            originalName: "PANNA COTTA FRUITS ROUGES",
            translatedName: "Panna Cotta with Red Fruits",
            ingredientsEn: ["cream", "sugar", "gelatin", "red fruit coulis"],
            categoryEn: "dessert",
            price: "4,00 €",
            nutritionScores: NutritionScores(protein: 2, fat: 7, carbs: 6),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: true, dairyFree: false)
        ),
        MenuItem(
            originalName: "TIRAMISU",
            translatedName: "Tiramisu",
            ingredientsEn: ["ladyfingers", "mascarpone", "coffee", "sugar", "eggs", "cocoa powder"],
            categoryEn: "dessert",
            price: "4,00 €",
            nutritionScores: NutritionScores(protein: 4, fat: 7, carbs: 6),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        )
    ]
}
