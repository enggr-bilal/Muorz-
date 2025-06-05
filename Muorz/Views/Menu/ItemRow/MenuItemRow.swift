//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuItemRow: View {
    let item: MenuItem
    let currency: String?
    let showHighProtein: Bool
    let showLowFat: Bool
    let showLowCarbs: Bool
    let searchText: String
    @ObservedObject var selectionManager: SelectionManager
    
    // Thresholds for nutritional tags (more strict for meaningful tags)
    private let highProteinThreshold = 7  // Was 6, now requires 7+
    private let lowFatThreshold = 3       // Was 5, now requires 3 or less
    private let lowCarbsThreshold = 3     // Was 4, now requires 3 or less
    
    private var isHighProtein: Bool {
        item.nutritionScores.protein >= highProteinThreshold
    }
    
    private var isLowFat: Bool {
        item.nutritionScores.fat <= lowFatThreshold
    }
    
    private var isLowCarbs: Bool {
        item.nutritionScores.carbs <= lowCarbsThreshold
    }
    
    var body: some View {
        MenuItemInfo(
            item: item,
            selectionManager: selectionManager,
            currency: currency,
            showHighProtein: showHighProtein,
            showLowFat: showLowFat,
            showLowCarbs: showLowCarbs,
            isHighProtein: isHighProtein,
            isLowFat: isLowFat,
            isLowCarbs: isLowCarbs,
            searchText: searchText
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MenuItemRow(
            item: MenuItem(
                originalName: "PIZZA VEGETARIANA",
                translatedName: "Vegetarian Pizza",
                ingredientsEn: ["tomato", "mushrooms", "bell peppers"],
                categoryEn: "main course",
                price: "12,00 €",
                nutritionScores: NutritionScores(protein: 5, fat: 6, carbs: 7),
                tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
            ),
            currency: "€",
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: false,
            searchText: "",
            selectionManager: SelectionManager()
        )
        
        MenuItemRow(
            item: MenuItem(
                originalName: "BRUSCHETTA VEGETARIANA",
                translatedName: "Vegetarian Bruschetta",
                ingredientsEn: ["tomato", "basil", "mozzarella"],
                categoryEn: "starter",
                price: "8,00 €",
                nutritionScores: NutritionScores(protein: 4, fat: 5, carbs: 7),
                tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
            ),
            currency: "€",
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            searchText: "tomato",
            selectionManager: SelectionManager()
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 
