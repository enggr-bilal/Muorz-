//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct FilterButton: View {
    let title: String?
    let icon: String
    let isSelected: Bool
    let isIconOnly: Bool
    
    init(title: String? = nil, icon: String, isSelected: Bool, isIconOnly: Bool = false) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.isIconOnly = isIconOnly
    }
    
    var body: some View {
        Group {
            if isIconOnly {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : .white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
            } else {
                Label(title ?? "", systemImage: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
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
    }
}

struct FilterHeader: View {
    @Binding var selectedCategory: String
    @Binding var selectedDietTag: String?
    @Binding var selectedNutritionTags: Set<String>
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let categories: [String]
    let searchSuggestions: [String]
    let onSuggestionTap: (String) -> Void
    let showHighProteinTag: Bool
    let showLowFatTag: Bool
    let showLowCarbsTag: Bool

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
    
    private var availableNutritionOptions: [PreferenceOption] {
        UserPreferences.nutritionDisplayOptions.filter { option in
            switch option.id {
            case "protein": return showHighProteinTag
            case "fat": return showLowFatTag
            case "carbs": return showLowCarbsTag
            default: return false
            }
        }
    }
    
    private var shouldShowNutritionButton: Bool {
        return !availableNutritionOptions.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                // Search Bar
                SearchBar(
                    searchText: $searchText,
                    placeholder: "Search ingredients, dishes...",
                    suggestions: searchSuggestions,
                    onSuggestionTap: onSuggestionTap,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching = false
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
            } else {
                // Filter Buttons - Using HStack with proper spacing
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        searchButton()
                        categoryMenu()
                        dietMenu()
                        if shouldShowNutritionButton {
                            nutritionMenu()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 3)
                    
                    
                    Spacer(minLength: 0)
                }
                .scrollIndicators(.hidden)
                .frame(height: 50) // Increased height to prevent cropping
                .background(Color.white)
                .clipped() // Prevent any overflow
            }
        }
        .contentShape(Rectangle()) // Prevent unwanted touch interactions
       // .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Search Button
    
    @ViewBuilder
    private func searchButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSearching = true
            }
        } label: {
            FilterButton(
                icon: "magnifyingglass",
                isSelected: !searchText.isEmpty,
                isIconOnly: true
            )
        }
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
            // Option "No Preference"
            Button {
                selectedDietTag = nil
            } label: {
                HStack {
                    Text("No Preference")
                    if selectedDietTag == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            // Autres options
            ForEach(UserPreferences.dietaryOptions) { option in
                Button {
                    selectedDietTag = option.id
                } label: {
                    HStack {
                        Text(option.name)
                        if selectedDietTag == option.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterButton(
                title: selectedDietOption?.name ?? "Diet",
                icon: "fork.knife", // Icône constante
                isSelected: selectedDietOption != nil
            )
        }
    }

    @ViewBuilder
    private func nutritionMenu() -> some View {
        Menu {
            ForEach(availableNutritionOptions) { option in
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
                        Text(option.name)
                        if selectedNutritionTags.contains(option.id) {
                            Spacer()
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
#Preview {
    MenuView(preferences: UserPreferences())
}
