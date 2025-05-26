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

    // MARK: - Helpers
    
    private var selectedCategoryLabel: String {
        selectedCategory == "all" ? "All" : selectedCategory.capitalized
    }
    
    private var selectedDietOption: PreferenceOption? {
        UserPreferences.dietaryOptions.first { $0.id == selectedDietTag }
    }

    private var selectedNutritionLabel: String {
        switch selectedNutritionTags.count {
        case 0: return "Nutrition"
        case 1: return "1 Filter"
        default: return "\(selectedNutritionTags.count) Filters"
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryMenu()
                dietMenu()
                nutritionMenu()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Menus

    @ViewBuilder
    private func categoryMenu() -> some View {
        Menu {
            ForEach(categories, id: \.self) { category in
                Button {
                    withAnimation {
                        selectedCategory = category
                    }
                } label: {
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
    }

    @ViewBuilder
    private func dietMenu() -> some View {
        Menu {
            Button {
                selectedDietTag = nil
            } label: {
                HStack {
                    Text("No Preference")
                    if selectedDietTag == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            ForEach(UserPreferences.dietaryOptions) { option in
                Button {
                    selectedDietTag = option.id
                } label: {
                    HStack {
                        Label(option.name, systemImage: option.icon)
                        if selectedDietTag == option.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            if let diet = selectedDietOption {
                FilterButton(title: diet.name, icon: diet.icon, isSelected: true)
            } else {
                FilterButton(title: "Diet", icon: "fork.knife", isSelected: false)
            }
        }
    }

    @ViewBuilder
    private func nutritionMenu() -> some View {
        Menu {
            ForEach(UserPreferences.nutritionOptions) { option in
                Button {
                    withAnimation {
                        if selectedNutritionTags.contains(option.id) {
                            selectedNutritionTags.remove(option.id)
                        } else {
                            selectedNutritionTags.insert(option.id)
                        }
                    }
                } label: {
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
                Button(role: .destructive) {
                    withAnimation {
                        selectedNutritionTags.removeAll()
                    }
                } label: {
                    Label("Clear All", systemImage: "xmark.circle.fill")
                }
            }
        } label: {
            FilterButton(
                title: selectedNutritionLabel,
                icon: "tag.fill",
                isSelected: !selectedNutritionTags.isEmpty
            )
        }
    }
}
