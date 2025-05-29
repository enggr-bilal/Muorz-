//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuItemInfo: View {
    let item: MenuItem
    @ObservedObject var selectionManager: SelectionManager
    let showHighProtein: Bool
    let showLowFat: Bool
    let showLowCarbs: Bool
    let isHighProtein: Bool
    let isLowFat: Bool
    let isLowCarbs: Bool
    let searchText: String
    
    private var quantity: Int {
        selectionManager.quantity(for: item)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Price row
            HStack {
                HighlightedText(
                    text: item.translatedName,
                    searchText: searchText,
                    font: .system(size: 20, weight: .regular, design: .serif),
                    highlightColor: .yellow.opacity(0.6)
                )
                .foregroundColor(.black)
                .lineLimit(1)
                
                Spacer()
                
                Text(item.price ?? "N/A")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
            }
            
            // Description
            HStack {
                HighlightedText(
                    text: item.ingredientsEn.joined(separator: ", "),
                    searchText: searchText,
                    font: .footnote,
                    highlightColor: .yellow.opacity(0.6)
                )
                .foregroundColor(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                Spacer()
            }
            
            // Tags and Quantity Control row
            
            Spacer()
            HStack {
                if showHighProtein || showLowFat || showLowCarbs {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if showHighProtein && isHighProtein {
                                NutritionTag(
                                    systemName: "figure.strengthtraining.traditional",
                                    label: "High Protein",
                                    color: .blue
                                )
                            }
                            if showLowFat && isLowFat {
                                NutritionTag(
                                    systemName: "leaf.fill",
                                    label: "Low Fat",
                                    color: .green
                                )
                            }
                            if showLowCarbs && isLowCarbs {
                                NutritionTag(
                                    systemName: "chart.line.downtrend.xyaxis",
                                    label: "Low Carbs",
                                    color: .orange
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                QuantityControl(
                    quantity: quantity,
                    onIncrement: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectionManager.addItem(item)
                    },
                    onDecrement: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectionManager.removeItem(item)
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 130)
        .background(Color(UIColor.systemBackground))
        .animation(.spring(response: 0.2), value: quantity)
    }
}

#Preview("With Highlighting") {
    VStack {
        MenuItemInfo(
            item: MenuItem(
                originalName: "BRUSCHETTA VEGETARIANA",
                translatedName: "Vegetarian Bruschetta",
                ingredientsEn: ["tomato", "basil", "mozzarella"],
                categoryEn: "starter",
                price: "8,00 €",
                nutritionScores: NutritionScores(protein: 4, fat: 5, carbs: 7),
                tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
            ),
            selectionManager: SelectionManager(),
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            isHighProtein: false,
            isLowFat: true,
            isLowCarbs: false,
            searchText: "tomato"
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview {
    VStack(spacing: 20) {
        MenuItemInfo(
            item: MenuItem(
                originalName: "PIZZA VEGETARIANA",
                translatedName: "Vegetarian Pizza",
                ingredientsEn: ["tomato", "mushrooms", "bell peppers"],
                categoryEn: "main course",
                price: "12,00 €",
                nutritionScores: NutritionScores(protein: 5, fat: 6, carbs: 7),
                tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
            ),
            selectionManager: SelectionManager(),
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: false,
            isHighProtein: true,
            isLowFat: true,
            isLowCarbs: false,
            searchText: ""
        )
        .background(Color.white)
        
        MenuItemInfo(
            item: MenuItem(
                originalName: "PIZZA VEGETARIANA",
                translatedName: "Vegetarian Pizza",
                ingredientsEn: ["tomato", "mushrooms", "bell peppers"],
                categoryEn: "main course",
                price: "12,00 €",
                nutritionScores: NutritionScores(protein: 5, fat: 6, carbs: 7),
                tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
            ),
            selectionManager: SelectionManager(),
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: false,
            isHighProtein: true,
            isLowFat: true,
            isLowCarbs: false,
            searchText: ""
        )
        .background(Color.white)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 
