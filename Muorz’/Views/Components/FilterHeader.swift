//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor, lineWidth: 1)
                    .padding(0.5)
            )
    }
}

struct FilterHeader: View {
    @Binding var selectedCategory: String
    @Binding var selectedDietTag: String?
    @Binding var selectedNutritionTags: Set<String>
    let categories: [String]
    
    private var selectedDietOption: PreferenceOption? {
        UserPreferences.dietaryOptions.first { $0.id == selectedDietTag }
    }
    
    private var selectedNutritionLabels: String {
        if selectedNutritionTags.isEmpty {
            return "Nutrition"
        }
        return selectedNutritionTags.count == 1 ? "1 Filter" : "\(selectedNutritionTags.count) Filters"
    }
    
    private var selectedCategoryLabel: String {
        selectedCategory == "all" ? "All" : selectedCategory.capitalized
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Categories Menu
                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            withAnimation {
                                selectedCategory = category
                            }
                        }) {
                            HStack {
                                Text(category == "all" ? "All Categories" : category.capitalized)
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterButton(
                        title: selectedCategoryLabel,
                        icon: "list.bullet",
                        isSelected: selectedCategory != "all"
                    )
                }
                
                // Diet Filter Button
                Menu {
                    Button(action: {
                        selectedDietTag = nil
                    }) {
                        HStack {
                            Text("No Preference")
                            if selectedDietTag == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ForEach(UserPreferences.dietaryOptions) { option in
                        Button(action: {
                            selectedDietTag = option.id
                        }) {
                            HStack {
                                Label(option.name, systemImage: option.icon)
                                if selectedDietTag == option.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    if let dietOption = selectedDietOption {
                        FilterButton(
                            title: dietOption.name,
                            icon: "dietOption.icon",
                            isSelected: true
                        )
                    } else {
                        FilterButton(
                            title: "Diet",
                            icon: "fork.knife",
                            isSelected: false
                        )
                    }
                }
                
                // Nutrition Tags Menu
                Menu {
                    ForEach(UserPreferences.nutritionOptions) { option in
                        Button(action: {
                            withAnimation {
                                if selectedNutritionTags.contains(option.id) {
                                    selectedNutritionTags.remove(option.id)
                                } else {
                                    selectedNutritionTags.insert(option.id)
                                }
                            }
                        }) {
                            HStack {
                                Label(option.name, systemImage: option.icon)
                                if selectedNutritionTags.contains(option.id) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    if !selectedNutritionTags.isEmpty {
                        Divider()
                        Button(role: .destructive, action: {
                            withAnimation {
                                selectedNutritionTags.removeAll()
                            }
                        }) {
                            Label("Clear All", systemImage: "xmark.circle.fill")
                        }
                    }
                } label: {
                    FilterButton(
                        title: selectedNutritionLabels,
                        icon: "tag.fill",
                        isSelected: !selectedNutritionTags.isEmpty
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    FilterHeader(
        selectedCategory: .constant("all"),
        selectedDietTag: .constant("vegetarian"),
        selectedNutritionTags: .constant(["protein"]),
        categories: ["all", "appetizers", "main course", "desserts"]
    )
} 
