//
//  ScannedMenu.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import SwiftData

@Model
final class ScannedMenu {
    // MARK: - Core Properties
    
    @Attribute(.unique) var id: UUID
    var scannedAt: Date
    var restaurantName: String?
    var restaurantCuisine: String?
    var restaurantLocation: String?
    var currency: String?
    
    // MARK: - Location Data (for future use)
    var latitude: Double?
    var longitude: Double?
    var address: String?
    
    // MARK: - Menu Data
    @Relationship(deleteRule: .cascade) var menuItems: [PersistedMenuItem]
    
    // MARK: - Metadata
    var notes: String?
    var rating: Int? // 1-5 stars rating
    var review: String? // User review text
    var isFavorite: Bool
    var tags: [String] // Custom tags for organization
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        scannedAt: Date = Date(),
        restaurantName: String? = nil,
        restaurantCuisine: String? = nil,
        restaurantLocation: String? = nil,
        currency: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        menuItems: [PersistedMenuItem] = [],
        notes: String? = nil,
        rating: Int? = nil,
        review: String? = nil,
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.scannedAt = scannedAt
        self.restaurantName = restaurantName
        self.restaurantCuisine = restaurantCuisine
        self.restaurantLocation = restaurantLocation
        self.currency = currency
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.menuItems = menuItems
        self.notes = notes
        self.rating = rating
        self.review = review
        self.isFavorite = isFavorite
        self.tags = tags
    }
    
    // MARK: - Convenience Initializer from MenuResponse
    
    convenience init(from menuResponse: MenuResponse, scannedAt: Date = Date()) {
        let persistedItems = menuResponse.menuItems.map { PersistedMenuItem(from: $0) }
        
        self.init(
            scannedAt: scannedAt,
            restaurantName: menuResponse.restaurantInfo?.name,
            restaurantCuisine: menuResponse.restaurantInfo?.cuisine,
            restaurantLocation: menuResponse.restaurantInfo?.location,
            currency: menuResponse.currency,
            menuItems: persistedItems
        )
    }
    
    // MARK: - Computed Properties
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scannedAt)
    }
    
    var displayName: String {
        return restaurantName ?? "Menu scanné"
    }
    
    var totalItems: Int {
        return menuItems.count
    }
    
    var categories: [String] {
        return Array(Set(menuItems.map { $0.categoryEn })).sorted()
    }
    
    var hasPricing: Bool {
        return currency != nil && menuItems.contains { $0.hasPrice }
    }
    
    var totalPrice: Double {
        return menuItems.compactMap { $0.priceValue }.reduce(0, +)
    }
    
    // MARK: - Search and Filter Methods
    
    func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowercaseQuery = query.lowercased()
        
        // Search in restaurant name
        if let name = restaurantName, name.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in cuisine
        if let cuisine = restaurantCuisine, cuisine.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in location
        if let location = restaurantLocation, location.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in notes
        if let notes = notes, notes.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Search in tags
        if tags.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
            return true
        }
        
        // Search in menu items
        return menuItems.contains { $0.matchesSearchQuery(query) }
    }
    
    func matchesDietaryPreference(_ preference: String?) -> Bool {
        guard let preference = preference else { return true }
        return menuItems.contains { $0.matchesDietaryPreference(preference) }
    }
    
    func matchesCategory(_ category: String) -> Bool {
        guard category != "all" else { return true }
        return menuItems.contains { $0.categoryEn == category }
    }
    
    // MARK: - Helper Methods
    
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
}

// MARK: - Persisted Menu Item Model

@Model
final class PersistedMenuItem {
    // MARK: - Core Properties
    
    @Attribute(.unique) var id: UUID
    var originalName: String
    var translatedName: String
    var ingredientsEn: [String]
    var categoryEn: String
    var price: String?
    
    // MARK: - Nutrition Data
    var proteinScore: Int
    var fatScore: Int
    var carbsScore: Int
    
    // MARK: - Dietary Tags
    var isVegetarian: Bool
    var isVegan: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
    
    // MARK: - Relationships
    @Relationship(inverse: \ScannedMenu.menuItems) var scannedMenu: ScannedMenu?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        originalName: String,
        translatedName: String,
        ingredientsEn: [String],
        categoryEn: String,
        price: String?,
        proteinScore: Int,
        fatScore: Int,
        carbsScore: Int,
        isVegetarian: Bool,
        isVegan: Bool,
        isGlutenFree: Bool,
        isDairyFree: Bool
    ) {
        self.id = id
        self.originalName = originalName
        self.translatedName = translatedName
        self.ingredientsEn = ingredientsEn
        self.categoryEn = categoryEn
        self.price = price
        self.proteinScore = proteinScore
        self.fatScore = fatScore
        self.carbsScore = carbsScore
        self.isVegetarian = isVegetarian
        self.isVegan = isVegan
        self.isGlutenFree = isGlutenFree
        self.isDairyFree = isDairyFree
    }
    
    // MARK: - Convenience Initializer from MenuItem
    
    convenience init(from menuItem: MenuItem) {
        self.init(
            originalName: menuItem.originalName,
            translatedName: menuItem.translatedName,
            ingredientsEn: menuItem.ingredientsEn,
            categoryEn: menuItem.categoryEn,
            price: menuItem.price,
            proteinScore: menuItem.nutritionScores.protein,
            fatScore: menuItem.nutritionScores.fat,
            carbsScore: menuItem.nutritionScores.carbs,
            isVegetarian: menuItem.tags.vegetarian,
            isVegan: menuItem.tags.vegan,
            isGlutenFree: menuItem.tags.glutenFree,
            isDairyFree: menuItem.tags.dairyFree
        )
    }
    
    // MARK: - Computed Properties
    
    var nutritionScores: NutritionScores {
        return NutritionScores(
            protein: proteinScore,
            fat: fatScore,
            carbs: carbsScore
        )
    }
    
    var dietaryTags: DietaryTags {
        return DietaryTags(
            vegetarian: isVegetarian,
            vegan: isVegan,
            glutenFree: isGlutenFree,
            dairyFree: isDairyFree
        )
    }
    
    var priceValue: Double? {
        guard let price = price else { return nil }
        return Double(price)
    }
    
    var hasPrice: Bool {
        return price != nil
    }
    
    var ingredientsString: String {
        return ingredientsEn.joined(separator: ", ")
    }
    
    // MARK: - Search and Filter Methods
    
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
    
    func matchesDietaryPreference(_ preference: String?) -> Bool {
        guard let preference = preference else { return true }
        
        switch preference {
        case "vegetarian": return isVegetarian
        case "vegan": return isVegan
        case "glutenFree": return isGlutenFree
        case "dairyFree": return isDairyFree
        default: return true
        }
    }
    
    // MARK: - Conversion to MenuItem (for compatibility)
    
    func toMenuItem() -> MenuItem {
        return MenuItem(
            originalName: originalName,
            translatedName: translatedName,
            ingredientsEn: ingredientsEn,
            categoryEn: categoryEn,
            price: price,
            nutritionScores: nutritionScores,
            tags: dietaryTags
        )
    }
} 