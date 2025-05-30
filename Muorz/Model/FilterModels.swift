//
//  FilterModels.swift
//  Muorz
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

// MARK: - Filter Configuration Models

/// Represents the current filter state for menu items
/// Manages dietary preferences, nutrition filters, and search criteria
struct MenuFilters: Codable, Equatable {
    /// Current search query text
    var searchQuery: String = ""
    
    /// Selected dietary preference filter
    var dietaryPreference: DietaryPreference?
    
    /// Set of active nutrition filters
    var nutritionFilters: Set<NutritionFilter> = []
    
    /// Selected category filter
    var categoryFilter: String?
    
    /// Price range filter
    var priceRange: PriceRange?
    
    // MARK: - Computed Properties
    
    /// Returns true if any filters are currently active
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty ||
        dietaryPreference != nil ||
        !nutritionFilters.isEmpty ||
        categoryFilter != nil ||
        priceRange != nil
    }
    
    /// Returns the number of active filters
    var activeFilterCount: Int {
        var count = 0
        if !searchQuery.isEmpty { count += 1 }
        if dietaryPreference != nil { count += 1 }
        if !nutritionFilters.isEmpty { count += nutritionFilters.count }
        if categoryFilter != nil { count += 1 }
        if priceRange != nil { count += 1 }
        return count
    }
    
    // MARK: - Methods
    
    /// Clears all active filters
    mutating func clearAll() {
        searchQuery = ""
        dietaryPreference = nil
        nutritionFilters.removeAll()
        categoryFilter = nil
        priceRange = nil
    }
    
    /// Applies filters to a collection of menu items
    /// - Parameter items: Array of menu items to filter
    /// - Returns: Filtered array of menu items
    func apply(to items: [MenuItem]) -> [MenuItem] {
        return items.filter { item in
            // Apply search query filter
            if !searchQuery.isEmpty && !item.matchesSearchQuery(searchQuery) {
                return false
            }
            
            // Apply dietary preference filter
            if let dietary = dietaryPreference,
               !item.matchesDietaryPreference(dietary.rawValue) {
                return false
            }
            
            // Apply nutrition filters
            if !nutritionFilters.isEmpty {
                let nutritionStrings = Set(nutritionFilters.map { $0.rawValue })
                if !item.matchesNutritionPreferences(nutritionStrings) {
                    return false
                }
            }
            
            // Apply category filter
            if let category = categoryFilter,
               !item.categoryEn.localizedCaseInsensitiveContains(category) {
                return false
            }
            
            // Apply price range filter
            if let range = priceRange,
               !range.contains(item.price) {
                return false
            }
            
            return true
        }
    }
}

// MARK: - Filter Option Enums

/// Available dietary preference filters
enum DietaryPreference: String, CaseIterable, Codable {
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case glutenFree = "glutenFree"
    case dairyFree = "dairyFree"
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        }
    }
    
    /// Icon name for UI display
    var iconName: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .dairyFree: return "drop.circle.fill"
        }
    }
}

/// Available nutrition-based filters
enum NutritionFilter: String, CaseIterable, Codable {
    case protein = "protein"
    case lowFat = "fat"
    case lowCarbs = "carbs"
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .protein: return "High Protein"
        case .lowFat: return "Low Fat"
        case .lowCarbs: return "Low Carbs"
        }
    }
    
    /// Icon name for UI display
    var iconName: String {
        switch self {
        case .protein: return "bolt.fill"
        case .lowFat: return "heart.fill"
        case .lowCarbs: return "flame.fill"
        }
    }
}

/// Price range filter for menu items
struct PriceRange: Codable, Equatable {
    let minimum: Double?
    let maximum: Double?
    
    /// Checks if a price string falls within this range
    /// - Parameter priceString: Optional price string from menu item
    /// - Returns: True if price is within range or if price is unavailable
    func contains(_ priceString: String?) -> Bool {
        guard let priceString = priceString,
              let price = extractPrice(from: priceString) else {
            // If no price is available, include the item
            return true
        }
        
        if let min = minimum, price < min {
            return false
        }
        
        if let max = maximum, price > max {
            return false
        }
        
        return true
    }
    
    /// Extracts numeric price from a price string
    /// - Parameter priceString: String containing price information
    /// - Returns: Extracted price as Double, or nil if not found
    private func extractPrice(from priceString: String) -> Double? {
        // Remove currency symbols and extract numeric value
        let cleanedString = priceString
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "CHF", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanedString)
    }
} 