//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

struct MenuItem: Identifiable {
    let id = UUID()
    let originalName: String
    let translatedName: String
    let ingredientsEn: [String]
    let categoryEn: String
    let price: String?
    let nutritionScores: NutritionScores
    let tags: DietaryTags
}

struct NutritionScores {
    let protein: Int
    let fat: Int
    let carbs: Int
}

struct DietaryTags {
    let vegetarian: Bool
    let vegan: Bool
    let glutenFree: Bool
    let dairyFree: Bool
}

// Sample data
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
