//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

struct NutritionFilter: Identifiable {
    let id: String
    let name: String
    let tag: String
    let icon: String
}

struct DietFilter: Identifiable {
    let id: String
    let name: String
    let tag: String
    let icon: String
}

// Static data
enum FilterData {
    static let nutritionFilters = [
        NutritionFilter(
            id: "protein",
            name: "High Protein",
            tag: "protein",
            icon: "figure.strengthtraining.traditional"
        ),
        NutritionFilter(
            id: "fat",
            name: "Low Fat",
            tag: "fat",
            icon: "leaf.fill"
        ),
        NutritionFilter(
            id: "carbs",
            name: "Low Carbs",
            tag: "carbs",
            icon: "chart.line.downtrend.xyaxis"
        )
    ]
    
    static let dietFilters = [
        DietFilter(
            id: "vegetarian",
            name: "Vegetarian",
            tag: "vegetarian",
            icon: ""
        ),
        DietFilter(
            id: "vegan",
            name: "Vegan",
            tag: "vegan",
            icon: ""
        ),
        DietFilter(
            id: "glutenFree",
            name: "Gluten Free",
            tag: "glutenFree",
            icon: ""
        ),
        DietFilter(
            id: "dairyFree",
            name: "Dairy Free",
            tag: "dairyFree",
            icon: ""
        )
    ]
} 
